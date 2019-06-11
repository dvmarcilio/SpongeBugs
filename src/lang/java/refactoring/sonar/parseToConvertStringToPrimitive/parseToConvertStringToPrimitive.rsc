module lang::java::refactoring::sonar::parseToConvertStringToPrimitive::parseToConvertStringToPrimitive

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import Set;
import Map;
import lang::java::util::CompilationUnitUtils;
import lang::java::util::MethodDeclarationUtils;
import lang::java::util::GeneralUtils;
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

private data RefactoredExp = refactoredExp(bool wasRefactored, Expression exp);
private data RefactoredMethodInvocation = refactoredMI(bool wasRefactored, MethodInvocation mi);

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
				case (LocalVariableDeclaration) `<UnannPrimitiveType varType> <Identifier varName> = <Expression rhs>`: {
					expRefactored = refactorExpression(unit, mdl, rhs);
					if (expRefactored.wasRefactored) {
						modified = true;
						insert parse(#LocalVariableDeclaration, "<varType> <varName> = <expRefactored.exp>");
					}
				}
				case (ReturnStatement) `return <Expression exp>;`: {
					methodReturnType = retrieveMethodReturnTypeAsStr(mdl);
					if (methodReturnType in getPrimitives() && isMethodInvocation("<exp>")) {	
						expRefactored = refactorExpression(unit, mdl, exp);
						if (expRefactored.wasRefactored) {
							modified = true;
							insert parse(#ReturnStatement, "return <expRefactored.exp>;");
						}
					}
				}
				case (Assignment) `<ExpressionName lhs> = <Expression rhs>`: {
					findFields(unit);
					findLocalVars(mdl);
					if (isLhsOfAPrimitiveType("<lhs>") && isMethodInvocation("<rhs>")) {
						expRefactored = refactorExpression(unit, mdl, rhs);
						if (expRefactored.wasRefactored) {
							modified = true;
							insert parse(#Assignment, "<lhs> = <expRefactored.exp>");
						}						
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

private RefactoredExp refactorExpression(CompilationUnit unit, MethodDeclaration mdl, Expression exp) {
	modified = false;
	refactoredExpression = top-down-break visit(exp) {
		case (MethodInvocation) `<ExpressionName expName>.valueOf(<ArgumentList? args>).equals(<ArgumentList? args2>)`: {
			continue;
		}
		case (MethodInvocation) `<ExpressionName expName>.valueOf(<ArgumentList? args>).compareTo(<ArgumentList? args2>)`: {
			continue;
		}
		case (MethodInvocation) `<ExpressionName expName>.valueOf(<ArgumentList? args>).<Identifier methodName>()`: {
			if("<expName>" in wrappers && "<methodName>" == typeValueByType["<expName>"]) {
				mi = refactorMethodInvocation(unit, mdl, expName, args);
				if (mi.wasRefactored) {
					modified = true;
					insert mi.mi;				
				}			
			}
		}
		// Eclipse special cases
		case (MethodInvocation) `(<ExpressionName expName>.valueOf(<ArgumentList? args>)).<Identifier methodName>()`: {
			if("<expName>" in wrappers && "<methodName>" == typeValueByType["<expName>"]) {
				mi = refactorMethodInvocation(unit, mdl, expName, args);
				if (mi.wasRefactored) {
					modified = true;
					insert mi.mi;				
				}					
			}
		}
		case (MethodInvocation) `<ExpressionName expName>.valueOf(<ArgumentList? args>)`: {
			if("<expName>" in wrappers) {
				mi = refactorMethodInvocation(unit, mdl, expName, args);
				if (mi.wasRefactored) {
					modified = true;
					insert mi.mi;				
				}				
			}
		}
	}
	
	return refactoredExp(modified, refactoredExpression);
}

private RefactoredMethodInvocation refactorMethodInvocation(CompilationUnit unit, MethodDeclaration mdl,
		ExpressionName expName, ArgumentList? args) {
	findFields(unit);
	findLocalVars(mdl);
	if (isArgumentAString(args)) {
		parseMethod = parseMethodByType["<expName>"];
		return refactoredMI(true, parse(#MethodInvocation, "<expName>.<parseMethod>(<args>)"));
	}
	return refactoredMI(false, parse(#MethodInvocation, "a.a()"));
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

private bool isLhsOfAPrimitiveType(str exp) {
	return isExpOfAPrimitiveType(exp, fieldsByName) || isExpOfAPrimitiveType(exp, localVarsByName);
}

private bool isExpOfAPrimitiveType(str exp, map[str, Var] varByName) {
	if (exp in varByName) {
		var = varByName[exp];
		return var.varType in getPrimitives();
	}
	
	return false;
}

private bool isMethodInvocation(str exp) {
	try {
		parse(#MethodInvocation, exp);
		return true;
	} catch: {
		return false;
	}
}
