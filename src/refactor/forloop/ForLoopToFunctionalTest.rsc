module refactor::forloop::ForLoopToFunctionalTest

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import refactor::forloop::ForLoopToFunctional;
import MethodVar;
import LocalVariablesFinder;
import ParseTreeVisualization;

public test bool x() {
	fileLoc = |project://rascal-Java8//testes/ForLoopToFunctional/T1.java|;
	methodBody = parse(#MethodBody, readFile(fileLoc));
	methodHeader = parse(#MethodHeader, "TestSuite createTestSuite()");
	set[MethodVar] methodVars = findLocalVariables(methodHeader, methodBody);
	EnhancedForStatement forStmt = parse(#EnhancedForStatement, "for (Class\<? extends AbstractTester\> testerClass : testers) {\n      final TestSuite testerSuite =\n          makeSuiteForTesterClass((Class\<? extends AbstractTester\<?\>\>) testerClass);\n      if (testerSuite.countTestCases() \> 0) {\n        suite.addTest(testerSuite);\n      }\n    }");
	VariableDeclaratorId iteratedVarName = parse(#VariableDeclaratorId, "testerClass");
	Expression collectionId = parse(#Expression, "testers");
	
	println(refactorEnhancedToFunctional(methodVars, forStmt, methodBody, iteratedVarName, collectionId));
	
	return false;
}