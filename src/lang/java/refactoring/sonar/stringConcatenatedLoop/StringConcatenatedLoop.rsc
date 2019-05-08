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

// Just so we don't get a unitialized exception
ExpressionName expLHSToConsider = parse(#ExpressionName, "a");

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
					refactored = refactorLoop(forStmt, mdl);
					if ("<refactored>" != "<forStmt>") {
						modified = true;
						BasicForStatement refactored = parse(#BasicForStatement, "<refactored>");
						insert refactored;
					}
				}
				
				case (EnhancedForStatement) `<EnhancedForStatement forStmt>`: {
					refactored = refactorLoop(forStmt, mdl);
					if ("<refactored>" != "<forStmt>") {
						modified = true;
						EnhancedForStatement refactored = parse(#EnhancedForStatement, "<refactored>");
						insert refactored;
					}
				}
				
				case (WhileStatement) `<WhileStatement whileStmt>`: {
					refactored = refactorLoop(whileStmt, mdl);
					if ("<refactored>" != "<whileStmt>") {
						modified = true;
						WhileStatement refactored = parse(#WhileStatement, "<refactored>");
						insert refactored;
					}
				}
				
			}
			if (modified) {
				shouldRewrite = true;
				mdlRefactored = ref(mdl, expLHSToConsider);
				insert (MethodDeclaration) `<MethodDeclaration mdlRefactored>`;
			}
		}	
	}
	
	if (shouldRewrite) {
		writeFile(fileLoc, unit);
	}
}

private Tree refactorLoop(Tree loopStmt, MethodDeclaration mdl) {
	loopStmt = top-down-break visit(loopStmt) {
		case (StatementExpression) `<ExpressionName expLHS> += <Expression exp>`: {
			if(isStringAndDeclaredWithinMethod(mdl, expLHS) && methodReturnsStringFromExpLHS(mdl, expLHS)) {
				expLHSToConsider = expLHS;
				refactoredToAppend = parse(#StatementExpression, "<expLHS>.append(<exp>)");
				insert refactoredToAppend;
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
	return loopStmt;
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

private MethodDeclaration ref(MethodDeclaration mdl, ExpressionName expName) {	
	mdl = visit(mdl) {
		case (LocalVariableDeclaration) `<UnannType varType> <Identifier varId> <Dims? _> = <Expression expRHS>`: {
			if (trim("<varType>") == "String" && trim("<varId>") == "<expName>") {
				lvDecl = parse(#LocalVariableDeclaration, "StringBuilder <varId> = new StringBuilder(<expRHS>)");
				insert lvDecl;
			}
		}
		
		case (StatementExpression) `<ExpressionName expLHS> <AssignmentOperator op> <Expression expRHS>`: {
			if (expLHS == expName && trim("<op>") == "=") {
				assignmentExp = parse(#StatementExpression, "<expLHS> = new StringBuilder(<expRHS>)");
				insert assignmentExp;
			}
			
			if (expLHS == expName && trim("<op>") == "+=") {
				assignmentExp = parse(#StatementExpression, "<expLHS>.append(<expRHS>)");
				insert assignmentExp;
			}
		}
		
		case (ReturnStatement) `<ReturnStatement returnStmt>`: {
			// Unfortunately there is a bug when parsing a ReturnStatement, we have to go deeper and substitute just the expression
			returnStmt = visit(returnStmt) {		
				case (ReturnStatement) `return <Expression returnExp>;`: {
					returnExp = visit(returnExp) {
						case (Expression) `<Expression _>`: {
							if (trim("<returnExp>") == "<expName>") {
								returnExpRefactored = parse(#Expression, "<expName>.toString()");
								insert returnExpRefactored;
							}
						}
					}
					insert (ReturnStatement) `return <Expression returnExp>;`;
				}
			}
			insert returnStmt;
		}
	}
	
	return mdl;
}
