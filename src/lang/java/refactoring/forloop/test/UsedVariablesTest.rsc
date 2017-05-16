module lang::java::refactoring::forloop::\test::UsedVariablesTest

import Set;
import IO;
import lang::java::refactoring::forloop::UsedVariables;
import lang::java::refactoring::forloop::ProspectiveOperation;
import lang::java::refactoring::forloop::OperationType;
import lang::java::refactoring::forloop::MethodVar;

public test bool methodInvocationWithArg() {
	prOp = prospectiveOperation("writer.write(thing);", FOR_EACH);	
	
	usedVars = retrieveUsedVariables(prOp);
	
	return size(usedVars) == 2 &&
		"writer" in usedVars &&
		"thing" in usedVars;
}

public test bool simpleMethodInvocationWithoutEndingSemiCollon() {
	prOp = prospectiveOperation("rule.hasErrors()", FILTER);
	
	usedVars = retrieveUsedVariables(prOp);
	
	return size(usedVars) == 1 &&
		"rule" in usedVars;
}

public test bool variableAssignmentWithInitializer() {
	prOp = prospectiveOperation("count = rule.getErrors().size();", MAP);
	
	usedVars = retrieveUsedVariables(prOp);
	
	return size(usedVars) == 2 &&
		"count" in usedVars &&
		"rule" in usedVars;
}

public test bool localVariableDeclarationShouldNotReturnItself() {
	prOp = prospectiveOperation("ClassLoader cl = entry.getKey(argUsed);", MAP);
	
	usedVars = retrieveUsedVariables(prOp);
	
	return "cl" notin usedVars;
}

public test bool localVariableDeclarationShouldReturnVarsUsedInInitializer() {
	prOp = prospectiveOperation("ClassLoader cl = entry.getKey(argUsed);", MAP);
	
	usedVars = retrieveUsedVariables(prOp);
	
	return size(usedVars) == 2 &&
		"entry" in usedVars &&
		"argUsed" in usedVars;
}

public test bool expressionIsNotAStatement() {
	prOp = prospectiveOperation("!((WebappClassLoader)cl).isStart()", FILTER);
	
	usedVars = retrieveUsedVariables(prOp);
	
	return size(usedVars) == 1 &&
		"cl" in usedVars;
}

public test bool ifThenStatement() {
	prOp = prospectiveOperation("if (!((WebappClassLoader)cl).isStart()) result.add(entry.getValue());", FILTER);
	
	usedVars = retrieveUsedVariables(prOp);
	
	return size(usedVars) == 3 &&
		"cl" in usedVars &&
		"result" in usedVars &&
		"entry" in usedVars;
}

public test bool reduce() {
	prOp = prospectiveOperation("count += rule.getErrors().size();", REDUCE);
	
	usedVars = retrieveUsedVariables(prOp);
	
	return size(usedVars) == 2 &&
		"count" in usedVars &&
		"rule" in usedVars;
}