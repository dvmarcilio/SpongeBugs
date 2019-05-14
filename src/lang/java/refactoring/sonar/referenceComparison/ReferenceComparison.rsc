module lang::java::refactoring::sonar::referenceComparison::ReferenceComparison

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import Set;
import lang::java::\syntax::Java18;
import lang::java::util::CompilationUnitUtils;
import lang::java::refactoring::forloop::MethodVar;
import lang::java::refactoring::forloop::LocalVariablesFinder;
import lang::java::refactoring::forloop::ClassFieldsFinder;


private data Var = newVar(str name, str varType);

private map[str, Var] fieldsByName = ();

private bool shouldRewrite = false;

private set[str] primitiveTypes = {"String", "int", "double", "float", "char", "byte", "Object"};

public void refactorAllReferenceComparison(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			if (shouldContinueWithASTAnalysis(fileLoc)) {
				shouldRewrite = false;
				refactorFileReferenceComparison(fileLoc);
			}
		} catch: {
			println("Exception file: " + fileLoc.file);
			continue;
		}
	}
}

private bool shouldContinueWithASTAnalysis(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	return findFirst(javaFileContent, "==") != -1 || findFirst(javaFileContent, "!=") != -1 ;
}

public void refactorFileReferenceComparison(loc fileLoc) {
	unit = retrieveCompilationUnitFromLoc(fileLoc);
	findFields(unit);
	
	unit = top-down-break visit(unit) {
		case (MethodDeclaration) `<MethodDeclaration mdl>`: {
			continueWithAnalysis = true;
			modified = false;
			visit(mdl) {
				case (MethodDeclarator) `<MethodDeclarator mDecl>`:
					continueWithAnalysis = findFirst("<mDecl>", "equals(") != 1;
			}
			if (continueWithAnalysis) {
				mdl = visit(mdl) {
					case (Expression) `<EqualityExpression lhs> == <RelationalExpression rhs>`: {
						map[str, Var] localVarsByName = findVarsInstantiatedInMethod(mdl);
						if (isComparisonOfInterest("<lhs>", "<rhs>", localVarsByName)) {
							modified = true;
							insert(parse(#Expression, "<lhs>.equals(<rhs>)"));
						}					
					}
					case (Expression) `<EqualityExpression lhs> != <RelationalExpression rhs>`: {
						map[str, Var] localVarsByName = findVarsInstantiatedInMethod(mdl);
						if (isComparisonOfInterest("<lhs>", "<rhs>", localVarsByName)) {
							modified = true;
							insert(parse(#Expression, "!<lhs>.equals(<rhs>)"));
						}					
					}
				}
				if (modified) {
					shouldRewrite = true;
					insert mdl;
				}
			}
		}
		case (Expression) `<EqualityExpression lhs> == <RelationalExpression rhs>`: {
			if (isComparisonOfInterest("<lhs>", "<rhs>")) {
				shouldRewrite = true;
				insert(parse(#Expression, "<lhs>.equals(<rhs>)"));
			}
		}
		case (Expression) `<EqualityExpression lhs> != <RelationalExpression rhs>`: {
			if (isComparisonOfInterest("<lhs>", "<rhs>")) {
				shouldRewrite = true;
				insert(parse(#Expression, "!<lhs>.equals(<rhs>)"));
			}
		}
		
	}

	if (shouldRewrite) {
		writeFile(fileLoc, unit);
	} 
}

private void findFields(CompilationUnit unit) {
	set[MethodVar] fields = findClassFields(unit);
	for (field <- fields) {
		fieldsByName[field.name] = newVar(field.name, field.varType);
	}
}

private map[str, Var] findVarsInstantiatedInMethod(MethodDeclaration mdl) {
	map[str, Var] varsInMethod = ();
	set[MethodVar] vars = findlocalVars(mdl);
	for (var <- vars) {
		varsInMethod[var.name] = newVar(var.name, var.varType);
	}
	return varsInMethod;
}

private bool isComparisonOfInterest(str exp1, str exp2) {
	return isExpOfInterest(exp1, fieldsByName) && isExpOfInterest(exp2, fieldsByName);
}

private bool isComparisonOfInterest(str exp, str exp2, map[str, Var] localVarsByName) {
	if (trim(exp2) == "null") return false;
	exp = trim(exp);
	return isExpOfInterest(exp, localVarsByName, fieldsByName) && isExpOfInterest(exp2, localVarsByName, fieldsByName);
}

private bool isExpOfInterest(str exp, map[str, Var] map1, map[str, Var] map2) {
	return isExpOfInterest(exp, map1) || isExpOfInterest(exp, map2);
}

private bool isExpOfInterest(str exp, map[str, Var] varByName) {
	if (isLiteralOtherThanString(exp))
		return false;
	
	if(exp in varByName) {
		var = varByName[exp];
		return var.varType notin primitiveTypes;
	}
	return false;
}

private bool isLiteralOtherThanString(str exp) {
	try {
		parse(#StringLiteral, exp);
		return false;
	} catch: {
		return isLiteral(exp);
	}
}

private bool isLiteral(str exp) {
	try {
		parse(#Literal, exp);
		return true;
	} catch:
		return false;
}