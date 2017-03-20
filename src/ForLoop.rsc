module ForLoop

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import ExceptionFinder;
import util::Math;

// TODO maybe return set[Identifier]
// avoids unparse()
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
		case (BasicForStatement) `for ( <ForInit? _> ; <Expression? _> ; <ForUpdate? _> ) <Statement stmt>`:
			isLoopEligibleForRefactor(stmt);
		case (EnhancedForStatement) `for ( <VariableModifier* _> <UnannType _> <VariableDeclaratorId _> : <Expression _> ) <Statement stmt>`: 
			isLoopEligibleForRefactor(stmt);
		case (BasicForStatementNoShortIf) `for ( <ForInit? _> ; <Expression? _> ; <ForUpdate? _> ) <StatementNoShortIf stmt>`:
			println("TODO");
		case (EnhancedForStatementNoShortIf) `for ( <VariableModifier* _> <UnannType _> <VariableDeclaratorId _> : <Expression _> ) <StatementNoShortIf stmt>`:
			println("TODO");
	}
}


// syntax BreakStatement = "break" Identifier? ";" ;
// syntax ThrowStatement = "throw" Expression ";" ;
// syntax Expression = LambdaExpression | AssignmentExpression ;
// syntax AssignmentExpression = ConditionalExpression | Assignment ;
// syntax Assignment = LeftHandSide AssignmentOperator Expression ;
// syntax LeftHandSide = ExpressionName | FieldAccess | ArrayAccess ;
// syntax ExpressionName = Identifier | AmbiguousName "." Identifier ;
// syntax AmbiguousName = Identifier | AmbiguousName "." Identifier  ;
// syntax Identifier = id: [$ A-Z _ a-z] !<< ID \ IDKeywords !>> [$ 0-9 A-Z _ a-z];
// syntax UnqualifiedClassInstanceCreationExpression = "new" TypeArguments? ClassOrInterfaceTypeToInstantiate "(" ArgumentList? ")" 

// TODO extract module and test it
private bool isLoopEligibleForRefactor(Statement stmt) {
	returnCount = 0;
	visit(stmt) {
		case (ThrowStatement) `throw new <TypeArguments? _> <ClassOrInterfaceTypeToInstantiate className> ( <ArgumentList? _>);`: {
			classNameStr = unparse(className);
			if (classNameStr in checkedExceptionClasses) {
				println("found checked exception (" + classNameStr + ") thrown inside a for statement.");
				return false;
			}
		}
		case (BreakStatement) `break <Identifier? _>;`: {
			println("found break statement inside a for statement.");
			return false;
		}
		case (ReturnStatement) `return <Expression? _>;`: {
			returnCount += 1;
		}
	}
	if (returnCount > 1) {
		println("returnCount: " + toString(returnCount)); 
		println(stmt);
		println();
		return false;
	}
	return true;
}