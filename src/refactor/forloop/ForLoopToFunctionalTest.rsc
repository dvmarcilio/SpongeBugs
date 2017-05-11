module refactor::forloop::ForLoopToFunctionalTest

import IO;
import String;
import lang::java::\syntax::Java18;
import ParseTree;
import refactor::forloop::ForLoopToFunctional;
import MethodVar;
import LocalVariablesFinder;
import LocalVariablesFinderTestResources;
import refactor::forloop::ProspectiveOperationTestResources;
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
	
	return "<refactoredStatement>" == "testers.stream().map(testerClass -\> makeSuiteForTesterClass((Class\<? extends AbstractTester\<?\>\>) testerClass)).filter(testerSuite -\> testerSuite.countTestCases() \> 0).forEach(testerSuite -\> {\n        suite.addTest(testerSuite);\n      });";
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
	
	return "<refactoredStatement>" ==  "values.stream().map(v -\> {\nString key = keysIt.next();\nMetric\<?\> value = deserialize(key, v, this.zSetOperations.score(key));\nreturn value;\n}).filter(value -\> value != null).forEach(value -\> {\r\n\t\t\t\tresult.add(value);\r\n\t\t\t});";
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
	
	return "<refactoredStatement>" == "snapshots.stream().map(snapshot -\> {\nFolderSnapshot previous = this.folders.get(snapshot.getFolder());\nupdated.put(snapshot.getFolder(), snapshot);\nChangedFiles changedFiles = previous.getChangedFiles(snapshot,\r\n                                                this.triggerFilter);\nreturn changedFiles;\n}).filter(changedFiles -\> !changedFiles.getFiles().isEmpty()).forEach(changedFiles -\> {\r\n                                        changeSet.add(changedFiles);\r\n                                });";
}

