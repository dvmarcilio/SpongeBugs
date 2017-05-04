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
import refactor::forloop::ForLoopBodyReferences;

public data ComposableProspectiveOperation = composableProspectiveOperation(ProspectiveOperation prOp, set[str] neededVars, set[str] availableVars);

public MethodBody refactorEnhancedToFunctional(set[MethodVar] methodVars, EnhancedForStatement forStmt, MethodBody methodBody, VariableDeclaratorId iteratedVarName, Expression collectionId) {	
	return buildRefactoredMethodBody(methodVars, forStmt, methodBody, iteratedVarName, collectionId);
}

private MethodBody buildRefactoredMethodBody(set[MethodVar] methodVars, EnhancedForStatement forStmt, MethodBody methodBody, VariableDeclaratorId iteratedVarName, Expression collectionId) {
	refactored = buildRefactoredEnhancedFor(methodVars, forStmt, methodBody, iteratedVarName, collectionId);
	forStatement = parse(#Statement, unparse(forStmt));
	refactoredMethodBody = refactorToFunctional(methodBody, forStatement, refactored);	
	return refactoredMethodBody;
}

public Statement buildRefactoredEnhancedFor(set[MethodVar] methodVars, EnhancedForStatement forStmt, MethodBody methodBody, VariableDeclaratorId iteratedVarName, Expression collectionId) {
	composablePrOps = retrieveComposableProspectiveOperations(methodVars, forStmt);
	return buildFunctionalStatement(methodVars, composablePrOps, forStmt, iteratedVarName, collectionId);
}

MethodBody refactorToFunctional(MethodBody methodBody, Statement forStmt, Statement refactored) = top-down-break visit(methodBody) {
	case forStmt
	=> refactored
};

public list[ComposableProspectiveOperation] retrieveComposableProspectiveOperations(set[MethodVar] methodVars, EnhancedForStatement forStmt) {
	prospectiveOperations = retrieveProspectiveOperations(methodVars, forStmt);
	nonEffectiveOutsideVarsReferencedCount = getTotalOfNonEffectiveFinalVarsReferenced(methodVars, forStmt);
	if (canOperationsBeRefactored(prospectiveOperations, nonEffectiveOutsideVarsReferencedCount)) {
		composablePrOps = createComposableProspectiveOperationsWithVariableAvailability(prospectiveOperations, methodVars);
		
		composablePrOps = mergeIntoComposableOperations(composablePrOps);
		
		return rearrangeMapBodiesIfNeeded(composablePrOps);
	} else 
		// Throwing the exception is not the best option, but the easiest to implement right now
		throw "CanNotBeRefactored";
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
			if(neitherCanBeMerged(prev, curr))
				throw "CanNotBeRefactored. Both operations are not mergeable";
			
			opsSize = size(composablePrOps); 
			
			if (isFilter(prev.prOp) || isFilter(curr.prOp)) {
				while(opsSize > i) {
					ComposableProspectiveOperation last = composablePrOps[opsSize - 1];
					ComposableProspectiveOperation beforeLast = composablePrOps[opsSize - 2];
					
					merged = mergeComposablePrOps(beforeLast, last);
					// XXX analyze if this "merging" is correct. probably not
					composablePrOps = slice(composablePrOps, 0, opsSize - 2) + merged;
					
					opsSize = size(composablePrOps);
				}
			} else {
				merged = mergeComposablePrOps(prev, curr);
				composablePrOps = composablePrOps[0..(i - 1)] + merged + composablePrOps[(i + 1)..];
			}
			
		}
	}
	return composablePrOps;
}

private bool canBeChained(ComposableProspectiveOperation prev, ComposableProspectiveOperation curr) {
	return size(curr.neededVars) <= 1 && isCurrNeededVarsInPrevAvailabilitySet(curr.neededVars, prev);
}

