module lang::java::refactoring::forloop::UsedVariables

import IO;
import String;
import Set;
import lang::java::\syntax::Java18;
import ParseTree;
import lang::java::refactoring::forloop::MethodVar;
import lang::java::refactoring::forloop::ProspectiveOperation;

public set[str] retrieveUsedVariables(ProspectiveOperation prOp) {
	set[str] usedVariables = {};
	
	if(isFilter(prOp))
		usedVariables += retrieveUsedVarsFromFilter(prOp.stmt);	
	else if (isLocalVariableDeclarationStatement(prOp.stmt))
		usedVariables += retrieveUsedVarsFromLocalVariableDeclarationStmt(prOp.stmt);	
 	else
		usedVariables += retrieveUsedVarsFromStatement(prOp.stmt);
	
	return usedVariables;
}


private set[str] retrieveUsedVarsFromFilter(str stmt) {
	if(isIfThenStatement(stmt))
		return retrieveUsedVarsFromIfThenStmt(stmt);
	else 
		return retrieveUsedVarsFromExpression(stmt);
}

public bool isIfThenStatement(str stmt) {
	try {
		parse(#IfThenStatement, stmt);
		return true;
	} catch: return false;
}

// XXX pretty redundant lookups for 'ExpressionName' around this module
private set[str] retrieveUsedVarsFromIfThenStmt(str stmt) {
	set[str] usedVariables = {};
	ifThenStmt = parse(#IfThenStatement, stmt);
	
	visit(ifThenStmt) {
		case ExpressionName expName: {
			visit(expName) {
				case Identifier id: usedVariables += unparse(id);
			}
		}
	}
	
	return usedVariables;
}

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