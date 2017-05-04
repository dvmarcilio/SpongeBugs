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

public test bool reduceAsNotTheLastOperationShouldNotBeRefactored() {
	fileLoc = |project://rascal-Java8//testes/ForLoopToFunctional/T2.java|;
	methodBody = parse(#MethodBody, readFile(fileLoc));
	methodHeader = parse(#MethodHeader, "void assertInvariants(Map\<K, V\> map)");
	set[MethodVar] methodVars = findLocalVariables(methodHeader, methodBody);
	fileForLoc = |project://rascal-Java8//testes/ForLoopToFunctional/T2For.java|;
	EnhancedForStatement forStmt = parse(#EnhancedForStatement, readFile(fileForLoc));
	VariableDeclaratorId iteratedVarName = parse(#VariableDeclaratorId, "key");
	Expression collectionId = parse(#Expression, "keySet");
	
	try
		refactoredStatement = buildRefactoredEnhancedFor(methodVars, forStmt, methodBody, iteratedVarName, collectionId);
	catch:
		return true;
	
	// Should have thrown exception
	return false;
}

// TODO nested loops needed to be changed in ProspectiveOperation
//public test bool nestedLoops() {
//	fileLoc = |project://rascal-Java8//testes/ForLoopToFunctional/NestedLoops.java|;
//	methodBody = parse(#MethodBody, readFile(fileLoc));
//	methodHeader = parse(#MethodHeader, "void testComplexBuilder()");
//	set[MethodVar] methodVars = findLocalVariables(methodHeader, methodBody);
//	fileForLoc = |project://rascal-Java8//testes/ForLoopToFunctional/T2For.java|;	
//	EnhancedForStatement forStmt = parse(#EnhancedForStatement, "for (Integer red : colorElem) {\n      for (Integer green : colorElem) {\n        for (Integer blue : colorElem) {\n          webSafeColorsBuilder.add((red \<\< 16) + (green \<\< 8) + blue);\n        }\n      }\n    }");
//	VariableDeclaratorId iteratedVarName = parse(#VariableDeclaratorId, "red");
//	Expression collectionId = parse(#Expression, "colorElem");
//	
//	refactoredStatement = buildRefactoredEnhancedFor(methodVars, forStmt, methodBody, iteratedVarName, collectionId);
//	
//	return false;
//}

public test bool shouldRefactorReduceWithCompoundPlusAssignmentOperator() {
	fileLoc = |project://rascal-Java8//testes/ForLoopToFunctional/T2.java|;
	methodBody = parse(#MethodBody, readFile(fileLoc));
	methodHeader = parse(#MethodHeader, "void assertInvariants(Map\<K, V\> map)");
	set[MethodVar] methodVars = findLocalVariables(methodHeader, methodBody);
	fileForLoc = |project://rascal-Java8//testes/ForLoopToFunctional/T2For2.java|;
	EnhancedForStatement forStmt = parse(#EnhancedForStatement, readFile(fileForLoc));
	VariableDeclaratorId iteratedVarName = parse(#VariableDeclaratorId, "entry");
	Expression collectionId = parse(#Expression, "entrySet");
	
	refactoredStatement = buildRefactoredEnhancedFor(methodVars, forStmt, methodBody, iteratedVarName, collectionId);

	return unparse(refactoredStatement) == "entrySet.stream().map(entry -\> {\nassertTrue(map.containsKey(entry.getKey()));\nreturn entry;\n}).map(entry -\> {\nassertTrue(map.containsValue(entry.getValue()));\nreturn entry;\n}).map(entry -\> {\nint expectedHash =\r\n            (entry.getKey() == null ? 0 : entry.getKey().hashCode())\r\n                ^ (entry.getValue() == null ? 0 : entry.getValue().hashCode());\nassertEquals(expectedHash, entry.hashCode());\nreturn expectedHash;\n}).map(expectedHash -\> expectedHash).reduce(expectedEntrySetHash, Integer::sum);";
}

public test bool shouldAddReturnToMapWithMoreThanOneStatement() {
	methodBodyLoc = |project://rascal-Java8//testes/ForLoopToFunctional/MethodBodyWithMultiStatementMap.java|;
	methodBody = parse(#MethodBody, readFile(methodBodyLoc));
	methodHeader = parse(#MethodHeader, "Iterable\<Metric\<?\>\> findAll()");
	set[MethodVar] methodVars = findLocalVariables(methodHeader, methodBody);
	fileForLoc = |project://rascal-Java8//testes/ForLoopToFunctional/ForWithMultiStatementMap.java|;
	EnhancedForStatement forStmt = parse(#EnhancedForStatement, readFile(fileForLoc));
	VariableDeclaratorId iteratedVarName = parse(#VariableDeclaratorId, "v");
	Expression collectionId = parse(#Expression, "values");
	
	refactoredStatement = buildRefactoredEnhancedFor(methodVars, forStmt, methodBody, iteratedVarName, collectionId);
	
	return unparse(refactoredStatement) == "values.stream().map(v -\> {\nString key = keysIt.next();\nMetric\<?\> value = deserialize(key, v, this.zSetOperations.score(key));\nreturn value;\n}).filter(value -\> value != null).forEach(value -\> {\nresult.add(value);\n});";
}

public test bool shouldAddCorrectReturnTo3StmtsMapBody() {
	methodBodyLoc = |project://rascal-Java8//testes/ForLoopToFunctional/MethodBodyWIth3StatementsMapBody.java|;
	methodBody = parse(#MethodBody, readFile(methodBodyLoc));
	methodHeader = parse(#MethodHeader, "void updateSnapshots(Collection\<FolderSnapshot\> snapshots)");
	set[MethodVar] methodVars = findLocalVariables(methodHeader, methodBody);
	fileForLoc = |project://rascal-Java8//testes/ForLoopToFunctional/ForWith3StatementsMapBody.java|;
	EnhancedForStatement forStmt = parse(#EnhancedForStatement, readFile(fileForLoc));
	VariableDeclaratorId iteratedVarName = parse(#VariableDeclaratorId, "snapshot");
	Expression collectionId = parse(#Expression, "snapshots");
	
	refactoredStatement = buildRefactoredEnhancedFor(methodVars, forStmt, methodBody, iteratedVarName, collectionId);
	
	return unparse(refactoredStatement) == "snapshots.stream().map(snapshot -\> {\nFolderSnapshot previous = this.folders.get(snapshot.getFolder());\nupdated.put(snapshot.getFolder(), snapshot);\nChangedFiles changedFiles = previous.getChangedFiles(snapshot,\r\n                                                this.triggerFilter);\nreturn changedFiles;\n}).filter(changedFiles -\> !changedFiles.getFiles().isEmpty()).forEach(changedFiles -\> {\nchangeSet.add(changedFiles);\n});";
}