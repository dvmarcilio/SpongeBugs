module refactor::forloop::ForLoopToFunctionalTest

import IO;
import String;
import lang::java::\syntax::Java18;
import ParseTree;
import refactor::forloop::ForLoopToFunctional;
import MethodVar;
import LocalVariablesFinder;
import ParseTreeVisualization;

public test bool ex1() {
	fileLoc = |project://rascal-Java8//testes/ForLoopToFunctional/T1.java|;
	methodBody = parse(#MethodBody, readFile(fileLoc));
	methodHeader = parse(#MethodHeader, "TestSuite createTestSuite()");
	set[MethodVar] methodVars = findLocalVariables(methodHeader, methodBody);
	EnhancedForStatement forStmt = parse(#EnhancedForStatement, "for (Class\<? extends AbstractTester\> testerClass : testers) {\n      final TestSuite testerSuite =\n          makeSuiteForTesterClass((Class\<? extends AbstractTester\<?\>\>) testerClass);\n      if (testerSuite.countTestCases() \> 0) {\n        suite.addTest(testerSuite);\n      }\n    }");
	VariableDeclaratorId iteratedVarName = parse(#VariableDeclaratorId, "testerClass");
	Expression collectionId = parse(#Expression, "testers");
	
	refactoredStatement = buildRefactoredEnhancedFor(methodVars, forStmt, methodBody, iteratedVarName, collectionId);
	
	return unparse(refactoredStatement) == "testers.stream().map(testerClass -\> makeSuiteForTesterClass((Class\<? extends AbstractTester\<?\>\>) testerClass)).filter(testerSuite -\> testerSuite.countTestCases() \> 0).forEach(testerSuite -\> {\nsuite.addTest(testerSuite);\n});";
}

// FIXME workaround for now. not really useful test.
public test bool reduceShouldNotBeEmpty() {
	fileLoc = |project://rascal-Java8//testes/ForLoopToFunctional/T2.java|;
	methodBody = parse(#MethodBody, readFile(fileLoc));
	methodHeader = parse(#MethodHeader, "void assertInvariants(Map\<K, V\> map)");
	set[MethodVar] methodVars = findLocalVariables(methodHeader, methodBody);
	fileForLoc = |project://rascal-Java8//testes/ForLoopToFunctional/T2For.java|;
	EnhancedForStatement forStmt = parse(#EnhancedForStatement, readFile(fileForLoc));
	VariableDeclaratorId iteratedVarName = parse(#VariableDeclaratorId, "key");
	Expression collectionId = parse(#Expression, "keySet");
	
	refactoredStatement = buildRefactoredEnhancedFor(methodVars, forStmt, methodBody, iteratedVarName, collectionId);
	
	return !isEmpty("<refactoredStatement>");
}