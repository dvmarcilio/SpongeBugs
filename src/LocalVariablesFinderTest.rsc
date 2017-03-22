module LocalVariablesFinderTest

import IO;
import LocalVariablesFinderTestResources;
import LocalVariablesFinder;
import Set;

public test bool shouldHaveTheEnhancedDeclaredVarAsFinal() {
	methodBody = enhancedForLoopFinalVarDecl();
	vars = findLocalVariables(methodBody);
	return "listenable" in vars.finals;
}

public test bool shouldHaveAllFinalVarsInTheEnhancedDeclaredVarAsFinal() {
	methodBody = enhancedForLoopFinalVarDecl();
	vars = findLocalVariables(methodBody);
	return "index" in vars.finals && "listenable" in vars.finals && 
		size(vars.finals) == 2;
}

public test bool shouldHaveTheNonFinalVarsInEnhancedDeclaredVarAsFinal() {
	methodBody = enhancedForLoopFinalVarDecl();
	vars = findLocalVariables(methodBody);
	return "i" in vars.nonFinals && size(vars.nonFinals) == 1;
}





  


