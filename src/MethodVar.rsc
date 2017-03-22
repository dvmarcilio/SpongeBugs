module MethodVar

public data MethodVar = methodVar(bool isFinal, str name, str varType, bool isLocal);

public bool isArray(MethodVar methodVar) {
	return methodVar.varType == "array";
}

public bool isParameter(MethodVar methodVar) {
	return !methodVar.isLocal;
} 

// may be improved. O(n) right now.
public set[MethodVar] retrieveFinals(set[MethodVar] methodVars) {
	return { var | MethodVar var <- methodVars, var.isFinal };
}

// may be improved. O(n) right now.
public set[MethodVar] retrieveNonFinals(set[MethodVar] methodVars) {
	return { var | MethodVar var <- methodVars, !var.isFinal };
}

public set[str] retrieveFinalsNames(set[MethodVar] methodVars) {
	return { var.name | MethodVar var <- methodVars, var.isFinal };
}

public set[str] retrieveNonFinalsNames(set[MethodVar] methodVars) {
	return { var.name | MethodVar var <- methodVars, !var.isFinal };
}