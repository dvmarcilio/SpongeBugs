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

public data ComposibleProspectiveOperation = composibleProspectiveOperation(ProspectiveOperation prOp, set[str] neededVars, set[str] availableVars);

public list[ComposibleProspectiveOperation]  refactorEnhancedToFunctional(set[MethodVar] methodVars, EnhancedForStatement forStmt) {	
	prospectiveOperations = retrieveProspectiveOperations(methodVars, forStmt);
	composiblePrOps = createComposibleProspectiveOperationsWithVariableAvailability(prospectiveOperations, methodVars);
	
	return mergeIntoComposableOperations(composiblePrOps);
}

private list[ComposibleProspectiveOperation] createComposibleProspectiveOperationsWithVariableAvailability(list[ProspectiveOperation] prOps, set[MethodVar] methodVars) {
	composiblePrOps = [];
	for (prOp <- prOps) {
		availableVars = retrieveAvailableVariables(prOp, methodVars);
		neededVars = retrieveUsedVariables(prOp);
		neededVars -= availableVars;
		
		composiblePrOps += composibleProspectiveOperation(prOp, neededVars, availableVars);
	}
	
	return composiblePrOps;
}

private list[ComposibleProspectiveOperation] mergeIntoComposableOperations(list[ComposibleProspectiveOperation] composiblePrOps) {
		
	// we don't want the curr element (index 0)
	listIndexes = [1 .. size(composiblePrOps)];
	// iterating bottom-up
	for (int i <- reverse(listIndexes)) {
		curr = composiblePrOps[i];
		prev = composiblePrOps[i - 1];
		if (!areComposable(curr, prev)) {
			if (isMergeable(prev) && isMergeable(curr)) {
				opsSize = size(composiblePrOps); 
				
				if (isFilter(prev.prOp) || isFilter(curr.prOp)) {
					while(opsSize > i) {
						ComposibleProspectiveOperation last = composiblePrOps[opsSize - 1];
						ComposibleProspectiveOperation beforeLast = composiblePrOps[opsSize - 2];
						
						merged = mergeComposiblePrOps(beforeLast, last);
						composiblePrOps = slice(composiblePrOps, 0, opsSize - 2) + merged;
						
						opsSize = size(composiblePrOps);
					}
				} else {
					merged = mergeComposiblePrOps(prev, curr);
					composiblePrOps = slice(composiblePrOps, 0, opsSize - 2) + merged;
				}
			}
		}
	}
	return composiblePrOps;
}

public bool areComposable(ComposibleProspectiveOperation curr, ComposibleProspectiveOperation prev) {
	currNeededInPrevAvailable = isCurrNeededVarsInPrevAvailableVars(curr.neededVars, prev.availableVars);
	return size(curr.neededVars) <= 1 && currNeededInPrevAvailable;
}

public bool isMergeable(ComposibleProspectiveOperation cPrOp) {
	operation = cPrOp.prOp.operation;
	return operation == FILTER || operation == MAP || operation == FOR_EACH;
}

private bool isCurrNeededVarsInPrevAvailableVars(set[str] currNeededVars, set[str] prevAvailableVars) {
	for(currNeededVar <- currNeededVars)
		if(currNeededVar notin prevAvailableVars) return false;
	return true;
}

public ComposibleProspectiveOperation mergeComposiblePrOps(ComposibleProspectiveOperation curr, ComposibleProspectiveOperation prev) {
	if (isFilter(curr.prOp)) {
		prOp = mergeTwoOpsInAnIfThenStmt(curr.prOp, prev.prOp);
		return mergeComposibleProspectiveOperation(prOp, curr, prev);
	} else {
		list[str] statements = retrieveAllStatements(curr.prOp) + retrieveAllStatements(prev.prOp);
		Block statementsAsOneBlock = transformStatementsInBlock(statements);
		prOp = prospectiveOperation(unparse(statementsAsOneBlock), prev.prOp.operation);
		return mergeComposibleProspectiveOperation(prOp, curr, prev);	
	}
}

private ProspectiveOperation mergeTwoOpsInAnIfThenStmt(ProspectiveOperation curr, ProspectiveOperation prev) {
	Expression exp = parse(#Expression, curr.stmt);
	Statement thenStmt = parse(#Statement, prev.stmt);
	ifThenStmt = [IfThenStatement] "if (<exp>) <thenStmt>";
	return prospectiveOperation(unparse(ifThenStmt), prev.operation);
}

private ComposibleProspectiveOperation mergeComposibleProspectiveOperation(ProspectiveOperation prOp, ComposibleProspectiveOperation curr, ComposibleProspectiveOperation prev) {
	mergedAvailableVars = mergeAvailableVars(curr.availableVars, prev.availableVars);
	mergedNeededVars = mergeNeededVars(curr.neededVars, prev.neededVars, mergedAvailableVars);
	return composibleProspectiveOperation(prOp, mergedNeededVars, mergedAvailableVars);
}

private set[str] mergeAvailableVars(set[str] currAvailableVars, prevAvailableVars) {
	return currAvailableVars + prevAvailableVars;
}

private set[str] mergeNeededVars(set[str] currNeededVars, set[str] prevNeededVars, set[str] mergedAvailableVars) {
	neededVars = currNeededVars + prevNeededVars;
	return neededVars - mergedAvailableVars;
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