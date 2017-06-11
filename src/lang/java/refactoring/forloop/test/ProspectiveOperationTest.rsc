module lang::java::refactoring::forloop::\test::ProspectiveOperationTest

import lang::java::\syntax::Java18;
import IO;
import List;
import lang::java::refactoring::forloop::ProspectiveOperation;
import lang::java::refactoring::forloop::\test::resources::ProspectiveOperationTestResources;
import lang::java::refactoring::forloop::OperationType;
import lang::java::refactoring::forloop::MethodVar;

public test bool shouldReturnAForEachOnSimpleShortExample() {
	tuple [set[MethodVar] vars, EnhancedForStatement loop] simpleShort = simpleShort();
	
	prospectiveOperations = retrieveProspectiveOperations(simpleShort.vars, simpleShort.loop);
	
	return size(prospectiveOperations) == 1 &&
		prospectiveOperations[0].stmt == "writer.write(thing);" &&
		prospectiveOperations[0].operation == FOR_EACH;
}

public test bool shouldHandleReduce() {
	tuple [set[MethodVar] vars, EnhancedForStatement loop] filterMapReduce = filterMapReduce();
	
	prospectiveOperations = retrieveProspectiveOperations(filterMapReduce.vars, filterMapReduce.loop);
	
	return size(prospectiveOperations) == 2 && 
		prospectiveOperations[0].stmt == "rule.hasErrors()" &&
		prospectiveOperations[0].operation == FILTER &&
		prospectiveOperations[1].stmt == "count += rule.getErrors().size();" &&
		prospectiveOperations[1].operation == REDUCE;
}

public test bool shouldHandleAnyMatch() {
	tuple [set[MethodVar] vars, EnhancedForStatement loop] continueAndReturn = continueAndReturn();
	
	prospectiveOperations = retrieveProspectiveOperations(continueAndReturn.vars, continueAndReturn.loop);
	
	return prospectiveOperations[1].stmt == "e.getGrammarName().equals(grammarName)" &&
		prospectiveOperations[1].operation == ANY_MATCH;
}

public test bool shouldSeparateAndChooseCorrectOperationsOnMultipleStatements() {
	tuple [set[MethodVar] vars, EnhancedForStatement loop] filterAndMergedForEach = filterAndMergedForEach();
	
	prospectiveOperations = retrieveProspectiveOperations(filterAndMergedForEach.vars, filterAndMergedForEach.loop);
	
	return size(prospectiveOperations) == 4 &&
		prospectiveOperations[0].stmt == "isValid(entry)" &&
		prospectiveOperations[0].operation == FILTER &&
		prospectiveOperations[1].stmt == "ClassLoader cl = entry.getKey();" &&
		prospectiveOperations[1].operation == MAP &&
		prospectiveOperations[2].stmt == "!((WebappClassLoader)cl).isStart()" &&
		prospectiveOperations[2].operation == FILTER &&
		prospectiveOperations[3].stmt == "result.add(entry.getValue());" &&
		prospectiveOperations[3].operation == FOR_EACH;
}

public test bool shouldSeparateAndChooseCorrectOperationsOnMultipleMapsEndingWithAReduce() {
	tuple [set[MethodVar] vars, EnhancedForStatement loop] multipleMapsAndEndingReducer = multipleMapsAndEndingReducer();
	
	prospectiveOperations = retrieveProspectiveOperations(multipleMapsAndEndingReducer.vars, multipleMapsAndEndingReducer.loop);
	
	return size(prospectiveOperations) == 5 &&
		prospectiveOperations[0].stmt == "assertTrue(map.containsKey(entry.getKey()));" &&
		prospectiveOperations[0].operation == MAP &&
		prospectiveOperations[1].stmt == "assertTrue(map.containsValue(entry.getValue()));" &&
		prospectiveOperations[1].operation == MAP &&
		prospectiveOperations[2].stmt == "int expectedHash =\r\n            (entry.getKey() == null ? 0 : entry.getKey().hashCode())\r\n                ^ (entry.getValue() == null ? 0 : entry.getValue().hashCode());" &&
		prospectiveOperations[2].operation == MAP &&
		prospectiveOperations[3].stmt == "assertEquals(expectedHash, entry.hashCode());" &&
		prospectiveOperations[3].operation == MAP &&
		prospectiveOperations[4].stmt == "expectedEntrySetHash += expectedHash;" &&
		prospectiveOperations[4].operation == REDUCE;
}

public test bool shouldThrowExceptionWhenInnerLoopIsFound() {
	tuple [set[MethodVar] vars, EnhancedForStatement loop] innerLoop = innerLoop1();
	
	try {
		prospectiveOperations = retrieveProspectiveOperations(innerLoop.vars, innerLoop.loop);
	} catch:
		return true;
	
	return false;
}

public test bool shouldThrowExceptionWhenAnotherInnerLoopIsFound() {
	tuple [set[MethodVar] vars, EnhancedForStatement loop] innerLoop = innerLoop2();
	
	try {
		prospectiveOperations = retrieveProspectiveOperations(innerLoop.vars, innerLoop.loop);
	} catch:
		return true;
	
	return false;
}

