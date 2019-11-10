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

// StringBuilder and String common methods
// String actually has indexOf that takes 'char' as argument
// Leaving it out to assure correctness
private set[str] commonMethods = {"substring", "length", "charAt", 
	"codePointAt", "codePointBefore", "codePointCount"};

// Just so we don't get a unitialized exception
ExpressionName expLHSToConsider = parse(#ExpressionName, "a");

public void refactorAllStringConcatenatedLoop(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			if (shouldContinueWithASTAnalysis(fileLoc)) {
				shouldRewrite = false;
				refactorStringConcatenatedLoop(fileLoc);
			}
		} catch: {
			println("Exception file (StringConcatenatedLoop): " + fileLoc.file);
			continue;
		}	
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
				
				case (DoStatement) `<DoStatement doStmt>`: {
					refactored = refactorLoop(doStmt, mdl);
					if ("<refactored>" != "<doStmt>") {
						modified = true;
						DoStatement refactored = parse(#DoStatement, "<refactored>");
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
	set[MethodVar] vars = findlocalVars(mdl);
	if ("<exp>" notin retrieveNonParametersNames(vars)) {
		return false;
	}
	
	MethodVar var = findByName(vars, "<exp>");
	return isString(var) && !var.isParameter;
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
	mdl = replaceReferencesWithToStringCall(mdl, expName);

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

private MethodDeclaration replaceReferencesWithToStringCall(MethodDeclaration mdl, ExpressionName varName) {
	mdl = visit(mdl) {
		// can be made better
		case (MethodInvocation) `<MethodInvocation mi>`: {
			modified = false;
			mi = bottom-up-break visit(mi) {
				case (ExpressionName) `<ExpressionName expressionName>`: {
					if (trim("<expressionName>") == "<varName>" && shouldChangeMethodInvocation(mi, varName)) {
						modified = true;
						insert parse(#ExpressionName, "<varName>.toString");
					}
				}
				case (Primary) `<Primary primary>`: {
					if (trim("<primary>") == "<varName>" && shouldChangeMethodInvocation(mi, varName)) {
						modified = true;
						insert parse(#Primary, "<varName>.toString");
					}
				}
			}
			if (modified)
				insert parse(#MethodInvocation, replaceAll("<mi>", "<varName>.toString", "<varName>.toString()"));
		}
		
		case (ArgumentList) `<ArgumentList argumentList>`: {
			modified = false;
			argumentList = visit(argumentList) {
				case (Expression) `<Expression possibleString>`: {
					if (trim("<possibleString>") == "<varName>") {
						modified = true;
						insert parse(#Expression, "<varName>.toString()");
					}
				}
			}
			if (modified)
				insert argumentList;
		}
	}
	
	return mdl;
}

private bool shouldChangeMethodInvocation(MethodInvocation mi, ExpressionName varName) {
	miStr = "<mi>";
	return doesNotCallMethod(miStr, varName, "append") &&
		doesNotCallMethod(miStr, varName, "toString") &&
		!callsACommonMethod(miStr);
}

private bool doesNotCallMethod(str miStr, ExpressionName varName, str methodName) {
	return findFirst(miStr, "<varName>.<methodName>(") == -1;
}

private bool callsACommonMethod(str miStr) {
	for (commonMethod <- commonMethods) {
		if (findFirst(miStr, ".<commonMethod>(") != -1)
			return true;
	}
	return false;
}