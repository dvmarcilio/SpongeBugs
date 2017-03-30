module LocalVariablesFinderTestResources

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import MethodVar;

public MethodHeader emptyMethodHeader() {
	header = "void method()";
	return parse(#MethodHeader, header);
}

public MethodHeader nonFinalSingleParameterMethodHeader() {
	header = "void method(int param)";
	return parse(#MethodHeader, header);
}

public MethodHeader finalSingleParameterMethodHeader() {
	header = "void method(final int finalParam)";
	return parse(#MethodHeader, header);
}

public MethodHeader multipleParametersLastFinalMethodHeader() {
	header = "void method(int param, String str, final double finalLastParam)";
	return parse(#MethodHeader, header);
}

public MethodHeader multipleParametersLastNonFinalMethodHeader() {
	header = "void method(int param, String str, double nonFinalLastParam)";
	return parse(#MethodHeader, header);
}

public MethodBody emptyMethodBody() {
	body = "{}";
	return parse(#MethodBody, body);
} 

public MethodBody enhancedForLoopFinalVarDecl() {
	fileLoc = |project://rascal-Java8//testes/localVariables/EnhancedForLoopFinalVarDecl|;
	content = readFile(fileLoc);
	return parse(#MethodBody, content);
}

public MethodBody enhancedForLoopWithException() {
	fileLoc = |project://rascal-Java8//testes/localVariables/EnhancedForLoopWithException|;
	content = readFile(fileLoc);
	return parse(#MethodBody, content);
}

public MethodBody arrayVariables() {
	fileLoc = |project://rascal-Java8//testes/localVariables/MultiplePlainArrayDeclarations|;
	content = readFile(fileLoc);
	return parse(#MethodBody, content);
}

public set[MethodVar] getEncouragedArrays(set[MethodVar] vars) {
	return getNonFinalEncouragedArrays(vars) + getFinalEncouragedArrays(vars);
}

public set[MethodVar] getNonFinalEncouragedArrays(set[MethodVar] vars) {
	varIntArray = findByName(vars, "intArray");
	varStrArray = findByName(vars, "strArray");
	varObjArray = findByName(vars, "objArray");
	return {varIntArray, varStrArray, varObjArray};
}

public set[MethodVar] getFinalEncouragedArrays(set[MethodVar] vars) {
	varFinalObjArray = findByName(vars, "finalObjArray");
	varFinalStrArray = findByName(vars, "finalStrArray");
	return {varFinalObjArray, varFinalStrArray};
}

public set[MethodVar] getDiscouragedArrays(set[MethodVar] vars) {
	return getNonFinalDiscouragedArrays(vars) + getFinalDiscouragedArrays(vars);
}

public set[MethodVar] getNonFinalDiscouragedArrays(set[MethodVar] vars) {
	varObjDiscouraged = findByName(vars, "objDiscouraged");
	varStrDiscouraged = findByName(vars, "strDiscouraged");
	return {varObjDiscouraged, varStrDiscouraged};
}

public set[MethodVar] getFinalDiscouragedArrays(set[MethodVar] vars) {
	varFinalObjDiscouraged = findByName(vars, "finalObjDiscouraged");
	varFinalIntDiscouraged = findByName(vars, "finalIntDiscouraged");
	return {varFinalObjDiscouraged, varFinalIntDiscouraged};
}

public set[MethodVar] getAllNonFinalArrays(set[MethodVar] vars) {
	return getNonFinalEncouragedArrays(vars) + getNonFinalDiscouragedArrays(vars);
}

public set[MethodVar] getAllFinalArrays(set[MethodVar] vars) {
	return getFinalEncouragedArrays(vars) + getFinalDiscouragedArrays(vars);
}

public MethodHeader varsWithinTheLoopMethodHeader() {
	header = "void method(int notWithinLoop, String notWithinLoopAgain)";
	return parse(#MethodHeader, header);
}

public MethodBody varsWithinTheLoopMethodBody() {
	fileLoc = |project://rascal-Java8//testes/localVariables/EnhancedForLoopVarsWithinLoop|;
	content = readFile(fileLoc);
	return parse(#MethodBody, content);
}