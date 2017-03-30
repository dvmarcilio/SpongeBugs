module refactor::forloop::NeededVariables

import IO;
import String;
import Set;
import lang::java::\syntax::Java18;
import ParseTree;
import MethodVar;
import refactor::forloop::ProspectiveOperation;

public set[str] retrieveNeededVariables(ProspectiveOperation prOp) {
	set[str] neededVariables = {};
	
	if (isReduce(prOp))
		return {};
	else if(isFilter(prOp))
		neededVariables += retrieveNeededVarsFromExpression(prOp.stmt);	
	else if (isLocalVariableDeclarationStatement(prOp.stmt))
		neededVariables += retrieveNeededVarsFromLocalVariableDeclarationStmt(prOp.stmt);	
 	else
		neededVariables += retrieveNeededVarsFromStatement(prOp.stmt);
	
	return neededVariables;
}

// XXX Parsing twice (isLocal... and this method) the stmt
// should not be a big deal since it's only a stmt from a prospective operation.
// Using this pattern (parsing to check if a stmt is of the type #Something) and then parsing again
// could refactor in the future to return a Tuple, with the bool and the parsed tree.
private set[str] retrieveNeededVarsFromLocalVariableDeclarationStmt(str stmt) {
	set[str] neededVariables = {};
	
	lvdlStmt = parse(#LocalVariableDeclarationStatement, stmt);
	
	visit(lvdlStmt) {	
		case ExpressionName expName: {
			visit(expName) {
				case Identifier id: neededVariables += unparse(id);
			}
		}	
	}
	
	return neededVariables;
}

// TODO verify if visit(Tree) works for a more generic traversal
// maybe it's possible to traverse only once
private set[str] retrieveNeededVarsFromExpression(str stmt) {
	set[str] neededVariables = {};
	
	exp = parse(#Expression, stmt);
	
	visit(exp) {
		case ExpressionName expName: {
			visit(expName) {
				case Identifier id: neededVariables += unparse(id);
			}
		}
	}
	
	return neededVariables;
}

private set[str] retrieveNeededVarsFromStatement(str stmt) {
	set[str] neededVariables = {};
	
	stmt = parse(#Statement, getCorrectStatementAsString(stmt));
	
	visit (stmt) {
		case ExpressionName expName: {
			visit(expName) {
				case Identifier id: neededVariables += unparse(id);
			}
		}
	}
	
	return neededVariables;
}

private str getCorrectStatementAsString(str stmt) {
	// stmt does not end with ';' it can't be parsed as a statement
	// it can also be a block
	if(!(endsWith(stmt, ";") || endsWith(stmt, "}")))
		return stmt + ";";
	return stmt;
}