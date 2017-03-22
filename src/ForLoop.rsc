module ForLoop

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import util::Math;
import LocalVariablesFinder;

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
	visit(unit) {
		case (MethodDeclaration) `<MethodModifier* _> <MethodHeader _> <MethodBody methodBody>`: {
			bool findEffectiveFinalLocalVars = doesMethodHaveAnEligibleForLoop(methodBody);
			if (findEffectiveFinalLocalVars)
				findLocalVariables(methodBody);
		}
	}
}

private bool doesMethodHaveAnEligibleForLoop(MethodBody methodBody) {
	visit(methodBody) {
		case (EnhancedForStatement) `for ( <VariableModifier* _> <UnannType _> <VariableDeclaratorId _> : <Expression _> ) <Statement stmt>`: 
			return isLoopEligibleForRefactor(stmt);
		case (EnhancedForStatementNoShortIf) `for ( <VariableModifier* _> <UnannType _> <VariableDeclaratorId _> : <Expression _> ) <StatementNoShortIf stmt>`:
			println("TODO");
	}
	return false;
}

// TODO extract module and test it
private bool isLoopEligibleForRefactor(Statement stmt) {
	returnCount = 0;
	visit(stmt) {
		case (ThrowStatement) `throw new <TypeArguments? _> <ClassOrInterfaceTypeToInstantiate className> ( <ArgumentList? _>);`: {
			classNameStr = unparse(className);
			if (classNameStr in checkedExceptionClasses) {
				//println("found checked exception (" + classNameStr + ") thrown inside a for statement.");
				return false;
			}
		}
		case (BreakStatement) `break <Identifier? _>;`: {
			//println("found break statement inside a for statement.");
			return false;
		}
		case (ReturnStatement) `return <Expression? _>;`: {
			returnCount += 1;
		}
		// LambdaFicator restructures code to eliminate 'continue'
		// if we don't do this, we should not allow 'continue'
		// Even if we do it, no labeled 'continue' are allowed
		case (ContinueStatement) `continue <Identifier? _>;`: {
			//println("found continue statement inside a for statement.");
			return false;
		}
	}
	if (returnCount > 1) {
		//println("more than one (" + toString(returnCount) + " total) return statements inside a for statement."); 
		// println(stmt);
		return false;
	}
	return true;
}
