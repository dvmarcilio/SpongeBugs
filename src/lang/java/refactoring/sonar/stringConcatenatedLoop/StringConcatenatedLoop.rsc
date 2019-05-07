module lang::java::refactoring::sonar::stringConcatenatedLoop::StringConcatenatedLoop

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import Set;
import lang::java::util::MethodDeclarationUtils;
import lang::java::util::CompilationUnitUtils;
import lang::java::refactoring::forloop::LocalVariablesFinder;
import lang::java::refactoring::forloop::MethodVar;

private bool shouldRewrite = false;

public void refactorAllStringConcatenatedLoop(list[loc] locs) {
	for(fileLoc <- locs) {
		//try {
			if (shouldContinueWithASTAnalysis(fileLoc)) {
				shouldRewrite = false;
				refactorStringConcatenatedLoop(fileLoc);
			}
		//} catch: {
		//	println("Exception file: " + fileLoc.file);
		//	continue;
		//}	
	}
}

private bool shouldContinueWithASTAnalysis(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	return containForLoop(javaFileContent) && findFirst(javaFileContent, "+=") != -1;
}

private bool containForLoop(str javaFileContent) {
	return findFirst(javaFileContent, "for (") != -1 || findFirst(javaFileContent, "for(") != -1;
}

public void refactorStringConcatenatedLoop(loc fileLoc) {
	unit = retrieveCompilationUnitFromLoc(fileLoc);
	
	unit = visit(unit) {
		case (MethodDeclaration) `<MethodDeclaration mdl>`: {
			modified = false;
			mdl = visit(mdl) {
				case (BasicForStatement) `<BasicForStatement forStmt>`: { 
					BasicForStatement = top-down-break visit(forStmt) {
						case (Assignment) `<ExpressionName expLHS> += <Expression exp>`: {
							if(isStringAndDeclaredWithinMethod(mdl, expLHS) && methodReturnsStringFromExpLHS(mdl, expLHS)) {
								println("case 1");
							}
						}
						case (Assignment) `<ExpressionName expLHS> = <ExpressionName expRHS> + <ExpressionName expRHS2>`: {
							if (<"expLHS"> == <"expRHS">) {
								if(isStringAndDeclaredWithinMethod(mdl, expLHS)) {							
									println("case 2");
								}
							}
						}
						case (Assignment) `<ExpressionName expLHS> = <ExpressionName expRHS> + <StringLiteral strLiteral>`: {
							if (<"expLHS"> == <"expRHS">) {
								if(isStringAndDeclaredWithinMethod(mdl, expLHS)) {							
									println("case 3");
								}
							}
						}
					}
				}
			}
		}
	}
	
}

private bool isStringAndDeclaredWithinMethod(MethodDeclaration mdl, ExpressionName exp) {
	set[MethodVar] vars = findVars(mdl);
	if ("<exp>" notin retrieveNonParametersNames(vars)) {
		return false;
	}
	
	MethodVar var = findByName(vars, "<exp>");
	return isString(var) && !var.isParameter;
}

private set[MethodVar] findVars(MethodDeclaration mdl) {
	visit (mdl) {
		case (MethodDeclaration) `<MethodModifier* mds> <MethodHeader methodHeader> <MethodBody mBody>`: {
			return findLocalVariables(methodHeader, mBody);
		}
	}
	return {};
}

private bool methodReturnsStringFromExpLHS(MethodDeclaration mdl, ExpressionName exp) {
	methodReturnsString = false;
	returnsExpString = false;
	visit (mdl) {
		case (MethodDeclaration) `<MethodModifier* mds> <MethodHeader methodHeader> <MethodBody mBody>`: {
			visit (methodHeader) {
				case (MethodHeader) `<Result returnType> <MethodDeclarator _> <Throws? _>`: {
					methodReturnsString = trim("<returnType>") == "String";
				}
			}
		}
		case (ReturnStatement) `return <ExpressionName exp>;`: {
			returnsExpString = true;
		}
	}
	return methodReturnsString && returnsExpString;
}
