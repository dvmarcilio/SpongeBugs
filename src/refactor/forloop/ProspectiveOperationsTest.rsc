module refactor::forloop::ProspectiveOperationsTest

import refactor::forloop::ProspectiveOperation;
import refactor::forloop::ProspectiveOperationsTestResources;
import MethodVar;
import lang::java::\syntax::Java18;
import IO;

public test bool shouldReturnAForEachOnSimpleShortExample() {
	tuple [set[MethodVar] vars, EnhancedForStatement loop] simpleShort = simpleShort();
	prospectiveOperations = retrievePotentialOperations(simpleShort.vars, simpleShort.loop);
	return prospectiveOperations[0].stmt == "writer.write(thing);" &&
		prospectiveOperations[0].operation == "forEach";
}

public test bool shouldReturnCorrectlyOnFilterMapReduceExample() {
	tuple [set[MethodVar] vars, EnhancedForStatement loop] filterMapReduce = filterMapReduce();
	prospectiveOperations = retrievePotentialOperations(filterMapReduce.vars, filterMapReduce.loop);
	return prospectiveOperations[0].stmt == "rule.hasErrors()" &&
		prospectiveOperations[0].operation == "filter" &&
		prospectiveOperations[1].stmt == "count += rule.getErrors().size();" &&
		prospectiveOperations[1].operation == "reduce";
}

//public test bool shouldReturnXOnContinueAndReturnEnhancedLoop() {
//	tuple [set[MethodVar] vars, EnhancedForStatement loop] continueAndReturn = continueAndReturn();
//	prospectiveOperations = retrievePotentialOperations(continueAndReturn.vars, continueAndReturn.loop);
//	println(prospectiveOperations);
//	return false;
//}