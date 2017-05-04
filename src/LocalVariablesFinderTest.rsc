module LocalVariablesFinderTest

import IO;
import LocalVariablesFinderTestResources;
import LocalVariablesFinder;
import Set;
import MethodVar;

public test bool shouldHaveTheEnhancedDeclaredVarAsFinal() {
	methodBody = enhancedForLoopFinalVarDecl();
	vars = findLocalVariables(emptyMethodHeader(), methodBody);
	
	finalsNames = retrieveFinalsNames(vars);
	
	return "listenableFinal" in finalsNames;
}

public test bool shouldHaveAllFinalVarsInTheEnhancedDeclaredVarAsFinal() {
	methodBody = enhancedForLoopFinalVarDecl();
	vars = findLocalVariables(emptyMethodHeader(), methodBody);
	
	finalsNames = retrieveFinalsNames(vars);
	
	return "index" in finalsNames && "listenableFinal" in finalsNames && 
		size(finalsNames) == 2;
}

public test bool shouldHaveTheNonFinalVarsInEnhancedDeclaredVarAsFinal() {
	methodBody = enhancedForLoopFinalVarDecl();
	vars = findLocalVariables(emptyMethodHeader(), methodBody);
	
	nonFinalsNames = retrieveNonFinalsNames(vars);
	
	return "i" in nonFinalsNames && "listenableNonFinal" in nonFinalsNames && 
		size(nonFinalsNames) == 2;
}

public test bool shouldHaveAllFinalVarsInEnhancedWithException() {
	methodBody = enhancedForLoopWithException();
	vars = findLocalVariables(emptyMethodHeader(), methodBody);
	
	finalsNames = retrieveFinalsNames(vars);
	
	return "map" in finalsNames && "entrySet" in finalsNames &&
		"unmappedKey" in finalsNames && "unmappedValue" in finalsNames && 
			size(finalsNames) == 4;
}

public test bool shouldHaveAllNonFinalVarsIncludingExceptionInEnhancedWithException() {
	methodBody = enhancedForLoopWithException();
	vars = findLocalVariables(emptyMethodHeader(), methodBody);
	
	nonFinalsNames = retrieveNonFinalsNames(vars);
	
	return "e" in nonFinalsNames && "entry" in nonFinalsNames &&
		size(nonFinalsNames) == 2;
}

public test bool intVarShouldHaveItsCorrectType() {
	methodBody = enhancedForLoopFinalVarDecl();
	
	vars = findLocalVariables(emptyMethodHeader(), methodBody);
	varI = findByName(vars, "i");
	
	return varI.varType == "int"; 
}

public test bool encouragedDeclaredArrayVarsShouldBeArrays() {
	methodBody = arrayVariables();
	
	vars = findLocalVariables(emptyMethodHeader(), methodBody);
	
	for(methodVar <- getEncouragedArrays(vars)) {
		if(!isTypePlainArray(methodVar)) return false;
	}
	return true;
}

public test bool discouragedDeclaredArrayVarsShouldBeArrays() {
	methodBody = arrayVariables();
	
	vars = findLocalVariables(emptyMethodHeader(), methodBody);
	
	for(methodVar <- getDiscouragedArrays(vars)) {
		if(!isTypePlainArray(methodVar)) return false;
	}
	return true;
}

public test bool nonFinalArraysShouldBeNonFinal() {
	methodBody = arrayVariables();
	
	vars = findLocalVariables(emptyMethodHeader(), methodBody);
	
	for(methodVar <- getAllNonFinalArrays(vars)) {
		if(methodVar.isFinal) return false;
	}
	return true;
}

public test bool finalArraysShouldBeFinal() {
	methodBody = arrayVariables();
	
	vars = findLocalVariables(emptyMethodHeader(), methodBody);
	
	for(methodVar <- getAllFinalArrays(vars)) {
		if(!methodVar.isFinal) return false;
	}
	return true;
}

public test bool shouldReturnNonFinalSingleParameter() {
	methodHeader = nonFinalSingleParameterMethodHeader();
	methodBody = emptyMethodBody();
	
	vars = findLocalVariables(methodHeader, methodBody);
	nonLocals = retrieveParameters(vars);
	var = findByName(vars, "param");
	
	return size(nonLocals) == 1 && !var.isFinal && var.isParameter;
}

public test bool shouldReturnFinalSingleParameter() {
	methodHeader = finalSingleParameterMethodHeader();
	methodBody = emptyMethodBody();
	
	vars = findLocalVariables(methodHeader, methodBody);
	nonLocals = retrieveParameters(vars);
	var = findByName(vars, "finalParam");
	
	return size(nonLocals) == 1 && var.isFinal && var.isParameter;
}

public test bool shouldReturnCorrectParamsWithLastOneFinal() {
	methodHeader = multipleParametersLastFinalMethodHeader();
	methodBody = emptyMethodBody();
	
	vars = findLocalVariables(methodHeader, methodBody);
	nonLocals = retrieveParameters(vars);
	param = findByName(vars, "param");
	strParam = findByName(vars, "str");
	finalLastParam = findByName(vars, "finalLastParam");
	
	return size(nonLocals) == 3 &&
		!param.isFinal && param.isParameter &&
		!strParam.isFinal && strParam.isParameter &&
		finalLastParam.isFinal && finalLastParam.isParameter;
}

