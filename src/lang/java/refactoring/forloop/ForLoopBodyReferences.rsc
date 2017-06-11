module lang::java::refactoring::forloop::ForLoopBodyReferences

import lang::java::\syntax::Java18;
import String;
import ParseTree;
import IO;
import Set;
import lang::java::refactoring::forloop::MethodVar;

public bool atMostOneReferenceToNonEffectiveFinalVar(set[MethodVar] localVariables, Statement loopBody) {
	return getTotalOfNonEffectiveFinalVarsReferenced(localVariables, loopBody) <= 1;
}

public int getTotalOfNonEffectiveFinalVarsReferenced(set[MethodVar] localVariables, EnhancedForStatement forStmt) {
	return getTotalOfNonEffectiveFinalVarsReferenced(localVariables, retrieveLoopBodyFromEnhancedFor(forStmt)); 
}

public Statement retrieveLoopBodyFromEnhancedFor(EnhancedForStatement forStmt) {
	top-down-break visit (forStmt) {
		case (EnhancedForStatement) `for ( <VariableModifier* _> <UnannType _> <VariableDeclaratorId _>: <Expression _> ) <Statement loopBody>`:
		return loopBody;
	}	
	throw "Error";
}

public int getTotalOfNonEffectiveFinalVarsReferenced(set[MethodVar] localVariables, Statement loopBody) {
	varsReferencedNames = findVariablesReferenced(loopBody);
	nonEffectiveFinalVarsReferencedCount = 0;
	
	for (varReferencedName <- varsReferencedNames) {
		var = findByName(localVariables, varReferencedName);
		if (!isEffectiveFinal(var) && !var.isDeclaredWithinLoop)
			nonEffectiveFinalVarsReferencedCount += 1;
	}
	
	return nonEffectiveFinalVarsReferencedCount;
}

// XXX UsedVariables could use the same thing
// XXX Ignoring class fields. ('this.x')
public set[str] findVariablesReferenced(Statement loopBody) {
	set[str] varsReferenced = {};

	visit (loopBody) {
		case ExpressionName expName: {
			visit(expName) {
				case Identifier id: varsReferenced += unparse(id);
			}
		}
	}	
	
	return varsReferenced;
}