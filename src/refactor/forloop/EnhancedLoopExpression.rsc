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
public bool isIteratingOnCollection(Expression exp, set[MethodVar] localVariables) {
	if (isExpAnIdentifier(exp))
		return isIdentifierACollection(exp, localVariables);
	else
		return false;
}

private bool isExpAnIdentifier(Expression exp) {
	expStr = unparse(exp);
	return !contains(expStr, ".") && !contains(expStr, "(");
}

private bool isIdentifierACollection(Expression exp, set[MethodVar] localVariables) {
	varName = trim(unparse(exp));
	var = findByName(localVariables, varName);
	return !isTypePlainArray(var) && !isIterable(var);
}

// FIXME
private bool isExpressionReturningACollection(Expression exp) {
	return false;
}