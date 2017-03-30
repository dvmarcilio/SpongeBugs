module MethodVar

import Set;
import String;

// TODO Review if using a Set is the best choice. Probably not.
public data MethodVar = methodVar(bool isFinal, str name, str varType, bool isParameter, bool isDeclaredWithinLoop);
public data MethodVar = methodVar(bool isFinal, str name, str varType, bool isParameter, bool isDeclaredWithinLoop, bool isEffectiveFinal);

public bool isArray(MethodVar methodVar) {
	return methodVar.varType == "array";
}

public bool isParameter(MethodVar methodVar) {
	return !methodVar.isParameter;
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

public set[MethodVar] retrieveParameters(set[MethodVar] methodVars) {
	return { var | MethodVar var <- methodVars, var.isParameter };
}

public set[MethodVar] retrieveNonParameters(set[MethodVar] methodVars) {
	return { var | MethodVar var <- methodVars, !var.isParameter };
}

public set[str] retrieveParametersNames(set[MethodVar] methodVars) {
	return { var.name | MethodVar var <- methodVars, var.isParameter };
}

public set[str] retrieveNonParametersNames(set[MethodVar] methodVars) {
	return { var.name | MethodVar var <- methodVars, !var.isParameter };
}

public bool isTypePlainArray(MethodVar methodVar) {
	return endsWith(methodVar.varType, "[]");
}

public set[MethodVar] retrieveDeclaredWithinLoop(set[MethodVar] methodVars) {
	return { var | MethodVar var <- methodVars, var.isDeclaredWithinLoop };
}

public set[str] retrieveDeclaredWithinLoopNames(set[MethodVar] methodVars) {
	return { var.name | MethodVar var <- methodVars, var.isDeclaredWithinLoop };
}

public set[MethodVar] retrieveNotDeclaredWithinLoop(set[MethodVar] methodVars) {
	return { var | MethodVar var <- methodVars, !var.isDeclaredWithinLoop };
}

public set[str] retrieveNotDeclaredWithinLoopNames(set[MethodVar] methodVars) {
	return { var.name | MethodVar var <- methodVars, !var.isDeclaredWithinLoop };
}

// FIXME
public bool isEffectiveFinal(MethodVar methodVar) {
	try
		return methodVar.isFinal || methodVar.isEffectiveFinal;
	catch NoSuchField("isEffectiveFinal"):
		return methodVar.isFinal;
}