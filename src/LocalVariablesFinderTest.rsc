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

public test bool shouldHaveAllFinalVarsInEnhancedWithException() {
	methodBody = enhancedForLoopWithException();
	vars = findLocalVariables(methodBody);
	return "map" in vars.finals && "entrySet" in vars.finals &&
		"unmappedKey" in vars.finals && "unmappedValue" in vars.finals && 
			size(vars.finals) == 4;
}

public test bool shouldHaveAllNonFinalVarsIncludingExceptionInEnhancedWithException() {
	methodBody = enhancedForLoopWithException();
	vars = findLocalVariables(methodBody);
	return "e" in vars.nonFinals && "entry" in vars.nonFinals &&
		size(vars.nonFinals) == 2;
}