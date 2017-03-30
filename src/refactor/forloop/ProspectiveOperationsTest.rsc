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