module refactor::forloop::UsedVariables

import IO;
import String;
import Set;
import lang::java::\syntax::Java18;
import ParseTree;
import MethodVar;
import refactor::forloop::ProspectiveOperation;

public set[str] retrieveUsedVariables(ProspectiveOperation prOp) {
	set[str] usedVariables = {};
	
	if (isReduce(prOp))
		return {};
	else if(isFilter(prOp))
		usedVariables += retrieveUsedVarsFromExpression(prOp.stmt);	
	else if (isLocalVariableDeclarationStatement(prOp.stmt))
		usedVariables += retrieveUsedVarsFromLocalVariableDeclarationStmt(prOp.stmt);	
 	else
		usedVariables += retrieveUsedVarsFromStatement(prOp.stmt);
	
	return usedVariables;
}

// XXX Parsing twice (isLocal... and this method) the stmt
// should not be a big deal since it's only a stmt from a prospective operation.
// Using this pattern (parsing to check if a stmt is of the type #Something) and then parsing again
// could refactor in the future to return a Tuple, with the bool and the parsed tree.
private set[str] retrieveUsedVarsFromLocalVariableDeclarationStmt(str stmt) {
	set[str] usedVariables = {};
	
	lvdlStmt = parse(#LocalVariableDeclarationStatement, stmt);
	
	visit(lvdlStmt) {	
		case ExpressionName expName: {
			visit(expName) {
				case Identifier id: usedVariables += unparse(id);
			}
		}	
	}
	
	return usedVariables;
}

// TODO verify if visit(Tree) works for a more generic traversal
// maybe it's possible to traverse only once
private set[str] retrieveUsedVarsFromExpression(str stmt) {
	set[str] usedVariables = {};
	
	exp = parse(#Expression, stmt);
	
	visit(exp) {
		case ExpressionName expName: {
			visit(expName) {
				case Identifier id: usedVariables += unparse(id);
			}
		}
	}
	
	return usedVariables;
}

private set[str] retrieveUsedVarsFromStatement(str stmt) {
	set[str] usedVariables = {};
	
	stmt = parse(#Statement, getCorrectStatementAsString(stmt));
	
	visit (stmt) {
		case ExpressionName expName: {
			visit(expName) {
				case Identifier id: usedVariables += unparse(id);
			}
		}
	}
	
	return usedVariables;
}

private str getCorrectStatementAsString(str stmt) {
	// stmt does not end with ';' it can't be parsed as a statement
	// it can also be a block
	if(!(endsWith(stmt, ";") || endsWith(stmt, "}")))
		return stmt + ";";
	return stmt;
}