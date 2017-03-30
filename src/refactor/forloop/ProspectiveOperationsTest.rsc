module refactor::forloop::ProspectiveOperationsTest

import refactor::forloop::ProspectiveOperation;
import refactor::forloop::ProspectiveOperationsTestResources;
import refactor::forloop::OperationType;
import MethodVar;
import lang::java::\syntax::Java18;
import IO;
import List;

public test bool shouldReturnAForEachOnSimpleShortExample() {
	tuple [set[MethodVar] vars, EnhancedForStatement loop] simpleShort = simpleShort();
	
	prospectiveOperations = retrieveProspectiveOperations(simpleShort.vars, simpleShort.loop);
	
	return size(prospectiveOperations) == 1 &&
		prospectiveOperations[0].stmt == "writer.write(thing);" &&
		prospectiveOperations[0].operation == FOR_EACH;
}

public test bool shouldReturnCorrectlyOnFilterMapReduceExample() {
	tuple [set[MethodVar] vars, EnhancedForStatement loop] filterMapReduce = filterMapReduce();
	
	prospectiveOperations = retrieveProspectiveOperations(filterMapReduce.vars, filterMapReduce.loop);
	
	return size(prospectiveOperations) == 2 && 
		prospectiveOperations[0].stmt == "rule.hasErrors()" &&
		prospectiveOperations[0].operation == FILTER &&
		prospectiveOperations[1].stmt == "count += rule.getErrors().size();" &&
		prospectiveOperations[1].operation == REDUCE;
}

//public test bool shouldReturnXOnContinueAndReturnEnhancedLoop() {
//	tuple [set[MethodVar] vars, EnhancedForStatement loop] continueAndReturn = continueAndReturn();
//	prospectiveOperations = retrievePotentialOperations(continueAndReturn.vars, continueAndReturn.loop);
//	println(prospectiveOperations);
//	return false;
//}

public test bool shouldReturnXOnFilterAndMergedForEach() {
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