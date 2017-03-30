module refactor::forloop::ForLoopToFunctional

import IO;
import List;
import Set;
import lang::java::\syntax::Java18;
import ParseTree;
import MethodVar;
import refactor::forloop::ProspectiveOperation;
import refactor::forloop::UsedVariables;
import refactor::forloop::AvailableVariables;
import refactor::forloop::OperationType;

public data ComposableProspectiveOperation = composableProspectiveOperation(ProspectiveOperation prOp, set[str] neededVars, set[str] availableVars);

private set[MethodVar] methodAvailableVars;

public list[ComposableProspectiveOperation]  refactorEnhancedToFunctional(set[MethodVar] methodVars, EnhancedForStatement forStmt) {	
	prospectiveOperations = retrieveProspectiveOperations(methodVars, forStmt);
	composablePrOps = createComposableProspectiveOperationsWithVariableAvailability(prospectiveOperations, methodVars);
	
	methodAvailableVars = methodVars;
	
	return mergeIntoComposableOperations(composablePrOps);
}

private list[ComposableProspectiveOperation] createComposableProspectiveOperationsWithVariableAvailability(list[ProspectiveOperation] prOps, set[MethodVar] methodVars) {
	composablePrOps = [];
	for (prOp <- prOps) {
		availableVars = retrieveAvailableVariables(prOp, methodVars);
		neededVars = retrieveNeededVars(prOp, availableVars);
		composablePrOps += composableProspectiveOperation(prOp, neededVars, availableVars);
	}
	
	return composablePrOps;
}

private set[str] retrieveNeededVars(ProspectiveOperation prOp, set[str] availableVars) {
	neededVars = retrieveUsedVariables(prOp);
	neededVars -= availableVars;
	return neededVars;
}

private list[ComposableProspectiveOperation] mergeIntoComposableOperations(list[ComposableProspectiveOperation] composablePrOps) {
		
	// we don't want the curr element (index 0)
	listIndexes = [1 .. size(composablePrOps)];
	// iterating bottom-up
	for (int i <- reverse(listIndexes)) {
		curr = composablePrOps[i];
		prev = composablePrOps[i - 1];
		if (!areComposable(curr, prev)) {
			if (isMergeable(prev) && isMergeable(curr)) {
				opsSize = size(composablePrOps); 
				
				if (isFilter(prev.prOp) || isFilter(curr.prOp)) {
					while(opsSize > i) {
						ComposableProspectiveOperation last = composablePrOps[opsSize - 1];
						ComposableProspectiveOperation beforeLast = composablePrOps[opsSize - 2];
						
						merged = mergeComposablePrOps(beforeLast, last);
						composablePrOps = slice(composablePrOps, 0, opsSize - 2) + merged;
						
						opsSize = size(composablePrOps);
					}
				} else {
					merged = mergeComposablePrOps(prev, curr);
					composablePrOps = slice(composablePrOps, 0, opsSize - 2) + merged;
				}
			}
		}
	}
	return composablePrOps;
}

public bool areComposable(ComposableProspectiveOperation curr, ComposableProspectiveOperation prev) {
	currNeededInPrevAvailable = isCurrNeededVarsInPrevAvailableVars(curr.neededVars, prev.availableVars);
	return size(curr.neededVars) <= 1 && currNeededInPrevAvailable;
}

public bool isMergeable(ComposableProspectiveOperation cPrOp) {
	operation = cPrOp.prOp.operation;
	return operation == FILTER || operation == MAP || operation == FOR_EACH;
}

private bool isCurrNeededVarsInPrevAvailableVars(set[str] currNeededVars, set[str] prevAvailableVars) {
	for(currNeededVar <- currNeededVars)
		if(currNeededVar notin prevAvailableVars) return false;
	return true;
}

public ComposableProspectiveOperation mergeComposablePrOps(ComposableProspectiveOperation curr, ComposableProspectiveOperation prev) {
	if (isFilter(curr.prOp)) {
		prOp = mergeTwoOpsInAnIfThenStmt(curr.prOp, prev.prOp);
		availableVars = retrieveAvailableVariables(prOp, methodAvailableVars);
		neededVars = retrieveNeededVars(prOp, availableVars);
		return composableProspectiveOperation(prOp, neededVars, availableVars);
	} else {
		list[str] statements = retrieveAllStatements(curr.prOp) + retrieveAllStatements(prev.prOp);
		Block statementsAsOneBlock = transformStatementsInBlock(statements);
		prOp = prospectiveOperation(unparse(statementsAsOneBlock), prev.prOp.operation);
		return mergeComposableProspectiveOperation(prOp, curr, prev);	
	}
}

private ProspectiveOperation mergeTwoOpsInAnIfThenStmt(ProspectiveOperation curr, ProspectiveOperation prev) {
	Expression exp = parse(#Expression, curr.stmt);
	Statement thenStmt = parse(#Statement, prev.stmt);
	ifThenStmt = [IfThenStatement] "if (<exp>) <thenStmt>";
	return prospectiveOperation(unparse(ifThenStmt), prev.operation);
}

private ComposableProspectiveOperation mergeComposableProspectiveOperation(ProspectiveOperation prOp, ComposableProspectiveOperation curr, ComposableProspectiveOperation prev) {
	mergedAvailableVars = mergeAvailableVars(curr.availableVars, prev.availableVars);
	mergedNeededVars = mergeNeededVars(curr.neededVars, prev.neededVars, mergedAvailableVars);
	return composableProspectiveOperation(prOp, mergedNeededVars, mergedAvailableVars);
}

private set[str] mergeAvailableVars(set[str] currAvailableVars, prevAvailableVars) {
	return currAvailableVars + prevAvailableVars;
}

private set[str] mergeNeededVars(set[str] currNeededVars, set[str] prevNeededVars, set[str] mergedAvailableVars) {
	neededVars = currNeededVars;
	neededVars -= mergedAvailableVars;
	neededVars += prevNeededVars; 
	return neededVars ;
}

private list[str] retrieveAllStatements(ProspectiveOperation prOp) {
	list[str] allStatements = [];
	if (isBlock(prOp.stmt))
		return retrieveAllStatementsFromBlock(prOp.stmt); 
	else if(isLocalVariableDeclarationStatement(prOp.stmt))
		return [prOp.stmt];
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
		case (IfThenStatement) `if (<Expression exp>) <Statement thenStmt>`:
			stmts += "if (" + unparse(exp) + ")";
	}
	return stmts;
}

private Block transformStatementsInBlock(list[str] stmts) {
	str joined = "{\n";
	for(stmt <- stmts)
		joined += (stmt + "\n");
	joined +=  "}";
	return parse(#Block, joined);
}