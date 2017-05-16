module lang::java::refactoring::forloop::AvailableVariables

import Set;
import lang::java::\syntax::Java18;
import ParseTree;
import lang::java::refactoring::forloop::MethodVar;
import lang::java::refactoring::forloop::ProspectiveOperation;

// XXX assess the necessity to verify these others conditions:
	// fields declared in class, inherited and visible from imported classes ??
	// variables declared in the Prospective Operation ??
// Right now they are being verified by elimination.
public set[str] retrieveAvailableVariables(ProspectiveOperation prOp, set[MethodVar] methodVars) {
	availableVars = {};
	
	withinMethod = retrieveNotDeclaredWithinLoopNames(methodVars); 
	withinLoop = retrieveDeclaredWithinLoopNames(methodVars);
	
	availableVars += withinMethod;
	availableVars -= withinLoop;
	// Probably redundant somehow. This will catch some withinLoop. 
	availableVars += retrieveLocalVariableDeclarations(prOp);
	
	return availableVars;
}

private set[str] retrieveLocalVariableDeclarations(ProspectiveOperation prOp) {
	if (isFilter(prOp)) return {};

	localVars = {};
	Tree stmt;	
	
	if (isLocalVariableDeclarationStatement(prOp.stmt))
		stmt = parse(#LocalVariableDeclarationStatement, prOp.stmt);
	else
		stmt = parse(#Statement, prOp.stmt);
		
	visit(stmt) {
		case LocalVariableDeclaration lvdl: {
			visit(lvdl) {
				case (VariableDeclaratorId) `<Identifier id>`: localVars += unparse(id);
			}
		}
	}
	return localVars;
}