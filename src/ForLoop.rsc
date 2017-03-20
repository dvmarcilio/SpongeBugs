module ForLoop

import IO;
import lang::java::\syntax::Java18;
import ParseTree;

public void findForLoops(list[loc] locs) {
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
			lookForBreakingPreConditions(stmt);
		case (EnhancedForStatement) `for ( <VariableModifier* _> <UnannType _> <VariableDeclaratorId _> : <Expression _> ) <Statement stmt>`: 
			lookForBreakingPreConditions(stmt);
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

private void lookForBreakingPreConditions(Statement stmt) {
	visit(stmt) {
		case (ThrowStatement) `throw new <TypeArguments? _> <ClassOrInterfaceTypeToInstantiate className> ( <ArgumentList? _>);`: {
			println(className);
		}
		case (BreakStatement) `break <Identifier? _>;`: {
			println("break");
		}
	}
}