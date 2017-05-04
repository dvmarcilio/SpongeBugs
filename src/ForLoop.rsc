module ForLoop

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import LocalVariablesFinder;
import refactor::forloop::EnhancedLoopExpression;
import refactor::forloop::ForLoopBodyReferences;
import refactor::forloop::ForLoopToFunctional;
import refactor::forloop::ClassFieldsFinder;
import MethodVar;
import util::Math;

private set[str] checkedExceptionClasses;

private set[MethodVar] currentClassFields = {};

private bool alreadyComputedClassFields;

private int refactoredCount = 0;

public void findForLoops(list[loc] locs, set[str] checkedExceptions) {
	refactoredCount = 0;
	checkedExceptionClasses = checkedExceptions;
	for(fileLoc <- locs) {
		javaFileContent = readFile(fileLoc);
		try {
			unit = parse(#CompilationUnit, javaFileContent);
			alreadyComputedClassFields = false;
			lookForForStatements(unit);
		} catch:
			continue;	
	}
	println("refactoredCount: " + toString(refactoredCount));
}

private void lookForForStatements(CompilationUnit unit) {
	visit(unit) {
		case MethodDeclaration methodDeclaration:
			lookForEnhancedForStatementsInMethod(unit, methodDeclaration);
	}
}

private void lookForEnhancedForStatementsInMethod(CompilationUnit unit, MethodDeclaration methodDeclaration) {
	visit(methodDeclaration) {
		case (MethodDeclaration) `<MethodModifier* _> <MethodHeader methodHeader> <MethodBody methodBody>`:
			lookForEnhancedForStatementsInMethodBody(unit, methodHeader, methodBody);
	}
}

private void lookForEnhancedForStatementsInMethodBody(CompilationUnit unit, MethodHeader methodHeader, MethodBody methodBody) {
	set[MethodVar] availableVars = {};
	alreadyComputedCurrentMethodAvailableVars = false;
	
	top-down visit(methodBody) {
		case EnhancedForStatement forStmt: {
			
			if(!alreadyComputedClassFields) {
				currentClassFields = findClassFields(unit);
				alreadyComputedClassFields = true;
			}
			
			if(!alreadyComputedCurrentMethodAvailableVars) { 
				availableVars = currentClassFields + findLocalVariables(methodHeader, methodBody);
				alreadyComputedAvailableVars = true;
			}
			
			top-down visit(forStmt) {
				case EnhancedForStatement enhancedForStmt: {
					visit(enhancedForStmt) {
						case (EnhancedForStatement) `for ( <VariableModifier* _> <UnannType _> <VariableDeclaratorId iteratedVarName>: <Expression collectionId> ) <Statement stmt>`: {
							
							if(isLoopRefactorable(availableVars, collectionId, stmt)) {
							
								try {
									refactored = refactorEnhancedToFunctional(availableVars, enhancedForStmt, methodBody, iteratedVarName, collectionId);
									refactoredCount += 1;
									println("refactored: " + toString(refactoredCount));
									println(enhancedForStmt);
									println("---");
									println(refactored);
									println();
								} catch: {
									continue;
								}
								
							}
						}
					}
				}
			}		
		}
		
		case (EnhancedForStatementNoShortIf) `for ( <VariableModifier* _> <UnannType _> <VariableDeclaratorId _> : <Expression _> ) <StatementNoShortIf stmt>`:
			println("TODO");
	}
}

private bool isLoopRefactorable(set[MethodVar] methodLocalVariables, Expression exp, Statement stmt) {
	return loopBodyPassConditions(stmt) && isIteratingOnCollection(exp, methodLocalVariables) &&
		atMostOneReferenceToNonEffectiveFinalVar(methodLocalVariables, stmt);
}

// TODO extract module and test it
private bool loopBodyPassConditions(Statement stmt) {
	returnCount = 0;
	visit(stmt) {
		case (ThrowStatement) `throw new <TypeArguments? _> <ClassOrInterfaceTypeToInstantiate className> ( <ArgumentList? _>);`: {
			if ("<className>" in checkedExceptionClasses) return false;
		}
		
		case (BreakStatement) `break <Identifier? _>;`: return false;

		case (ReturnStatement) `return <Expression? returnExp>;`: {
			returnExpStr = unparse(returnExp);
			if(returnExpStr != "true" || returnExpStr != "false")
				return false;
			
			returnCount += 1;	
		}
	
		// labeled continue. 
		case (ContinueStatement) `continue <Identifier _>;`: return false;
	}
	
	if (returnCount > 1) return false;
	
	return true;
}