module lang::java::refactoring::forloop::EnhancedForLoopRefactorer

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import util::Math;
import lang::java::refactoring::forloop::LocalVariablesFinder;
import lang::java::refactoring::forloop::EnhancedLoopExpression;
import lang::java::refactoring::forloop::ForLoopBodyReferences;
import lang::java::refactoring::forloop::ForLoopToFunctional;
import lang::java::refactoring::forloop::ClassFieldsFinder;
import lang::java::refactoring::forloop::MethodVar;

private bool PRINT_DEBUG = false;

public set[str] checkedExceptionClasses = {};

private set[MethodVar] currentClassFields = {};

private bool alreadyComputedClassFields = false;

private int refactoredCount = 0;

// Method for debugging. Not used by driver
public void forLoopToFunctional(list[loc] locs, set[str] checkedExceptions) {
	refactoredCount = 0;
	checkedExceptionClasses = checkedExceptions;
	for(fileLoc <- locs) {
		javaFileContent = readFile(fileLoc);
		try {
			unit = parse(#CompilationUnit, javaFileContent);
			refactorForLoopToFunctional(unit);
		} catch:
			continue;	
	}
	println("refactoredCount: " + toString(refactoredCount));
}

// Losing formatting after a method is refactored.
public tuple[int occurrences, CompilationUnit unit] refactorForLoopToFunctional(CompilationUnit unit) {
	int occurrences = 0;
	alreadyComputedClassFields = false;
	CompilationUnit refactoredUnit = visit(unit) {
		case (MethodDeclaration) `<MethodModifier* mds> <MethodHeader methodHeader> <MethodBody mBody>`: {
			MethodBody refactoredMethodBody = visit(mBody) {
				case MethodBody methodBody: {
					refactored = refactorEnhancedForStatementsInMethodBody(unit, methodHeader, methodBody);
					occurrences += refactored.occurrences;
					insert refactored.body; 	  				
				}
			};
			
			insert((MethodDeclaration) `<MethodModifier* mds> <MethodHeader methodHeader> <MethodBody refactoredMethodBody>`);
		}
	};
	
	return <occurrences, refactoredUnit>;
}

// TODO What happens when two for statements are refactored inside the same method?
public tuple[MethodBody body, int occurrences] refactorEnhancedForStatementsInMethodBody(CompilationUnit unit, MethodHeader methodHeader, MethodBody methodBody) {
	set[MethodVar] availableVars = {};
	alreadyComputedCurrentMethodAvailableVars = false;
	occurrences = 0;
	
	MethodBody refactoredMethodBody = methodBody; 
	
	top-down visit(methodBody) {
		case EnhancedForStatement enhancedForStmt: 
			visit(enhancedForStmt) {
			
				case (EnhancedForStatement) `for ( <VariableModifier* _> <UnannType _> <VariableDeclaratorId iteratedVarName>: <Expression collectionId> ) <Statement loopBody>`: {
					
					if(!alreadyComputedClassFields) {
						currentClassFields = findClassFields(unit);
						alreadyComputedClassFields = true;
					}
					
					if(!alreadyComputedCurrentMethodAvailableVars) { 
						methodVars = findLocalVariables(methodHeader, methodBody);
						availableVars = retainLocalVariablesIfDuplicates(currentClassFields, methodVars);
						alreadyComputedAvailableVars = true;
					}
									
					if(isLoopRefactorable(availableVars, collectionId, loopBody)) {
					
						try {
							refactoredMethodBody = refactorEnhancedToFunctional(availableVars, enhancedForStmt, methodBody, iteratedVarName, collectionId);
							occurrences += 1;
							
							refactoredCount += 1;
							
							if(PRINT_DEBUG) {
								println("refactored: " + toString(refactoredCount));
								println(enhancedForStmt);
								println("---");
								println(refactoredMethodBody);
								println();
							}
						} catch: {
							// ignore. continuing
							// 'continue' do not works as expected in 'visit' statements
							;	
						}
					}
				}
				
			}
		
		case (EnhancedForStatementNoShortIf) `for ( <VariableModifier* _> <UnannType _> <VariableDeclaratorId _> : <Expression _> ) <StatementNoShortIf stmt>`:
			println("TODO");
	}
	
	return <refactoredMethodBody, occurrences>;
}

private bool isLoopRefactorable(set[MethodVar] availableVariables, Expression collectionId, Statement loopBody) {
	return loopBodyPassConditions(loopBody) && isIteratingOnCollection(collectionId, availableVariables) &&
		atMostOneReferenceToNonEffectiveFinalVar(availableVariables, loopBody);
}

// TODO extract module and test it
private bool loopBodyPassConditions(Statement loopBody) {
	returnCount = 0;
	visit(loopBody) {
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
		
		// TODO remove in case we refactor loops with if with continue
		case ContinueStatement continueStmt: return false;
		
		// labeled continue. 
		case (ContinueStatement) `continue <Identifier _>;`: return false;
	}
	
	if (returnCount > 1) return false;
	
	return true;
}