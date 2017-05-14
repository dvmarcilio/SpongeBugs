module refactor::forloop::EnhancedLoopExpressionTest

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import MethodVar;
import LocalVariablesFinder;
import LocalVariablesFinderTestResources;
import refactor::forloop::ClassFieldsFinder;
import refactor::forloop::EnhancedLoopExpression;

public test bool iterableShouldReturnFalse() {
	params = paramsEnhancedForOnIterable();
	
	return isIteratingOnCollection(params.exp, params.localVariables) == false;
}

private tuple[Expression exp, set[MethodVar] localVariables] paramsEnhancedForOnIterable() {
	tuple[MethodHeader methodHeader, MethodBody methodBody] method = getEnhancedForOnIterable();
	localVariables = findLocalVariables(method.methodHeader, method.methodBody);
	// Making life easier
	exp = parse(#Expression, "keys");
	return <exp, localVariables>;
}

private tuple[MethodHeader methodHeader, MethodBody methodBody] getEnhancedForOnIterable() {
	fileLoc = |project://rascal-Java8//testes/ForLoopToFunctional/EnhancedForOnIterable.java|;
	methodDeclaration = parse(#MethodDeclaration, readFile(fileLoc));
	visit(methodDeclaration) {
		case (MethodDeclaration) `<MethodModifier * _> <MethodHeader methodHeader> <MethodBody methodBody>`: {
			return <methodHeader, methodBody>;
		}
	} 
}

public test bool iterableParamShouldReturnFalse() {
	exp = parse(#Expression, "types");
	methodHeader = iterableParameterMethodHeader();
	methodBody = iterableParameterMethodBody();
	localVariables = findLocalVariables(methodHeader, methodBody);
	
	return isIteratingOnCollection(exp, localVariables) == false;
}

public test bool thisFieldListShouldReturnTrue() {
	exp = parse(#Expression, "this.engineValves");
	methodHeader = parse(#MethodHeader, "void configureEngine(Engine engine)");
	methodBodyLoc = |project://rascal-Java8/testes/classFields/MethodBodyIteratingOnThisField2|;
	methodBody = parse(#MethodBody, readFile(methodBodyLoc));
	localVariables = findLocalVariables(methodHeader, methodBody);
	classFields = findClassFields(parse(#CompilationUnit, readFile(|project://rascal-Java8/testes/classFields/TomcatServletWebServerFactory.java|)));
	vars = localVariables + classFields;
	
	return isIteratingOnCollection(exp, vars) == true;
}