public test bool shouldReturnCorrectParamsWithLastOneNonFinal() {
	methodHeader = multipleParametersLastNonFinalMethodHeader();
	methodBody = emptyMethodBody();
	
	vars = findLocalVariables(methodHeader, methodBody);
	nonLocals = retrieveParameters(vars);
	param = findByName(vars, "param");
	strParam = findByName(vars, "str");
	nonFinalLastParam = findByName(vars, "nonFinalLastParam");
	
	return size(nonLocals) == 3 &&
		!param.isFinal && param.isParameter &&
		!strParam.isFinal && strParam.isParameter &&
		!nonFinalLastParam.isFinal && nonFinalLastParam.isParameter;
}

public test bool shouldReturnCorrectVarsDeclaredWithinLoop() {
	methodHeader = varsWithinTheLoopMethodHeader();
	methodBody = varsWithinTheLoopMethodBody();
	
	vars = findLocalVariables(methodHeader, methodBody);
	varsWithinLoop = retrieveDeclaredWithinLoop(vars);
	withinLoopNames = retrieveDeclaredWithinLoopNames(vars);
	
	return size(varsWithinLoop) == 3 &&
		"insideDecl" in withinLoopNames &&
		"insideBody" in withinLoopNames &&
		"insideBodyStr" in withinLoopNames;
}

public test bool shouldReturnCorrectVarsNotDeclaredWithinLoop() {
	methodHeader = varsWithinTheLoopMethodHeader();
	methodBody = varsWithinTheLoopMethodBody();
	
	vars = findLocalVariables(methodHeader, methodBody);
	varsNotWithinLoop = retrieveNotDeclaredWithinLoop(vars);
	notWithinLoopNames = retrieveNotDeclaredWithinLoopNames(vars);
	
	return size(varsNotWithinLoop) == 5 &&
		"notWithinLoop" in notWithinLoopNames &&
		"notWithinLoopAgain" in notWithinLoopNames &&
		"localVarNotWithinLoop" in notWithinLoopNames &&
		"localVarNotWithinLoopAgain" in notWithinLoopNames &&
		"notWithinLoopAfterLoop" in notWithinLoopNames;
}

public test bool shouldIdentifyNonEffectiveFinalVar() {
	methodHeader = nonEffectiveFinalUsedInEnhancedForMethodHeader();
	methodBody = nonEffectiveFinalUsedInEnhancedForMethodBody();
	
	vars = findLocalVariables(methodHeader, methodBody);
	nonEffectiveFinalVar = findByName(vars, "prefix");
	
	return !isEffectiveFinal(nonEffectiveFinalVar);
}

public test bool shouldParseCorrectTypeFromIterableParameter() {
	methodHeader = iterableParameterMethodHeader();
	methodBody = iterableParameterMethodBody();
	
	vars = findLocalVariables(methodHeader, methodBody);
	iterableParam = findByName(vars, "types");
	
	return iterableParam.varType == "Iterable\<? extends K\>";
}

public test bool shouldIdentifyAnonnymousInnerClassMethodParams() {
	methodHeader = methodWithAnonnymousInnerClassMethodHeader();
	methodBody = methodWithAnonnymousInnerClassMethodBody();
	
	vars = findLocalVariables(methodHeader, methodBody);
	iterableParam = findByName(vars, "types");
	
	return iterableParam.varType == "Iterable\<? extends K\>";
}

public test bool postIncrementedVariableInsideLoopShouldBeNonEffectiveFinal() {
	methodHeader = postIncrementedVarMethodHeader();
	methodBody = postIncrementedVarMethodBody();
	
	vars = findLocalVariables(methodHeader, methodBody);
	i = findByName(vars, "i");

	return !i.isEffectiveFinal && !isEffectiveFinal(i);
}

public test bool postIncrementedVariable2InsideLoopShouldBeNonEffectiveFinal() {
	methodHeader = postIncrementedVar2MethodHeader();
	methodBody = postIncrementedVar2MethodBody();
	
	vars = findLocalVariables(methodHeader, methodBody);
	i = findByName(vars, "i");

	return !i.isEffectiveFinal && !isEffectiveFinal(i);
}

public test bool postIncrementedVariable3InsideLoopShouldBeNonEffectiveFinal() {
	methodHeader = postIncrementedVar3MethodHeader();
	methodBody = postIncrementedVar3MethodBody();
	
	vars = findLocalVariables(methodHeader, methodBody);
	i = findByName(vars, "i");

	return !i.isEffectiveFinal && !isEffectiveFinal(i);
}

public test bool postDecrementedVariableInsideLoopShouldBeNonEffectiveFinal() {
	methodHeader = postDecrementedVarMethodHeader();
	methodBody = postDecrementedVarMethodBody();
	
	vars = findLocalVariables(methodHeader, methodBody);
	misses = findByName(vars, "misses");

	return !misses.isEffectiveFinal && !isEffectiveFinal(misses);
}