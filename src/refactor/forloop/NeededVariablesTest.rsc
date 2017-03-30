module refactor::forloop::NeededVariablesTest

import refactor::forloop::NeededVariables;
import refactor::forloop::ProspectiveOperation;
import refactor::forloop::OperationType;
import MethodVar;
import Set;
import IO;

public test bool methodInvocationWithArg() {
	prOp = prospectiveOperation("writer.write(thing);", FOR_EACH);	
	
	neededVars = retrieveNeededVariables(prOp);
	
	return size(neededVars) == 2 &&
		"writer" in neededVars &&
		"thing" in neededVars;
}

public test bool simpleMethodInvocationWithoutEndingSemiCollon() {
	prOp = prospectiveOperation("rule.hasErrors()", FILTER);
	
	neededVars = retrieveNeededVariables(prOp);
	
	return size(neededVars) == 1 &&
		"rule" in neededVars;
}

public test bool simpleMethodInvocationWithtEndingSemiCollon() {
	prOp = prospectiveOperation("rule.hasErrors()", FILTER);
	
	neededVars = retrieveNeededVariables(prOp);
	
	return size(neededVars) == 1 &&
		"rule" in neededVars;
}

public test bool variableAssignmentWithInitializer() {
	prOp = prospectiveOperation("count = rule.getErrors().size();", MAP);
	
	neededVars = retrieveNeededVariables(prOp);
	
	return size(neededVars) == 2 &&
		"count" in neededVars &&
		"rule" in neededVars;
}

public test bool localVariableDeclarationShouldReturnItselfWithInitializer() {
	prOp = prospectiveOperation("ClassLoader cl = entry.getKey(argNeeded);", MAP);
	
	neededVars = retrieveNeededVariables(prOp);
	
	return size(neededVars) == 3 &&
		"cl" in neededVars &&
		"entry" in neededVars && 
		"argNeeded" in neededVars;
}

public test bool expressionIsNotAStatement() {
	prOp = prospectiveOperation("!((WebappClassLoader)cl).isStart()", FILTER);
	
	neededVars = retrieveNeededVariables(prOp);
	
	return size(neededVars) == 1 &&
		"cl" in neededVars;
}

public test bool reduceShouldReturnEmpty() {
	prOp = prospectiveOperation("count += rule.getErrors().size();", REDUCE);
	
	neededVars = retrieveNeededVariables(prOp);
	
	return size(neededVars) == 0;
}