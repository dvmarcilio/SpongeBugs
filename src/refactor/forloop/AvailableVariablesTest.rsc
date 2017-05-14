module refactor::forloop::AvailableVariablesTest

import refactor::forloop::AvailableVariables;
import refactor::forloop::ProspectiveOperation;
import refactor::forloop::OperationType;
import MethodVar;
import Set;
import IO;

public test bool methodParamShouldBeAvailableVar() {
	prOp = prospectiveOperation("writer.write(thing);", FOR_EACH);	
	methodVars = {methodVar(false, "thing", "String", false, true, false), 
		methodVar(false, "writer", "PrintWriter", true, false, false)};
	
	availableVars = retrieveAvailableVariables(prOp, methodVars);
	
	return size(availableVars) == 1 &&
		"writer" in availableVars;
}

public test bool varWithinLoopShouldNotBeAvailable() {
	prOp = prospectiveOperation("rule.hasErrors()", FILTER);
	methodVars = {methodVar(false, "count", "int", false, false, false), 
		methodVar(false, "rule", "ElementRule", false, true, false)};
		
	availableVars = retrieveAvailableVariables(prOp, methodVars);
	
	return "rule" notin availableVars;
}

public test bool varNotWithinLoopShouldBeAvailable() {
	prOp = prospectiveOperation("rule.hasErrors()", FILTER);
	methodVars = {methodVar(false, "count", "int", false, false, false), 
		methodVar(false, "rule", "ElementRule", false, true, false)};
		
	availableVars = retrieveAvailableVariables(prOp, methodVars);
	
	return "count" in availableVars;
}

public test bool localVariableDeclarationShouldBeAvailableVar() {
	prOp = prospectiveOperation("ClassLoader cl = entry.getKey();", MAP);
	methodVars = {}; // Independent in this case
	
	availableVars = retrieveAvailableVariables(prOp, methodVars);
	
	return size(availableVars) == 1 && 
		"cl" in availableVars;
}

public test bool localVariableDeclAlongWithVarNotWithinLoopShouldBeAvailableVars() {
	prOp = prospectiveOperation("ClassLoader cl = entry.getKey();", MAP);
	methodVars = {methodVar(false, "result", "List\<String\>", false, false, false)};
	
	availableVars = retrieveAvailableVariables(prOp, methodVars);
	
	return size(availableVars) == 2 && 
		"cl" in availableVars &&
		"result" in availableVars;
}

public test bool localVariableDeclarationWithArgsInInitializerShouldBeAvailableVar() {
	prOp = prospectiveOperation("ClassLoader cl = entry.getKey(argNeeded);", MAP);
	methodVars = {}; // Independent in this case
	
	availableVars = retrieveAvailableVariables(prOp, methodVars);
	
	return size(availableVars) == 1 && 
		"cl" in availableVars;
}