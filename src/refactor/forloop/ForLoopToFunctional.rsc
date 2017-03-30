module refactor::forloop::ForLoopToFunctional

import lang::java::\syntax::Java18;
import ParseTree;
import IO;
import refactor::forloop::ProspectiveOperation;
import List;
import MethodVar;

public void refactorEnhancedToFunctional(set[MethodVar] methodVars, EnhancedForStatement forStmt) {
	prospectiveOperations = retrieveProspectiveOperations(methodVars, forStmt);
	println(mergeOperations(prospectiveOperations, methodVars));
}

private list[ProspectiveOperation] mergeOperations(list[ProspectiveOperation] prOps, set[MethodVar] methodVars) {	
	// we don't want the first element (index 0)
	listIndexes = [1 .. size(prOps)];
	// iterating bottom-up
	for (int i <- reverse(listIndexes)) {
		curr = prOps[i];
		prev = prOps[i - 1];
		if (!areComposable(curr, prev, methodVars)) {
			if (isMergeable(prev) && isMergeable(curr)) {
				opsSize = size(prOps); 
				
				if (isFilter(prev) || isFilter(curr)) {
					while(opsSize > i) {
						ProspectiveOperation last = prOps[opsSize - 1];
						ProspectiveOperation beforeLast = prOps[opsSize - 2];
						merged = mergeOps(beforeLast, last, methodVars);
						prOps = slice(prOps, 0, opsSize - 2) + merged;
						
						opsSize = size(prOps);
					}
				} else {
					merged = mergeOps(prev, curr, methodVars);
					prOps = slice(prOps, 0, opsSize - 2) + merged;
				}
			}
		}
	}
	return prOps;
}