private bool isCurrNeededVarsInPrevAvailabilitySet(set[str] currNeededVars, ComposableProspectiveOperation prev) {
	prevAvailabilitySet = prev.availableVars + prev.neededVars;
	for(currNeededVar <- currNeededVars)
		if(currNeededVar notin prevAvailabilitySet) return false;
	return true;
}

private bool neitherCanBeMerged(ComposableProspectiveOperation prev, ComposableProspectiveOperation curr) {
	return !isMergeable(prev.prOp) || !isMergeable(curr.prOp);
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

private list[ComposableProspectiveOperation] rearrangeMapBodiesIfNeeded(list[ComposableProspectiveOperation] composablePrOps) {
	listIndexes = [1 .. size(composablePrOps)];
	for (int i <- reverse(listIndexes)) {
		curr = composablePrOps[i - 1];
		next = composablePrOps[i];
		if (isMap(curr.prOp))
			// Modifying in place
			composablePrOps[i - 1] = rearrangeMapBody(curr, next.neededVars);
	}
	
	return composablePrOps;
}

private ComposableProspectiveOperation rearrangeMapBody(ComposableProspectiveOperation curr, set[str] nextNeededVars) {
		prOp = curr.prOp;
		if(isLocalVariableDeclarationStatement(prOp.stmt))
			return rearrangeLocalVariableDeclarationMapBody(curr, nextNeededVars);
		else if(isNumericLiteral(prOp.stmt))
			return curr;
		else
			return addReturnToMapBody(curr, nextNeededVars);
}

private ComposableProspectiveOperation rearrangeLocalVariableDeclarationMapBody(ComposableProspectiveOperation curr, set[str] nextNeededVars) {
	lvdl = parse(#LocalVariableDeclarationStatement, curr.prOp.stmt);
	varName = "";
	visit(lvdl) {
		case VariableDeclaratorId varId: varName = trim(unparse(varId));
	}
	
	if (varName notin nextNeededVars)
		return addReturnToMapBody(curr, nextNeededVars);
		 
	return curr;
}

private bool isNumericLiteral(str stmt) {
	// FIXME
	return false;
}

private ComposableProspectiveOperation addReturnToMapBody(ComposableProspectiveOperation curr, set[str] nextNeededVars) {
	list[str] stmts = [];
	if (isBlock(curr.prOp.stmt)) 
		stmts += retrieveAllStatementsFromBlock(curr.prOp.stmt);
	else
		stmts += curr.prOp.stmt;
		
	varName = isEmpty(nextNeededVars) ? "_item" : getOneFrom(nextNeededVars);
	stmts += "return <varName>;";
	block = transformStatementsInBlock(stmts);
	
	curr.prOp.stmt = unparse(block);
	return curr;
}

private Statement buildFunctionalStatement(set[MethodVar] methodVars, list[ComposableProspectiveOperation] composablePrOps, EnhancedForStatement forStmt, VariableDeclaratorId iteratedVarName, Expression collectionId) {
	if(size(composablePrOps) == 1 && isForEach(composablePrOps[0].prOp))
		return buildStatementForOnlyOneForEach(composablePrOps[0].prOp, iteratedVarName, collectionId);                   
	
	return chainOperationsIntoStatement(methodVars, composablePrOps, collectionId);
}

private Statement buildStatementForOnlyOneForEach(ProspectiveOperation prOp, VariableDeclaratorId iteratedVarName, Expression collectionId) {
	stmtBlock = transformIntoBlock(prOp.stmt);
	iteratedVarName = trimEndingBlankSpace(iteratedVarName);
	return parse(#Statement, "<collectionId>.forEach(<iteratedVarName> -\> <stmtBlock>);");
}

private Block transformIntoBlock(str stmt) {
	if(isBlock(stmt)) return parse(#Block, stmt);
	return parse(#Block, "{\n<stmt>\n}");
}

private VariableDeclaratorId trimEndingBlankSpace(VariableDeclaratorId varId) {
	return parse(#VariableDeclaratorId, trim(unparse(varId)));
}

private Statement chainOperationsIntoStatement(set[MethodVar] methodVars, list[ComposableProspectiveOperation] composablePrOps, Expression collectionId) {
	str chainStr = "<collectionId>.stream()";
	
	for(composablePrOp <- composablePrOps) {
		chainStr = "<chainStr>." + buildChainableOperation(methodVars, composablePrOp);
	}
	
	return parse(#Statement, "<chainStr>;");
}

private str buildChainableOperation(set[MethodVar] methodVars, ComposableProspectiveOperation cPrOp) {
	prOp = cPrOp.prOp;
	if(isReduce(prOp))
		return buildMapReduceOperation(methodVars, cPrOp);
	
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
	else // isForEach(prOp)
		return unparse(transformIntoBlock(prOp.stmt));
}

private str getLambdaBodyForMap(str stmt) {
	if(isExpressionStatement(stmt))
		return getLambdaBodyForMapWhenExpressionStatement(stmt);
	else
		return getLambdaBodyForMapWhenLocalVariableDeclaration(stmt);
}

private bool isExpressionStatement(str stmt) {
	try {
		parse(#ExpressionStatement, stmt);
		return true;
	} catch:
		return false;
}

private str getLambdaBodyForMapWhenExpressionStatement(str stmt) {
	return removeEndingSemiCollonIfPresent(stmt);
}

private str removeEndingSemiCollonIfPresent(str stmt) {
	if(endsWith(stmt, ";"))
		stmt = substring(stmt, 0, size(stmt)-1);
	return stmt;
}

private str getLambdaBodyForMapWhenLocalVariableDeclaration(str stmt) {
	stmt = removeEndingSemiCollonIfPresent(stmt);
	
	lvdl = parse(#LocalVariableDeclaration, stmt);
	visit(lvdl) {
		case VariableInitializer vi: return unparse(vi);
	}
	throw "No variable initializer in MAP";
}

// TODO check for prefix and postfix increment/decrement after ProspectiveOperation is working 
private str buildMapReduceOperation(set[MethodVar] methodVars, ComposableProspectiveOperation cPrOp) {
	mapOperation = "";
	reduceOperation = "";
	stmt = parse(#Statement, cPrOp.prOp.stmt);
	bottom-up-break visit(stmt) {
		case (Assignment) `<LeftHandSide lhs> <AssignmentOperator op> <Expression exp>`: {
			reducingVar = unparse(lhs);
			
			lambdaParamName = retrieveLambdaParameterName(cPrOp);
			mapOperation = "map(<lambdaParamName> -\> <exp>)";
			
			reduceOperation += buildReduceOperation(methodVars, op, reducingVar);			
		}
	}
	
	
	
	return "<mapOperation>.<reduceOperation>";
}

private str buildReduceOperation(set[MethodVar] methodVars, AssignmentOperator op, str reducingVar) {
	reduceOperation = "";
	if("<op>" == "+=")
		reduceOperation = buildPlusAssignmentReduce(methodVars, reducingVar);						
	else
		reduceOperation = buildSimpleExplicitReduce("<op>", reducingVar);

	return reduceOperation;
}

private str buildPlusAssignmentReduce(set[MethodVar] methodVars, str reducingVar) {
	if(isString(methodVars, reducingVar))
		return "reduce(<reducingVar>, String::concat)";
	else 
		if(isInteger(methodVars, reducingVar))
			return "reduce(<reducingVar>, Integer::sum)";
		else
			return buildSimpleExplicitReduce("+=", reducingVar);
}

private bool isString(set[MethodVar] methodVars, str varName) {
	var = findByName(methodVars, varName);
	return isString(var);
}

private bool isInteger(set[MethodVar] methodVars, str varName) {
	var = findByName(methodVars, varName);
	return isInteger(var);
}

private str buildSimpleExplicitReduce(str op, str reducingVar) {
	return "reduce(<reducingVar>, (accumulator, _item) -\> accumulator <op> _item)"; 
}