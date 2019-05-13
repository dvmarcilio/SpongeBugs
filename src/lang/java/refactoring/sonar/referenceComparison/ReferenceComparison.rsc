module lang::java::refactoring::sonar::referenceComparison::ReferenceComparison

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import Set;
import lang::java::\syntax::Java18;
import lang::java::util::CompilationUnitUtils;

private data Var = newVar(str name, str varType);

private map[str, Var] constantsByName = ();

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
	return findFirst(javaFileContent, "==") != -1 ;
}

public void refactorFileReferenceComparison(loc fileLoc) {
	unit = retrieveCompilationUnitFromLoc(fileLoc);
	findConstants(unit);
	
	unit = top-down-break visit(unit) {
		case (MethodDeclaration) `<MethodDeclaration mdl>`: {
			mdl = visit(mdl) {
				case (EqualityExpression) `<EqualityExpression lhs> == <RelationalExpression rhs>`: {
					map[str, Var] localVarsByName = findVarsInstantiatedWithinMethod(mdl);
					if (isComparisonOfInterest("<lhs>", "<rhs>", localVarsByName)) {
						println(fileLoc.file);
						println("<lhs> == <rhs>\n");
					}					
				} 
			}
		}
		case (EqualityExpression) `<EqualityExpression lhs> == <RelationalExpression rhs>`: {
			if (isComparisonOfInterest("<lhs>", "<rhs>")) {
				println(fileLoc.file);
				println("<lhs> == <rhs>\n");
			}
		}
	}

	if (shouldRewrite) {
		writeFile(fileLoc, unit);
	} 
}

private void findConstants(CompilationUnit unit) {
	visit(unit) {
		case (FieldDeclaration) `<FieldModifier* varMod> <UnannType varType> <VariableDeclaratorList vdl>;`: {
			visit(vdl) {
				case (VariableDeclaratorId) `<Identifier varId> <Dims? dims>`: { 
					if (isStaticFinal(varMod)) {
						varIdStr = trim("<varId>");
						constantsByName[varIdStr] = newVar(varIdStr, trim("<varType>"));
					}
				}
			}
		}
	}
}

private bool isStaticFinal(FieldModifier* varMod) {
	varModStr = "<varMod>";
	return contains(varModStr, "final") && contains(varModStr, "static");	
}

private map[str, Var] findVarsInstantiatedWithinMethod(MethodDeclaration mdl) {
	map[str, Var] varsWithinMethod = ();
	visit (mdl) {
		case (LocalVariableDeclaration) `<LocalVariableDeclaration lVDecl>`: {
			visit(lVDecl) {	
				case (LocalVariableDeclaration) `<VariableModifier* varMod> <UnannType varType> <VariableDeclaratorList vdl>`: {
					visit(vdl) {
						case (VariableDeclarator) `<VariableDeclaratorId varId> = new <TypeArguments? _> <ClassOrInterfaceTypeToInstantiate typeInstantiated> (<ArgumentList? _>)`: {
							varIdStr = trim("<varId>");
							varsWithinMethod[varIdStr] = newVar(varIdStr, trim("<varType>"));
						}
					}
				}
			}
		}
	}
	
	return varsWithinMethod;
}

private bool isComparisonOfInterest(str exp1, str exp2) {
	return isExpOfInterest(exp1, constantsByName) && isExpOfInterest(exp2, constantsByName);
}

private bool isComparisonOfInterest(str exp, str exp2, map[str, Var] localVarsByName) {
	if (trim(exp2) == "null") return false;
	exp = trim(exp);
	return isExpOfInterest(exp, localVarsByName, constantsByName) && isExpOfInterest(exp2, localVarsByName, constantsByName);
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