public test bool shouldThrowExceptionWhenALoopWithOnlyOneReferenceToOutsideNonEffectiveFinalVarIsNotAReducer() {
	methodHeader = assignmentInsideForMethodHeader();
	methodBody = assignmentInsideForMethodBody();
	methodVars = findLocalVariables(methodHeader, methodBody);
	VariableDeclaratorId iteratedVarName = parse(#VariableDeclaratorId, "entry");
	Expression collectionId = parse(#Expression, "dir");
	EnhancedForStatement forStmt = parse(#EnhancedForStatement, "for (Path entry : dir) {\n               exceptions = concat(exceptions, deleteRecursivelyInsecure(entry));\n            }");
	
	try {
		refactoredStatement = buildRefactoredEnhancedFor(methodVars, forStmt, methodBody, iteratedVarName, collectionId);
	} catch:
		return true;
		
	return false;	
}

public test bool shouldThrowExceptionWhenALoopWithOnlyOneReferenceToOutsideNonEffectiveFinalVarIsNotAReducer2() {
	methodHeader = parse(#MethodHeader, "\<E\> ImmutableSortedMultiset\<E\> copyOfSortedEntries(Comparator\<? super E\> comparator, Collection\<Entry\<E\>\> entries)");
  	methodBodyLoc = |project://rascal-Java8/testes/localVariables/MethodBodyWithTwoReferencesToOutsideNonEffectiveVars|;
  	methodBody = parse(#MethodBody, readFile(methodBodyLoc));
  	methodVars = findLocalVariables(methodHeader, methodBody);
  	forStmt = parse(#EnhancedForStatement, "for (Entry\<E\> entry : entries) {\n      elementsBuilder.add(entry.getElement());\n      cumulativeCounts[i + 1] = cumulativeCounts[i] + entry.getCount();\n      i++;\n    }");
  	VariableDeclaratorId iteratedVarName = parse(#VariableDeclaratorId, "entry");
	Expression collectionId = parse(#Expression, "entries");
  	
  	try {
		refactoredStatement = buildRefactoredEnhancedFor(methodVars, forStmt, methodBody, iteratedVarName, collectionId);
	} catch:
		return true;
		
	return false;	 	
}

public test bool shouldWorkWithThrowStatementInsideAnIfThatIsNotTheLastStatement() {
	tuple [set[MethodVar] vars, EnhancedForStatement loop] loopWithThrowStatement = loopWithThrowStatement();
	methodBodyLoc = |project://rascal-Java8//testes/localVariables/MethodBodyPostDecrementedVar|;
  	methodBody = parse(#MethodBody, readFile(methodBodyLoc));
	VariableDeclaratorId iteratedVarName = parse(#VariableDeclaratorId, "key");
	Expression collectionId = parse(#Expression, "keysToLoad");
  	
  	refactoredStatement = buildRefactoredEnhancedFor(loopWithThrowStatement.vars, loopWithThrowStatement.loop, methodBody, iteratedVarName, collectionId);
  	
  	return "<refactoredStatement>" == "keysToLoad.forEach(key -\> {\nV value = newEntries.get(key);\nif (value == null) {\n              throw new InvalidCacheLoadException(\"loadAll failed to return a value for \" + key);\n            }\nresult.put(key, value);\n});";
}

public test bool loopWithIfWithTwoStatementsInsideBlockShouldRefactorInnerIfAsMap() {
	tuple [set[MethodVar] vars, EnhancedForStatement loop] loop = loopWithIfWithTwoStatementsInsideBlock();
	methodBodyLoc = |project://rascal-Java8//testes/ForLoopToFunctional/MethodBodyIfWithTwoStmtsInsideAndStmtAfterBlock.java|;
  	methodBody = parse(#MethodBody, readFile(methodBodyLoc));
	VariableDeclaratorId iteratedVarName = parse(#VariableDeclaratorId, "endpoint");
	Expression collectionId = parse(#Expression, "endpoints");
  	
  	refactoredStatement = buildRefactoredEnhancedFor(loop.vars, loop.loop, methodBody, iteratedVarName, collectionId);
	
	return "<refactoredStatement>" == "endpoints.stream().filter(endpoint -\> isIncluded(endpoint)).map(endpoint -\> endpointHandlerMapping.getPath(endpoint.getPath())).map(path -\> {\npaths.add(path);\nreturn path;\n}).map(path -\> {\nif (!path.equals(\"\")) {\r\n\t\t\t\t\t\tpaths.add(path + \"/**\");\r\n\t\t\t\t\t\t// Add Spring MVC-generated additional paths\r\n\t\t\t\t\t\tpaths.add(path + \".*\");\r\n\t\t\t\t\t}\nreturn path;\n}).forEach(path -\> {\npaths.add(path + \"/\");\n});";
}

public test bool anotherIfThatIsMap() {
	methodHeader = parse(#MethodHeader, "void afterPropertiesSet() throws Exception");
  	methodBodyLoc = |project://rascal-Java8/testes/ForLoopToFunctional/MethodBodyIfAsNotAFilter|;
  	methodBody = parse(#MethodBody, readFile(methodBodyLoc));
  	methodVars = findLocalVariables(methodHeader, methodBody);
  	forStmt = parse(#EnhancedForStatement, "for (Endpoint\<?\> endpoint : delegates) {if (isGenericEndpoint(endpoint.getClass()) && endpoint.isEnabled()) {EndpointMvcAdapter adapter = new EndpointMvcAdapter(endpoint);String path = determinePath(endpoint,this.applicationContext.getEnvironment());if (path != null) {adapter.setPath(path);}this.endpoints.add(adapter);}}");
  	VariableDeclaratorId iteratedVarName = parse(#VariableDeclaratorId, "endpoint");
	Expression collectionId = parse(#Expression, "delegates");
	
	refactoredStatement = buildRefactoredEnhancedFor(methodVars, forStmt, methodBody, iteratedVarName, collectionId);
	
	println(refactoredStatement);
	
	return "<refactoredStatement>" == "delegates.stream().filter(endpoint -\> isGenericEndpoint(endpoint.getClass()) && endpoint.isEnabled()).map(endpoint -\> {\nEndpointMvcAdapter adapter = new EndpointMvcAdapter(endpoint);\nString path = determinePath(endpoint,this.applicationContext.getEnvironment());\nif (path != null) {adapter.setPath(path);}\nreturn adapter;\n}).forEach(adapter -\> {\nthis.endpoints.add(adapter);\n});";
}

//public test bool shouldRefactorToReduceWithPostIncrement() {
//	throw "Not yet implemented";
//
//	methodHeader = parse(#MethodHeader, "\<E\> ImmutableSortedMultiset\<E\> copyOfSortedEntries(Comparator\<? super E\> comparator, Collection\<Entry\<E\>\> entries)");
//  	methodBodyLoc = |project://rascal-Java8/testes/localVariables/MethodBodyReduceWithPostIncrement|;
//  	methodBody = parse(#MethodBody, readFile(methodBodyLoc));
//  	methodVars = findLocalVariables(methodHeader, methodBody);
//  	forStmt = parse(#EnhancedForStatement, "for (Entry\<E\> entry : entries) {\n      elementsBuilder.add(entry.getElement());\n      // cumulativeCounts[i + 1] = cumulativeCounts[i] + entry.getCount();\n      i++;\n    }");
//  	VariableDeclaratorId iteratedVarName = parse(#VariableDeclaratorId, "entry");
//	Expression collectionId = parse(#Expression, "entries");
//  	
//  	try {
//		refactoredStatement = buildRefactoredEnhancedFor(methodVars, forStmt, methodBody, iteratedVarName, collectionId);
//	} catch:
//		return true;
//		
//	return false;	 	
//}

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