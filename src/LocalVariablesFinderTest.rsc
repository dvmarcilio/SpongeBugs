module LocalVariablesFinderTest

import IO;
import LocalVariablesFinderTestResources;
import LocalVariablesFinder;
import Set;
import MethodVar;

public test bool shouldHaveTheEnhancedDeclaredVarAsFinal() {
	methodBody = enhancedForLoopFinalVarDecl();
	vars = findLocalVariables(methodBody);
	finalsNames = retrieveFinalsNames(vars);
	return "listenableFinal" in finalsNames;
}

public test bool shouldHaveAllFinalVarsInTheEnhancedDeclaredVarAsFinal() {
	methodBody = enhancedForLoopFinalVarDecl();
	vars = findLocalVariables(methodBody);
	finalsNames = retrieveFinalsNames(vars);
	return "index" in finalsNames && "listenableFinal" in finalsNames && 
		size(finalsNames) == 2;
}

public test bool shouldHaveTheNonFinalVarsInEnhancedDeclaredVarAsFinal() {
	methodBody = enhancedForLoopFinalVarDecl();
	vars = findLocalVariables(methodBody);
	nonFinalsNames = retrieveNonFinalsNames(vars);
	println(vars);
	println(nonFinalsNames);
	return "i" in nonFinalsNames && "listenableNonFinal" in nonFinalsNames && 
		size(nonFinalsNames) == 2;
}

public test bool shouldHaveAllFinalVarsInEnhancedWithException() {
	methodBody = enhancedForLoopWithException();
	vars = findLocalVariables(methodBody);
	finalsNames = retrieveFinalsNames(vars);
	return "map" in finalsNames && "entrySet" in finalsNames &&
		"unmappedKey" in finalsNames && "unmappedValue" in finalsNames && 
			size(finalsNames) == 4;
}

public test bool shouldHaveAllNonFinalVarsIncludingExceptionInEnhancedWithException() {
	methodBody = enhancedForLoopWithException();
	vars = findLocalVariables(methodBody);
	nonFinalsNames = retrieveNonFinalsNames(vars);
	return "e" in nonFinalsNames && "entry" in nonFinalsNames &&
		size(nonFinalsNames) == 2;
}