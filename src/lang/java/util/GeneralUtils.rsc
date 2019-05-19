module lang::java::util::GeneralUtils

private set[str] primitiveWrappers = {"Byte", "Character", "Short", "Integer", "Long", "Float", "Double", "Boolean"};
private set[str] primitives = {"byte", "short", "int", "long", "char", "float", "double", "boolean"};

public set[str] getPrimitiveWrappers() {
	return primitiveWrappers;
}

public set[str] getPrimitives() {
	return primitives;
}