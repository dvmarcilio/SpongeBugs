module lang::java::refactoring::sonar::parseToConvertStringToPrimitive::parseToConvertStringToPrimitive

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import Set;
import Map;
import lang::java::util::CompilationUnitUtils;
import lang::java::refactoring::forloop::MethodVar;
import lang::java::refactoring::forloop::LocalVariablesFinder;
import lang::java::refactoring::forloop::ClassFieldsFinder;

// {"Byte", "Character", "Short", "Integer", "Long", "Float", "Double", "Boolean"};

private map[str, str] parseMethodByType = (
	"Float": "parseFloat",
	"Integer": "parseInt",
	"Boolean": "parseBoolean",
	"Short": "parseShort",
	"Long": "parseLong",
	"Double": "parseDouble"
);

private map[str, str] typeValueByType = (
	"Float": "floatValue",
	"Integer": "intValue",
	"Boolean": "booleanValue",
	"Short": "shortValue",
	"Long": "longValue",
	"Double": "doubleValue"
);

private set[str] wrappers = domain(parseMethodByType);

private data Var = newVar(str name, str varType);

private map[str, Var] fieldsByName = ();
private map[str, Var] localVarsByName = ();

private bool shouldRewrite = false;

public void refactorAllParseToConvertStringToPrimitive(list[loc] locs) {
	for (fileLoc <- locs) {
		try {
			if (shouldContinueWithASTAnalysis(fileLoc)) {
				shouldRewrite = false;
				fieldsByName = ();
				refactorFileParseToConvertStringToPrimitive(fileLoc);
			}
		} catch: {
			println("Exception file: " + fileLoc.file);
			continue;
		}
	}
}

private bool shouldContinueWithASTAnalysis(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	return hasWrapper(javaFileContent) && findFirst(javaFileContent, ".valueOf(") != -1;
}

private bool hasWrapper(str javaFileContent) {
	for (wrapper <- wrappers) {
		if (findFirst(javaFileContent, wrapper) != -1)
			return true;
	}
	return false;
}


public void refactorFileParseToConvertStringToPrimitive(loc fileLoc) {
	unit = retrieveCompilationUnitFromLoc(fileLoc);
	
	unit = top-down-break visit(unit) {
		case (MethodDeclaration) `<MethodDeclaration mdl>`: {
			modified = false;
			localVarsByName = ();
			mdl = top-down-break visit(mdl) {
				case (MethodInvocation) `<ExpressionName expName>.valueOf(<ArgumentList? args>).<Identifier methodName>()`: {
					if("<expName>" in wrappers && "<methodName>" == typeValueByType["<expName>"]) {
						findFields(unit);
						findLocalVars(mdl);
						if (isArgumentAString(args)) {
							modified = true;
						}					
					}
					if (modified) {
						parseMethod = parseMethodByType["<expName>"];
						insert parse(#MethodInvocation, "<expName>.<parseMethod>(<args>)");
					}
				}
				// Eclipse special cases
				case (MethodInvocation) `(<ExpressionName expName>.valueOf(<ArgumentList? args>)).<Identifier methodName>()`: {
					if("<expName>" in wrappers && "<methodName>" == typeValueByType["<expName>"]) {
						findFields(unit);
						findLocalVars(mdl);
						if (isArgumentAString(args)) {
							modified = true;
						}					
					}
					if (modified) {
						parseMethod = parseMethodByType["<expName>"];
						insert parse(#MethodInvocation, "<expName>.<parseMethod>(<args>)");
					}
				}
				case (MethodInvocation) `<ExpressionName expName>.valueOf(<ArgumentList? args>)`: {
					if("<expName>" in wrappers) {
						findFields(unit);
						findLocalVars(mdl);
						if (isArgumentAString(args)) {
							modified = true;
						}					
					}
					if (modified) {
						parseMethod = parseMethodByType["<expName>"];
						insert parse(#MethodInvocation, "<expName>.<parseMethod>(<args>)");
					}
				}
			}
			if (modified) {
				shouldRewrite = true;
				insert mdl;
			}
		}
	}
	
	if (shouldRewrite) {
		writeFile(fileLoc, unit);
	} 
}

private void findFields(CompilationUnit unit) {
	if(isEmpty(fieldsByName)) {
		set[MethodVar] fields = findClassFields(unit);
		for (field <- fields) {
			fieldsByName[field.name] = newVar(field.name, field.varType);
		}
	}
}

private void findLocalVars(MethodDeclaration mdl) {
	if(isEmpty(localVarsByName)) {
		set[MethodVar] vars = findlocalVars(mdl);
		for (var <- vars) {
			localVarsByName[var.name] = newVar(var.name, var.varType);
		}
	}
}

private bool isArgumentAString(ArgumentList? args) {
	return isArgumentAFieldOrLocalVarString("<args>") || isStringLiteral("<args>");
}

private bool isArgumentAFieldOrLocalVarString(str arg) {
	return isExpReferencingAString(arg, fieldsByName) || isExpReferencingAString(arg, localVarsByName);
}

private bool isExpReferencingAString(str exp, map[str, Var] varByName) {
	if (exp in varByName) {
		var = varByName[exp];
		return var.varType == "String";
	}
	
	return false;
}

private bool isStringLiteral(str exp) {
	try {
		parse(#StringLiteral, exp);
		return true;
	} catch: {
		return false;
	}
}