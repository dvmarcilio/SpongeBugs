module refactor::forloop::ProspectiveOperation

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import ParseTreeVisualization;
import List;
import util::Math;
import MethodVar;
import String;
import Set;

public data ProspectiveOperation = prospectiveOperation(str stmt, str operation);

str FILTER = "filter";
str MAP = "map";
str FOR_EACH = "forEach";
str REDUCE = "reduce";
str ANY_MATCH = "anyMatch";
str NONE_MATCH = "noneMatch";

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

private list[ProspectiveOperation] retrieveProspectiveOperationsFromBlock(Block block) {
	list[ProspectiveOperation] prOps = [];
	top-down visit(block) {
		case BlockStatement blockStatement: {
			top-down-break visit(blockStatement) {
				case (IfThenStatement) `if ( <Expression exp> ) <Statement thenStmt>`: {
					prOps += prospectiveOperation(unparse(exp), FILTER);
					prOps += retrieveProspectiveOperationsFromStatement(thenStmt);
				}
				case (IfThenElseStatement) `if ( <Expression exp> ) <StatementNoShortIf thenStmt> else <Statement elseStmt>`: {
					//retrieveProspectiveOperationsFromStatement(thenStmt);
					println("if else");
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
	top-down visit (ifStmt) {
		case (IfThenStatement) `if ( <Expression exp> ) <Statement thenStmt>`: {
			visit (thenStmt) {
				case (ReturnStatement) `return <Expression returnExp>;`: {
					if ("<returnExp>" == true)
						prOps += prospectiveOperation(unparse(ifStmt), ANY_MATCH);
					else if ("<returnExp>" == false)
						prOps += prospectiveOperation(unparse(ifStmt), NONE_MATCH);
				}
				case Statement statement: {
					prOps += prospectiveOperation(unparse(exp), FILTER);
					prOps += retrieveProspectiveOperationsFromStatement(statement);
				}
			}
		}
	}
	return prOps;
}

private list[ProspectiveOperation] retrieveProspectiveOperationFromSingleStatement(Statement statement) {
	if (isReducer(statement))
		return [prospectiveOperation(unparse(statement), REDUCE)];
	else
		return [prospectiveOperation(unparse(statement), MAP)];
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
	operation = prOp.operation;
	return operation == FILTER || operation == MAP || operation == FOR_EACH;
}

public bool isFilter(ProspectiveOperation prOp) {
	return prOp.operation == FILTER;
}

// TODO needed and available called more than once. good idea to extract it.
public bool areComposable(ProspectiveOperation first, ProspectiveOperation second, set[MethodVar] methodVars) {
	firstNeededVars = retrieveNeededVariables(first);
	// second's available has to be in first's needed 
	secondAvailableVars = retrieveAvailableVars(second, methodVars);
	secondAvailableVarsInFirstNeeded = isSecondAvailableInFirstNeeded(firstNeededVars, secondAvailableVars);
	return size(firstNeededVars) <= 1 && secondAvailableVarsInFirstNeeded;
}

private bool isSecondAvailableInFirstNeeded(set[str] firstNeededVars, set[str] secondAvailableVars) {
	for(secondAvailable <- secondAvailableVars)
		if(secondAvailable notin firstNeededVars) return false;
	return true;
}

public ProspectiveOperation mergeOps(ProspectiveOperation first, ProspectiveOperation second, set[MethodVar] methodVars) {
	if (isFilter(first)) {
		return mergeTwoOpsInAnIfThenStmt(first, second);
	} else {
		list[str] statements = retrieveAllStatements(first) + retrieveAllStatements(second);
		
		set[str] firstAvailableVars = retrieveAvailableVars(first, methodVars);
		set[str] availableVars = firstAvailableVars;
		availableVars += retrieveAvailableVars(second, methodVars);
		
		set[str] neededVars = retrieveNeededVariables(second);
		neededVars -= firstAvailableVars;
		neededVars += retrieveNeededVariables(first);
		
		neededVars -= retrieveNotDeclaredWithinLoopNames(methodVars);
		
		Block statementsAsOneBlock = transformStatementsInBlock(statements);
		
		return prospectiveOperation(unparse(statementsAsOneBlock), second.operation); 	
	}
}

private ProspectiveOperation mergeTwoOpsInAnIfThenStmt(ProspectiveOperation first, ProspectiveOperation second) {
	Expression exp = parse(#Expression, first.stmt);
	Statement thenStmt = parse(#Statement, second.stmt);
	ifThenStmt = [IfThenStatement] "if (<exp>) <thenStmt>";
	return prospectiveOperation(unparse(ifThenStmt), second.operation);
}

private list[str] retrieveAllStatements(ProspectiveOperation prOp) {
	list[str] allStatements = [];
	if (isBlock(prOp.stmt))
		return retrieveAllStatementsFromBlock(prOp.stmt); 
	 else
		return retrieveAllExpressionStatementsFromStatement(prOp.stmt);
}

private bool isBlock(str stmt) {
	try {
		parse(#Block, stmt);
		return true;
	} catch: return false;
}

private list[str] retrieveAllStatementsFromBlock(str blockStr) {
	list[str] blockStatements = [];
	block = parse(#Block, blockStr);
	top-down visit(block) {
		case BlockStatement blockStmt:
			blockStatements += unparse(blockStmt);
	}
	return blockStatements;	
}

// XXX probably not this
private list[str] retrieveAllExpressionStatementsFromStatement(str statement) {
	list[str] stmts = [];
	Statement stmt = parse(#Statement, statement);
	top-down visit(stmt) {
		case ExpressionStatement expStmt:
			stmts += unparse(expStmt);
	}
	return stmts;
}

private set[str] retrieveAvailableVars(ProspectiveOperation prOp, set[MethodVar] methodVars) {
	// fields declared in class, inherited and visible from imported classes ??
	// variables declared in the Prospective Operation ??
	withinMethod = retrieveNotDeclaredWithinLoopNames(methodVars); 
	withinLoop = retrieveDeclaredWithinLoopNames(methodVars);
	return withinMethod - withinLoop;
}

private set[str] retrieveNeededVariables(ProspectiveOperation prOp) {
	if (prOp.operation == FILTER)
		return {};
	
	set[str] neededVariables = {};
	set[str] declaredVariables = {};
	set[str] methodsNames = {};

	stmt = parse(#Statement, prOp.stmt);
	// If a var has the same name as a called method, this will fail
	visit (stmt) {
		case LocalVariableDeclaration lvdl: {
			visit(lvdl) {
				case (VariableDeclaratorId) `<Identifier id>`: declaredVariables += unparse(id);
			}
		}
		case (MethodInvocation) `<Identifier methodName> ( <ArgumentList? _> )`: methodsNames += unparse(methodName); 
		case Identifier id: neededVariables = {};
	}
	
	neededVariables -= declaredVariables;
	neededVariables -= methodsNames;
	
	return neededVariables;
}

private Block transformStatementsInBlock(list[str] stmts) {
	str joined = "{\n";
	for(stmt <- stmts)
		joined += (stmt + "\n");
	joined +=  "}";
	return parse(#Block, joined);
}