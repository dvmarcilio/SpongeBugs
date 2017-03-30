module refactor::forloop::ProspectiveOperation

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import ParseTreeVisualization;
import Set;
import util::Math;
import MethodVar;
import String;

public data ProspectiveOperation = prospectiveOperation(Statement stmt, str operation);
public data ProspectiveOperation = prospectiveOperation(ExpressionStatement stmt2, str operation);

str FILTER = "filter";
str MAP = "map";
str FOR_EACH = "forEach";
str REDUCE = "reduce";
str ANY_MATCH = "anyMatch";
str NONE_MATCH = "noneMatch";

private set[MethodVar] methodLocalVars;

public void retrievePotentialOperations(set[MethodVar] localVars, EnhancedForStatement forStmt) {
	methodLocalVars = localVars;
	visit(forStmt) {
		case (EnhancedForStatement) `for ( <VariableModifier* _> <UnannType _> <VariableDeclaratorId _> : <Expression exp> ) <Statement stmt>`: {
			r = retrieveProspectiveOperationsFromStatement(stmt);
			println("prospective operations: " + toString(size(r)));
			for (prOp <- r) {
				println();
				println(prOp.operation);
				println(unparse(prOp.stmt2));
			}
		}
	}
}

private set[ProspectiveOperation] retrieveProspectiveOperationsFromStatement(Statement stmt) {
	set[ProspectiveOperation] prOps = {};
	top-down-break visit(stmt) {
		case Block blockStmt: {
			println("blockStatement");
			println(blockStmt);
			println();
			prOps += retrieveProspectiveOperationsFromBlock(blockStmt);
		}
		case IfThenStatement ifStmt: {
			println("ifThenStatement");
			println(ifStmt);
			println();
		}
		case IfThenElseStatement ifElseStmt: {
			println("ifThenElseStatement");
			println(ifElseStmt);
			println();
		}
		case ExpressionStatement stmt: prOps += retrieveProspectiveOperationFromSingleStatement(stmt);
	}
	return prOps;
}

private set[ProspectiveOperation] retrieveProspectiveOperationsFromBlock(Block blockStmt) {
	set[ProspectiveOperation] prOps = {};
	top-down visit(blockStmt) {
		case (IfThenStatement) `if ( <Expression exp> ) <Statement thenStmt>`: {
			prOps += retrieveProspectiveOperationsFromStatement(thenStmt);
		}
		case (IfThenElseStatement) `if ( <Expression exp> ) <StatementNoShortIf thenStmt> else <Statement elseStmt>`: {
			//retrieveProspectiveOperationsFromStatement(thenStmt);
			println("if else");
		}
		case ExpressionStatement stmt: prOps += retrieveProspectiveOperationFromSingleStatement(stmt);
	}
	println();
	return prOps;
}

private set[ProspectiveOperation] retrieveProspectiveOperationFromSingleStatement(ExpressionStatement stmt) {
	//visualize(stmt);
	if (isReducer(stmt))
		return {prospectiveOperation(stmt, REDUCE)};
	else
		return {prospectiveOperation(stmt, MAP)};
}

private bool isReducer(ExpressionStatement stmt) {
	visit (stmt) {
		case (Assignment) `<LeftHandSide lhs> <AssignmentOperator assignmentOp> <Expression _>`: {
			return isCompoundAssignmentOperator(assignmentOp) && isReferenceToNonFinalLocalVar(lhs);
		}
	}
	return false;
}

private bool isCompoundAssignmentOperator(AssignmentOperator assignmentOp) {
	operatorStr = unparse(assignmentOp);
	return operatorStr != "=" && operatorStr != "\>\>\>=" &&
		operatorStr != "^=";
}

private bool isReferenceToNonFinalLocalVar(LeftHandSide lhs) {
	varName = trim(unparse(lhs));
	var = findByName(methodLocalVars, varName);
	return !var.isFinal;
}