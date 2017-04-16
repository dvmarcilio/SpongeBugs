module refactor::forloop::ProspectiveOperation

import IO;
import List;
import String;
import lang::java::\syntax::Java18;
import ParseTree;
import MethodVar;
import refactor::forloop::OperationType;
import ParseTreeVisualization;

public data ProspectiveOperation = prospectiveOperation(str stmt, str operation);

private list[MethodVar] methodLocalVars;

public list[ProspectiveOperation] retrieveProspectiveOperations(set[MethodVar] localVars, EnhancedForStatement forStmt) {
	methodLocalVars = localVars;
	list[ProspectiveOperation] prospectiveOperations = [];
	top-down visit(forStmt) {
		case (EnhancedForStatement) `for ( <VariableModifier* _> <UnannType _> <VariableDeclaratorId _> : <Expression _> ) <Statement stmt>`: {
			prospectiveOperations = retrieveProspectiveOperationsFromStatement(stmt);
			prospectiveOperations = markLastStmtAsEager(prospectiveOperations);
		}
	}
	return prospectiveOperations;
}

private list[ProspectiveOperation] retrieveProspectiveOperationsFromStatement(Statement stmt) {
	list[ProspectiveOperation] prOps = [];
	top-down-break visit(stmt) {
		case Block block: {
			prOps += retrieveProspectiveOperationsFromBlock(block);
		}
		case IfThenStatement ifStmt: {
			prOps += retrieveProspectiveOperationsFromIfThenStatement(ifStmt);
		}
		case IfThenElseStatement ifElseStmt: {
			println("IfThenElseStatement");
			println(ifElseStmt);
			println();
		}
		case ExpressionStatement expStmt: {
			statement = parse(#Statement, unparse(expStmt));
			prOps += retrieveProspectiveOperationFromSingleStatement(statement);
		}
	}
	return prOps;
}


// XXX we might need to save `if (exp)` when a filter is added
private list[ProspectiveOperation] retrieveProspectiveOperationsFromBlock(Block block) {
	list[ProspectiveOperation] prOps = [];
	top-down-break visit(block) {
		case BlockStatement blockStatement: {
			top-down-break visit(blockStatement) {
				case (IfThenStatement) `if ( <Expression exp> ) <Statement thenStmt>`: {
					ifThenStmt = [IfThenStatement] "if (<exp>) <thenStmt>";
					prOps += retrieveProspectiveOperationsFromIfThenStatement(ifThenStmt);
				}
				case (IfThenElseStatement) `if ( <Expression exp> ) <StatementNoShortIf thenStmt> else <Statement elseStmt>`: {
					//retrieveProspectiveOperationsFromStatement(thenStmt);
					println("if else");
				}
				case LocalVariableDeclarationStatement lvdlStmt: {
					// not an if, so it's a map
					prOps += prospectiveOperation(unparse(lvdlStmt), MAP);
				} 
				case StatementWithoutTrailingSubstatement otherStmt: {
					statement = parse(#Statement, unparse(otherStmt));
					prOps += retrieveProspectiveOperationFromSingleStatement(statement);
				}
			}
		}
	}
	return prOps;
}

private list[ProspectiveOperation] retrieveProspectiveOperationsFromIfThenStatement(IfThenStatement ifStmt) {
	list[ProspectiveOperation] prOps = [];
	foundReturn = false;
	top-down-break visit (ifStmt) {
		case (IfThenStatement) `if ( <Expression exp> ) <Statement thenStmt>`: {
			top-down-break visit (thenStmt) {
				case Statement stmt: {
					visit(stmt) {
						case (ReturnStatement) `return <Expression returnExp>;`: {
							foundReturn = true;
							if ("<returnExp>" == "true")
								prOps += prospectiveOperation(unparse(exp), ANY_MATCH);
							else if ("<returnExp>" == "false")
								prOps += prospectiveOperation(unparse(exp), NONE_MATCH);
						}
					}
						
					if (!foundReturn) {
						prOps += prospectiveOperation(unparse(exp), FILTER);
						prOps += retrieveProspectiveOperationsFromStatement(thenStmt);
					}
				}
			}
		}
	}
	return prOps;
}

private ProspectiveOperation retrieveProspectiveOperationFromSingleStatement(Statement statement) {
	if (isReducer(statement))
		return prospectiveOperation(unparse(statement), REDUCE);
	else
		return prospectiveOperation(unparse(statement), MAP);
}

private bool isReducer(Statement statement) {
	visit (statement) {
		case (Assignment) `<LeftHandSide lhs> <AssignmentOperator assignmentOp> <Expression _>`:
			return isCompoundAssignmentOperator(assignmentOp) && isReferenceToNonFinalLocalVar(lhs);
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
	return !isEffectiveFinal(var);
}

private list[ProspectiveOperation] markLastStmtAsEager(list[ProspectiveOperation] prOps) {
	lastPrOp = prOps[-1];
	if(lastPrOp.operation == MAP)
		lastPrOp.operation = FOR_EACH;
	
	// all elements but the last + the last one (eagerized or not)
	return prefix(prOps) + lastPrOp;
}

public bool isMergeable(ProspectiveOperation prOp) {
	return isFilter(prOp) || isMap (prOp) || isForEach(prOp);
}

public bool isEagerOperation(ProspectiveOperation prOp) {
	return !isLazyOperation(prOp);
}

public bool isLazyOperation(ProspectiveOperation prOp) {
	return isFilter(prOp) || isMap(prOp);
}

public bool isFilter(ProspectiveOperation prOp) {
	return prOp.operation == FILTER;
}

public bool isReduce(ProspectiveOperation prOp) {
	return prOp.operation == REDUCE;
}

public bool isAnyMatch(ProspectiveOperation prOp) {
	return prOp.operation == ANY_MATCH;
}

public bool isNoneMatch(ProspectiveOperation prOp) {
	return prOp.operation == NONE_MATCH;
}

public bool isMap(ProspectiveOperation prOp) {
	return prOp.operation == MAP;
}

public bool isForEach(ProspectiveOperation prOp) {
	return prOp.operation == FOR_EACH;
}

public bool isLocalVariableDeclarationStatement(str stmt) {
	try {
		parse(#LocalVariableDeclarationStatement, stmt);
		return true;
	} catch: return false;
}

public bool canOperationsBeRefactored(list[ProspectiveOperation] prOps) {
	return !haveEagerOperationAsNonLast(prOps);
}

private bool haveEagerOperationAsNonLast(list[ProspectiveOperation] prOps) {
	operationsWithoutLast = prefix(prOps);
	for(prOp <- operationsWithoutLast)
		if(isEagerOperation(prOp)) return true;
	
	return false; 
}