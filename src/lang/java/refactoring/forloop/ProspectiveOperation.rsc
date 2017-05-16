module lang::java::refactoring::forloop::ProspectiveOperation

import IO;
import List;
import String;
import lang::java::\syntax::Java18;
import ParseTree;
import ParseTreeVisualization;
import lang::java::refactoring::forloop::MethodVar;
import lang::java::refactoring::forloop::OperationType;
import lang::java::refactoring::forloop::BreakIntoStatements;

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
			stmtsBrokenInto = breakIntoStatements(stmt);
			prOps += retrieveProspectiveOperationsFromIfThenStatement(ifStmt, stmtsBrokenInto);
		}
		case ExpressionStatement expStmt: {
			statement = parse(#Statement, unparse(expStmt));
			prOps += retrieveProspectiveOperationFromSingleStatement(statement);
		}
		
		case IfThenElseStatement ifElseStmt: throw "Not Refactoring If/Else for now";
		case ForStatement _: throw "Not Refactoring Inner Loops for now";
		case WhileStatement _: throw "Not Refactoring While Loops inside ForStatement for now";
	}
	return prOps;
}

private list[ProspectiveOperation] retrieveProspectiveOperationsFromBlock(Block block) {
	list[ProspectiveOperation] prOps = [];
	top-down-break visit(block) {
		case BlockStatement blockStatement: {
			top-down-break visit(blockStatement) {
				case (IfThenStatement) `if ( <Expression exp> ) <Statement thenStmt>`: {
					ifThenStmt = [IfThenStatement] "if (<exp>) <thenStmt>";
					stmtsBrokenInto = breakIntoStatements(block);
					prOps += retrieveProspectiveOperationsFromIfThenStatement(ifThenStmt, stmtsBrokenInto);
				}
				case (IfThenElseStatement) `if ( <Expression exp> ) <StatementNoShortIf thenStmt> else <Statement elseStmt>`: {
					throw "Not Refactoring If/Else for now";
				}
				case LocalVariableDeclarationStatement lvdlStmt: {
					// not an if, so it's a map
					prOps += prospectiveOperation(unparse(lvdlStmt), MAP);
				} 
				case StatementWithoutTrailingSubstatement otherStmt: {
					statement = parse(#Statement, unparse(otherStmt));
					prOps += retrieveProspectiveOperationFromSingleStatement(statement);
				}
				
				case IfThenElseStatement ifElseStmt: throw "Not Refactoring If/Else for now";
				case ForStatement _: throw "Not Refactoring Inner Loops for now";
				case WhileStatement _: throw "Not Refactoring While Loops inside ForStatement for now";
			}
		}
	}
	return prOps;
}

private list[ProspectiveOperation] retrieveProspectiveOperationsFromIfThenStatement(IfThenStatement ifStmt, list[Stmt] currBlockStmts) {
	list[ProspectiveOperation] prOps = [];
	foundReturn = false;
	top-down-break visit (ifStmt) {
		case (IfThenStatement) `if ( <Expression ifExp> ) <Statement thenStmt>`: {
			top-down-break visit (thenStmt) {
				case Statement stmt: {
					visit(stmt) {
						case (ReturnStatement) `return <Expression returnExp>;`: {
							foundReturn = true;
							prOps += createAnyMatchOrNoneMatchPrOp("<returnExp>", "<ifExp>");
						}
					}
						
					if (!foundReturn) {
						if (!ifStatementHasNoStatementAfter(ifStmt, currBlockStmts))
							prOps += prospectiveOperation(unparse(ifStmt), MAP);
						else {					
							prOps += prospectiveOperation(unparse(ifExp), FILTER);
							prOps += retrieveProspectiveOperationsFromThenStatement(thenStmt);
						}
					}
				}
			}
		}
	}
	return prOps;
}

private ProspectiveOperation createAnyMatchOrNoneMatchPrOp(str returnExp, str ifExp) {
	if (returnExp == "true")
		return prospectiveOperation(ifExp, ANY_MATCH);
	else // (returnExp == "false")
		return prospectiveOperation(ifExp, NONE_MATCH);
}

private bool ifStatementHasNoStatementAfter(IfThenStatement ifStmt, list[Stmt] currBlockStmts) {
	lastStmt = last(currBlockStmts);
	return lastStmt.stmtType == "IfThenStatement" && lastStmt.statement == ifStmt;
}

private list[ProspectiveOperation] retrieveProspectiveOperationsFromThenStatement(Statement thenStmt) {
	if (isSingleStatementBlock(thenStmt))
		return [retrieveProspectiveOperationFromSingleStatement(thenStmt)];
	else
		return retrieveProspectiveOperationsFromStatement(thenStmt);
}

// XXX Does this really work?
private bool isSingleStatementBlock(Statement thenStmt) {
	if (isBlock("<thenStmt>")) {
		semiCollonOccurrences = findAll("<thenStmt>", ";");
		return size(semiCollonOccurrences) == 1;
	}
	
	return false;
}

private ProspectiveOperation retrieveProspectiveOperationFromSingleStatement(Statement statement) {
	if (isReducer(statement))
		return prospectiveOperation(unparse(statement), REDUCE);
	else
		return prospectiveOperation(unparse(statement), MAP);
}

// TODO implement prefix and postfix increment/decrement
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

public bool canOperationsBeRefactored(list[ProspectiveOperation] prOps, int nonEffectiveOutsideVarsReferencedCount) {
	return !haveEagerOperationAsNonLast(prOps) 
		&& isLoopAReducerIfHasMoreThanOneReferenceToOutsideNonEffectiveFinalVar(prOps, nonEffectiveOutsideVarsReferencedCount);
}

private bool haveEagerOperationAsNonLast(list[ProspectiveOperation] prOps) {
	operationsWithoutLast = prefix(prOps);
	for(prOp <- operationsWithoutLast)
		if(isEagerOperation(prOp)) return true;
	
	return false; 
}

private bool isLoopAReducerIfHasMoreThanOneReferenceToOutsideNonEffectiveFinalVar(list[ProspectiveOperation] prOps, int outsideNonEffectiveReferencesCount) {
	if (outsideNonEffectiveReferencesCount == 1)
		return isReduce(last(prOps));
	return true;
}