module refactor::forloop::ForLoopToFunctional

import IO;
import List;
import Set;
import String;
import lang::java::\syntax::Java18;
import ParseTree;
import MethodVar;
import refactor::forloop::ProspectiveOperation;
import refactor::forloop::UsedVariables;
import refactor::forloop::AvailableVariables;
import refactor::forloop::OperationType;

public data ComposableProspectiveOperation = composableProspectiveOperation(ProspectiveOperation prOp, set[str] neededVars, set[str] availableVars);

public MethodBody refactorEnhancedToFunctional(set[MethodVar] methodVars, EnhancedForStatement forStmt, MethodBody methodBody, VariableDeclaratorId iteratedVarName, Expression collectionId) {	
	composablePrOps = retrieveComposableProspectiveOperations(methodVars, forStmt);
	
	Statement refactored = buildFunctionalStatement(composablePrOps, forStmt, iteratedVarName, collectionId);
	forStatement = parse(#Statement, unparse(forStmt));
	refactoredMethodBody = refactorToFunctional(methodBody, forStatement, refactored);
	
	//println("\n --- APPLYING REFACTOR ---");
	//println(forStmt);
	//println("refactored to:");
	//println(refactored);
	
	return refactoredMethodBody;
}

MethodBody refactorToFunctional(MethodBody methodBody, Statement forStmt, Statement refactored) = top-down-break visit(methodBody) {
	case forStmt
	=> refactored
};

public list[ComposableProspectiveOperation] retrieveComposableProspectiveOperations(set[MethodVar] methodVars, EnhancedForStatement forStmt) {
	prospectiveOperations = retrieveProspectiveOperations(methodVars, forStmt);
	composablePrOps = createComposableProspectiveOperationsWithVariableAvailability(prospectiveOperations, methodVars);
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
	// exclude first, since we iterate index and index-1
	listIndexes = [1 .. size(composablePrOps)];
	// iterating bottom-up
	for (int i <- reverse(listIndexes)) {
		curr = composablePrOps[i];
		prev = composablePrOps[i - 1];
		if (!canBeChained(prev, curr)) {
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

private bool canBeChained(ComposableProspectiveOperation prev, ComposableProspectiveOperation curr) {
	currNeededVarsInPrevAvailabilitySet = isCurrNeededVarsInPrevAvailabilitySet(curr.neededVars, prev);
	return size(curr.neededVars) <= 1 && currNeededVarsInPrevAvailabilitySet;
}

private bool isMergeable(ComposableProspectiveOperation cPrOp) {
	operation = cPrOp.prOp.operation;
	return operation == FILTER || operation == MAP || operation == FOR_EACH;
}

private bool isCurrNeededVarsInPrevAvailabilitySet(set[str] currNeededVars, ComposableProspectiveOperation prev) {
	prevAvailabilitySet = prev.availableVars + prev.neededVars;
	for(currNeededVar <- currNeededVars)
		if(currNeededVar notin prevAvailabilitySet) return false;
	return true;
}

private ComposableProspectiveOperation mergeComposablePrOps(ComposableProspectiveOperation prev, ComposableProspectiveOperation curr) {
	if (isFilter(prev.prOp))
		return mergeIntoAnIfThenStmt(prev, curr);		
	else 
		return mergeIntoABlock(prev, curr);
}

private ComposableProspectiveOperation mergeIntoAnIfThenStmt(ComposableProspectiveOperation prev, ComposableProspectiveOperation curr) {
	prOp = mergeTwoOpsInAnIfThenStmt(prev.prOp, curr.prOp);
	return mergeComposableProspectiveOperations(prOp, prev, curr);
}

private ProspectiveOperation mergeTwoOpsInAnIfThenStmt(ProspectiveOperation prev, ProspectiveOperation curr) {
	Expression exp = parse(#Expression, prev.stmt);
	Statement thenStmt = parse(#Statement, curr.stmt);
	ifThenStmt = [IfThenStatement] "if (<exp>) <thenStmt>";
	return prospectiveOperation(unparse(ifThenStmt), curr.operation);
}

private ComposableProspectiveOperation mergeComposableProspectiveOperations(ProspectiveOperation prOp, ComposableProspectiveOperation prev, ComposableProspectiveOperation curr) {
	mergedAvailableVars = mergeAvailableVars(curr.availableVars, prev.availableVars);
	mergedNeededVars = mergeNeededVars(curr.neededVars, prev.neededVars, mergedAvailableVars);
	return composableProspectiveOperation(prOp, mergedNeededVars, mergedAvailableVars);
}

private set[str] mergeAvailableVars(set[str] currAvailableVars, prevAvailableVars) {
	return currAvailableVars + prevAvailableVars;
}

private set[str] mergeNeededVars(set[str] currNeededVars, set[str] prevNeededVars, set[str] mergedAvailableVars) {
	neededVars = currNeededVars + prevNeededVars;
	return neededVars - mergedAvailableVars;
}

private ComposableProspectiveOperation mergeIntoABlock(ComposableProspectiveOperation prev, ComposableProspectiveOperation curr) {
	list[str] statements = retrieveAllStatements(prev.prOp) + retrieveAllStatements(curr.prOp);
	Block statementsAsOneBlock = transformStatementsInBlock(statements);
	prOp = prospectiveOperation(unparse(statementsAsOneBlock), curr.prOp.operation);
	return mergeComposableProspectiveOperations(prOp, prev, curr);
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

private list[str] retrieveAllExpressionStatementsFromStatement(str statement) {
	list[str] stmts = [];
	Statement stmt = parse(#Statement, statement);
	top-down visit(stmt) {
		case ExpressionStatement expStmt:
			stmts += unparse(expStmt);
		case (IfThenStatement) `if (<Expression exp>) <Statement thenStmt>`:
			stmts += "if (<exp>)";
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

private Statement buildFunctionalStatement(list[ComposableProspectiveOperation] composablePrOps, EnhancedForStatement forStmt, VariableDeclaratorId iteratedVarName, Expression collectionId) {
	if(size(composablePrOps) == 1 && isForEach(composablePrOps[0].prOp))
		return buildStatementForOnlyOneForEach(composablePrOps[0].prOp, iteratedVarName, collectionId);                   
	
	println();
	println(forStmt);
	println("\nrefactored to:");
	return chainOperationsIntoStatement(composablePrOps, collectionId);
}

private Statement buildStatementForOnlyOneForEach(ProspectiveOperation prOp, VariableDeclaratorId iteratedVarName, Expression collectionId) {
	stmtBlock = transformIntoBlock(prOp.stmt);
	iteratedVarName = trimEndingBlankSpace(iteratedVarName);
	return parse(#Statement, "<collectionId>.forEach((<iteratedVarName>) -\> <stmtBlock>);");
}

private Block transformIntoBlock(str stmt) {
	if(isBlock(stmt)) return parse(#Block, stmt);
	return parse(#Block, "{\n<stmt>\n}");
}

private VariableDeclaratorId trimEndingBlankSpace(VariableDeclaratorId varId) {
	return parse(#VariableDeclaratorId, trim(unparse(varId)));
}

private Statement chainOperationsIntoStatement(list[ComposableProspectiveOperation] composablePrOps, Expression collectionId) {
	str chainStr = "<collectionId>.stream()";
	
	for(composablePrOp <- composablePrOps) {
		chainStr = "<chainStr>." + buildChainableOperation(composablePrOp);
	}
	
	println(chainStr);
	return parse(#Statement, "<chainStr>;");
}

private str buildChainableOperation(ComposableProspectiveOperation cPrOp) {
	prOp = cPrOp.prOp;
	return prOp.operation + "(" + retrieveLambdaParameterName(cPrOp) + " -\> " +
		retrieveLambdaBody(prOp) + ")";
}

private str retrieveLambdaParameterName(ComposableProspectiveOperation cPrOp) {
	return isEmpty(cPrOp.neededVars) ? "_item" : getOneFrom(cPrOp.neededVars);
}

private str retrieveLambdaBody(ProspectiveOperation prOp) {
	if(isFilter(prOp) || isAnyMatch(prOp) || isNoneMatch(prOp) || isBlock(prOp.stmt))
		return prOp.stmt;
	else if(isMap(prOp)) {
		return getLambdaBodyForMap(prOp.stmt);	
	}
	else if(isReduce(prOp))
		return getLambdaBodyForReduce(prOp.stmt);
	else // isForEach(prOp)
		return unparse(transformIntoBlock(prOp.stmt));
}

private str getLambdaBodyForMap(str stmt) {
	// XXX Are other kind of statements maps?
	lvdl = parse(#LocalVariableDeclaration, stmt);
	visit(lvdl) {
		case VariableInitializer vi: return unparse(vi);
	}
	throw "No variable initializer in MAP";
}

private str getLambdaBodyForReduce(str stmt) {
	return "REDUCE_NOT_IMPLEMENTED_YET;";
}