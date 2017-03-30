module refactor::forloop::AvailableVariables

import Set;
import MethodVar;
import refactor::forloop::ProspectiveOperation;

// XXX assess the necessity to verify these others conditions:
	// fields declared in class, inherited and visible from imported classes ??
	// variables declared in the Prospective Operation ??
// Right now they are being verified by elimination.
public set[str] retrieveAvailableVars(ProspectiveOperation prOp, set[MethodVar] methodVars) {
	withinMethod = retrieveNotDeclaredWithinLoopNames(methodVars); 
	withinLoop = retrieveDeclaredWithinLoopNames(methodVars);
	return withinMethod - withinLoop;
}