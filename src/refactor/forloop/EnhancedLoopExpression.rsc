module refactor::forloop::EnhancedLoopExpression

import lang::java::\syntax::Java18;
import ParseTree;
import MethodVar;
import String;
import IO;

// XXX Only checking iterable variables defined in method (local and parameter)
// Need to verify class and instance variables too!
// Doing the full check on a method call will be an entire new problem
// example: for (Object rowKey : table.rowKeySet())

// Relying on compiler to help finding if it's an array or not
// Compiler gives error if expression is not Array/Collection
// Therefore we only check if the expression is an Array
public bool isIteratingOnCollection(Expression exp, set[MethodVar] availableVariables) {
	if (!isMethodInvocation(exp))
		return isIdentifierACollection(exp, availableVariables);
	else
		return false;
}

// XXX Ignoring Casts too.
// Redundant for now, because any method invocation will contain '('
// But not everything that have '(' will be a method invocation. (Casts for instance)
private bool isMethodInvocation(Expression exp) {
	expStr = "<exp>";
	return contains(expStr, "(") && parsesAsMethodInvocation(expStr);
}

private bool parsesAsMethodInvocation(str expStr) {
	try {
		parse(#MethodInvocation, expStr);
		return true;
	} catch:
		return false;
}

private bool isIdentifierACollection(Expression exp, set[MethodVar] availableVariables) {
	varName = trim(unparse(exp));
	// TODO eventually change/remove when dealing correctly with fields + local variables 
	varName = replaceFirst(varName, "this.", "");
	
	var = findByName(availableVariables, varName);
	return !isTypePlainArray(var) && !isIterable(var);
}

// FIXME
private bool isExpressionReturningACollection(Expression exp) {
	return false;
}