public test bool shouldThrowExceptionWhenLoopWithInnerWhileIsFound() {
	tuple [set[MethodVar] vars, EnhancedForStatement loop] loopWithInnerWhile = loopWithInnerWhile();
	
	try {
		prospectiveOperations = retrieveProspectiveOperations(loopWithInnerWhile.vars, loopWithInnerWhile.loop);
	} catch:
		return true;
	
	return false;
}

public test bool ifAsNotTheLastStatementShouldBeAMap() {
	tuple [set[MethodVar] vars, EnhancedForStatement loop] loopWithThrowStatement = loopWithThrowStatement();

	prospectiveOperations = retrieveProspectiveOperations(loopWithThrowStatement.vars, loopWithThrowStatement.loop);
	
	return size(prospectiveOperations) == 3 &&
		prospectiveOperations[0].stmt == "V value = newEntries.get(key);" &&
		prospectiveOperations[0].operation == MAP &&
		prospectiveOperations[1].stmt == "if (value == null) {\n              throw new InvalidCacheLoadException(\"loadAll failed to return a value for \" + key);\n            }" &&
		prospectiveOperations[1].operation == MAP &&
		prospectiveOperations[2].stmt == "result.put(key, value);" &&
		prospectiveOperations[2].operation == FOR_EACH;
}

// This is actually a really nice example.
// The first if is a filter because it is the last statement from the outer block
// The inner if is not the last statement within the first if block, so it's a map
public test bool innerIfAsNotTheLastStatementShouldBeAMap() {
	tuple [set[MethodVar] vars, EnhancedForStatement loop] loop = loopWithIfWithTwoStatementsInsideBlock();

	prospectiveOperations = retrieveProspectiveOperations(loop.vars, loop.loop);
	
	return size(prospectiveOperations) == 5 &&
		prospectiveOperations[0].stmt == "isIncluded(endpoint)" &&
		prospectiveOperations[0].operation == FILTER &&
		prospectiveOperations[1].stmt == "String path = endpointHandlerMapping.getPath(endpoint.getPath());" &&
		prospectiveOperations[1].operation == MAP &&
		prospectiveOperations[2].stmt == "paths.add(path);" &&
		prospectiveOperations[2].operation == MAP &&
		prospectiveOperations[3].stmt == "if (!path.equals(\"\")) {\r\n\t\t\t\t\t\tpaths.add(path + \"/**\");\r\n\t\t\t\t\t\t// Add Spring MVC-generated additional paths\r\n\t\t\t\t\t\tpaths.add(path + \".*\");\r\n\t\t\t\t\t}" &&
		prospectiveOperations[3].operation == MAP &&
		prospectiveOperations[4].stmt == "paths.add(path + \"/\");" &&
		prospectiveOperations[4].operation == FOR_EACH;
}

public test bool shouldThrowExceptionOnLoopWithInnerLoop() {
	tuple [set[MethodVar] vars, EnhancedForStatement loop] loop = outerLoopWithInnerLoop();
	
	try {
		prospectiveOperations = retrieveProspectiveOperations(loop.vars, loop.loop);
		return false;
	} catch:
		return true;
	
}

//public test bool shouldIdentifyPostIncrementAsReduce() {
//	throw "Not yet implemented";
//	
//	tuple [set[MethodVar] vars, EnhancedForStatement loop] loopReduceWithPostIncrement = loopReduceWithPostIncrement();
//
//	prospectiveOperations = retrieveProspectiveOperations(loopReduceWithPostIncrement.vars, loopReduceWithPostIncrement.loop);
//	
//	println(prospectiveOperations);
//	
//	return false;
//}

//public test bool shouldHandleAnyMatchAndIfWithContinue() {
//	tuple [set[MethodVar] vars, EnhancedForStatement loop] continueAndReturn = continueAndReturn();
//	
//	prospectiveOperations = retrieveProspectiveOperations(continueAndReturn.vars, continueAndReturn.loop);
//	println(prospectiveOperations);
//	
//	return size(prospectiveOperations) == 2 && 
//		prospectiveOperations[0].stmt == "e.getGrammarName() != null" &&
//		prospectiveOperations[0].operation == FILTER &&
//		prospectiveOperations[1].stmt == "e.getGrammarName().equals(grammarName)" &&
//		prospectiveOperations[1].operation == ANY_MATCH;
//}
//
//public test bool shouldHandleIfWithContinue() {
//	tuple [set[MethodVar] vars, EnhancedForStatement loop] continueAndReturn = continueAndReturn();
//	
//	prospectiveOperations = retrieveProspectiveOperations(continueAndReturn.vars, continueAndReturn.loop);
//	println(prospectiveOperations);
//	
//	return prospectiveOperations[0].stmt == "e.getGrammarName() != null" &&
//		prospectiveOperations[0].operation == FILTER;
//}