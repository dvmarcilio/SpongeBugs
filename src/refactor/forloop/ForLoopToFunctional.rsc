module refactor::forloop::ForLoopToFunctional

import lang::java::\syntax::Java18;
import ParseTree;
import IO;
import refactor::forloop::ProspectiveOperation;
import List;
import MethodVar;

public void refactorEnhancedToFunctional(EnhancedForStatement forStmt, set[MethodVar] methodVars) {
	prospectiveOperations = retrieveProspectiveOperations(methodVars, forStmt);
	println(mergeOperations(prospectiveOperations, methodVars));
}

private list[ProspectiveOperation] mergeOperations(list[ProspectiveOperation] prOps, set[MethodVar] methodVars) {
	println("mergeOperations()");
	listIndexes = [0 .. size(prOps)];
	// iterating bottom-up
	for (int i <- reverse(listIndexes)) {
		curr = prOps[i];
		prev = prOps[i - 1];
		if (!areComposable(curr, prev, methodVars)) {
			if (isMergeable(prev) && isMergeable(curr)) {
				if (isFilter(prev) || isFilter(curr)) {
					opsSize = size(prOps); 
					while(opsSize > i) {
						last = prOps[opsSize - 1];
						beforeLast = prOps[opsSize - 2];
						merged = mergeOps(beforeLast, last, methodVars);
						prOps = slice(prOps, 0, opsSize - 2) + merged;
					}
				} else {
					merged = mergeOps(prev, curr);
					prOps = slice(prOps, 0, opsSize - 2) + merged;
				}
			}
		}
	}
	return prOps;
}