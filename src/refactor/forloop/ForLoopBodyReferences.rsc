module refactor::forloop::ForLoopBodyReferences

import lang::java::\syntax::Java18;
import String;
import ParseTree;
import IO;
import Set;
import MethodVar;

// TODO still need to find effective final vars somewhere.
public bool atMostOneReferenceToNonEffectiveFinalVar(set[MethodVar] localVariables, Statement loopBody) {
	varsReferenced = findVariablesReferenced(loopBody);
	return size(varsReferenced) <= 1;
}

private set[str] findVariablesReferenced(Statement stmt) {
	set[str] varsReferenced = {};

	visit (stmt) {
		case (Assignment) `<LeftHandSide lhs> <AssignmentOperator _> <Expression _>`:
			varsReferenced += trim(unparse(lhs));
	}	
	
	return varsReferenced;
}