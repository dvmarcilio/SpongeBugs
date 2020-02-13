module lang::java::refactoring::forloop::MethodVar

import Set;
import String;
import lang::java::util::GeneralUtils;

// TODO Review if using a Set is the best choice. Probably not.
public data MethodVar = methodVar(bool isFinal, str name, str varType, bool isParameter, 
	bool isDeclaredWithinLoop, bool isEffectiveFinal, bool isField);

private set[str] collections = {"List", "ArrayList", "LinkedList", "Set", "HashSet", "LinkedHashSet",
	 "TreeSet", "Queue", "Stack", "SortedSet", "EnumSet", "ArrayDeque", "ConcurrentLinkedDeque", "ConcurrentLinkedQueue",
	 "Vector", "Deque", "NavigableSet", "Collection"};

public bool isArray(MethodVar methodVar) {
	return trim(methodVar.varType) == "array";
}

public bool isString(MethodVar methodVar) {
	return trim(methodVar.varType) == "String";
}

public bool isInteger(MethodVar methodVar) {
	varType = trim(methodVar.varType);
	return varType == "int" || varType == "Integer"; 
}

public bool isDouble(MethodVar methodVar) {
	varType = trim(methodVar.varType);
	return varType == "double" || varType == "Double"; 
}

public bool isFloat(MethodVar methodVar) {
	varType = trim(methodVar.varType);
	return varType == "float" || varType == "Float";
}

public bool isNumber(MethodVar methodVar) {
	varType = trim(methodVar.varType);
	return varType == "Number";
}

// fragile
public bool isIterable(MethodVar methodVar) {
	varType = trim(methodVar.varType);
	return startsWith(varType, "Iterable");
}

// FIXME? really?
public bool isParameter(MethodVar methodVar) {
	return !methodVar.isParameter;
}

// We might miss some
public bool isCollection(MethodVar methodVar) {
	varType = removeGenericsFromVarType(methodVar.varType);
	if (varType in collections)
		return true;
	
	return false;
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
	try {
		return getOneFrom({ var | MethodVar var <- methodVars, var.name == name });
	} catch EmptySet():
		return findByNameField(methodVars, name);
}

private MethodVar findByNameField(set[MethodVar] methodVars, str name) {
	str fieldPrefix = "this.";
	if (startsWith(name, fieldPrefix)) {
		fieldName = substring(name, size(fieldPrefix));
		return getOneFrom({ var | MethodVar var <- methodVars, var.name == fieldName });
	}
	throw EmptySet();
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

public bool isEffectiveFinal(MethodVar methodVar) {
	return methodVar.isFinal || methodVar.isEffectiveFinal;
}

// FIXME This will break if 'this.varName' is referenced, as we are removing the class field
// Would need to treat 'this.*' and change how we find vars by name
// One idea is to keep both localVariables AND classFields as separate lists.
// if both exists, a reference to a field can only be made by 'this.field'
public set[MethodVar] retainLocalVariablesIfDuplicates(set[MethodVar] classFields, set[MethodVar] localVars) {
	duplicatedNames = retrieveAllNames(classFields) & retrieveAllNames(localVars);
	duplicatedClassFields = { field | MethodVar field <- classFields, field.name in duplicatedNames };
	return (classFields - duplicatedClassFields) + localVars;
}

public set[str] retrieveAllNames(set[MethodVar] vars) {
	return { var.name | MethodVar var <- vars };
}