module MethodVar

import Set;
import String;

// TODO Review if using a Set is the best choice. Probably not.
public data MethodVar = methodVar(bool isFinal, str name, str varType, bool isLocal);

public bool isArray(MethodVar methodVar) {
	return methodVar.varType == "array";
}

public bool isParameter(MethodVar methodVar) {
	return !methodVar.isLocal;
} 

public set[MethodVar] retrieveFinals(set[MethodVar] methodVars) {
	return { var | MethodVar var <- methodVars, var.isFinal };
}

public set[MethodVar] retrieveNonFinals(set[MethodVar] methodVars) {
	return { var | MethodVar var <- methodVars, !var.isFinal };
}

public set[str] retrieveFinalsNames(set[MethodVar] methodVars) {
	return { var.name | MethodVar var <- methodVars, var.isFinal };
}

public set[str] retrieveNonFinalsNames(set[MethodVar] methodVars) {
	return { var.name | MethodVar var <- methodVars, !var.isFinal };
}

public MethodVar findByName(set[MethodVar] methodVars, str name) {
	return getOneFrom({ var | MethodVar var <- methodVars, var.name == name });
}

public bool isTypePlainArray(MethodVar methodVar) {
	return endsWith(methodVar.varType, "[]");
}