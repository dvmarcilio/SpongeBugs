module lang::java::util::GeneralUtils

import String;

private set[str] primitiveWrappers = {"Byte", "Character", "Short", "Integer", "Long", "Float", "Double", "Boolean"};
private set[str] primitives = {"byte", "short", "int", "long", "char", "float", "double", "boolean"};

public set[str] getPrimitiveWrappers() {
	return primitiveWrappers;
}

public set[str] getPrimitives() {
	return primitives;
}

public str removeGenericsFromVarType(str varType) {
	firstIndex = findFirst(varType, "\<");
	lastIndex = findLast(varType, "\>");
	if (firstIndex != -1 && lastIndex != -1) {
		return trim(substring(varType, 0, firstIndex) + substring(varType, lastIndex + 1));
	} else {
		return varType;
	}
}