module refactor::forloop::ForLoopToFunctional

import IO;
import List;
import Set;
import lang::java::\syntax::Java18;
import ParseTree;
import MethodVar;
import refactor::forloop::ProspectiveOperation;
import refactor::forloop::NeededVariables;
import refactor::forloop::AvailableVariables;



public void refactorEnhancedToFunctional(set[MethodVar] methodVars, EnhancedForStatement forStmt) {
	prospectiveOperations = retrieveProspectiveOperations(methodVars, forStmt);
	println(mergeOperations(prospectiveOperations, methodVars));
}

private list[ProspectiveOperation] mergeOperations(list[ProspectiveOperation] prOps, set[MethodVar] methodVars) {	
	// we don't want the first element (index 0)
	listIndexes = [1 .. size(prOps)];
	// iterating bottom-up
	for (int i <- reverse(listIndexes)) {
		curr = prOps[i];
		prev = prOps[i - 1];
		if (!areComposable(curr, prev, methodVars)) {
			if (isMergeable(prev) && isMergeable(curr)) {
				opsSize = size(prOps); 
				
				if (isFilter(prev) || isFilter(curr)) {
					while(opsSize > i) {
						ProspectiveOperation last = prOps[opsSize - 1];
						ProspectiveOperation beforeLast = prOps[opsSize - 2];
						merged = mergeOps(beforeLast, last, methodVars);
						prOps = slice(prOps, 0, opsSize - 2) + merged;
						
						opsSize = size(prOps);
					}
				} else {
					merged = mergeOps(prev, curr, methodVars);
					prOps = slice(prOps, 0, opsSize - 2) + merged;
				}
			}
		}
	}
	return prOps;
}

// TODO needed and available called more than once. good idea to extract it.
public bool areComposable(ProspectiveOperation first, ProspectiveOperation second, set[MethodVar] methodVars) {
	firstNeededVars = retrieveNeededVariables(first);
	// firsts' needed has to be available from second
	secondAvailableVars = retrieveAvailableVars(second, methodVars);
	firstNeededInSecondAvailable = isFirstNeededVarsInSecondAvailableVars(firstNeededVars, secondAvailableVars);
	return size(firstNeededVars) <= 1 && firstNeededInSecondAvailable;
}

private bool isFirstNeededVarsInSecondAvailableVars(set[str] firstNeededVars, set[str] secondAvailableVars) {
	for(firstNeededVar <- firstNeededVars)
		if(firstNeededVar notin secondAvailableVars) return false;
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