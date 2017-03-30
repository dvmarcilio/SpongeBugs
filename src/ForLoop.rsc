module ForLoop

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import LocalVariablesFinder;
import EnhancedLoopExpression;
import refactor::forloop::ForLoopBodyReferences;
import refactor::forloop::ProspectiveOperation;
import MethodVar;

private set[str] checkedExceptionClasses;

public void findForLoops(list[loc] locs, set[str] checkedExceptions) {
	checkedExceptionClasses = checkedExceptions;
	for(fileLoc <- locs) {
		javaFileContent = readFile(fileLoc);
		try {
			unit = parse(#CompilationUnit, javaFileContent);
			lookForForStatements(unit);
		} catch:
			continue;	
	}
}

private void lookForForStatements(CompilationUnit unit) {
	iteratedVariable = "";
	visit(unit) {
		case MethodDeclaration methodDeclaration:
			lookForEnhancedForStatementsInMethod(methodDeclaration);
	}
}

private void lookForEnhancedForStatementsInMethod(MethodDeclaration methodDeclaration) {
	visit(methodDeclaration) {
		case (MethodDeclaration) `<MethodModifier* _> <MethodHeader methodHeader> <MethodBody methodBody>`:
			lookForEnhancedForStatementsInMethodBody(methodHeader, methodBody);
	}
}

private void lookForEnhancedForStatementsInMethodBody(MethodHeader methodHeader, MethodBody methodBody) {
	visit(methodBody) {
		case EnhancedForStatement forStmt: {
			visit(forStmt) {
				case (EnhancedForStatement) `for ( <VariableModifier* _> <UnannType _> <VariableDeclaratorId _> : <Expression exp> ) <Statement stmt>`: {
					methodLocalVariables = findLocalVariables(methodHeader, methodBody);
					checkLoopEligibilityForRefactor(methodLocalVariables, exp, stmt);
					retrievePotentialOperations(methodLocalVariables, forStmt);
				}
			}		
		}
		
		case (EnhancedForStatementNoShortIf) `for ( <VariableModifier* _> <UnannType _> <VariableDeclaratorId _> : <Expression _> ) <StatementNoShortIf stmt>`:
			println("TODO");
	}
}

private bool checkLoopEligibilityForRefactor(set[MethodVar] methodLocalVariables, Expression exp, Statement stmt) {
	return loopBodyPassConditions(stmt) && isIteratingOnCollection(exp, methodLocalVariables) &&
		atMostOneReferenceToNonEffectiveFinalVar(methodLocalVariables, stmt);
}

// TODO extract module and test it
private bool loopBodyPassConditions(Statement stmt) {
	returnCount = 0;
	visit(stmt) {
		case (ThrowStatement) `throw new <TypeArguments? _> <ClassOrInterfaceTypeToInstantiate className> ( <ArgumentList? _>);`: {
			classNameStr = unparse(className);
			if (classNameStr in checkedExceptionClasses) return false;
		}
		
		case (BreakStatement) `break <Identifier? _>;`: return false;

		case (ReturnStatement) `return <Expression? _>;`: returnCount += 1;

		case (ContinueStatement) `continue <Identifier? _>;`: return false;
	}
	
	if (returnCount > 1) return false;
	
	return true;
}