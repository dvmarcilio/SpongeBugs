module lang::java::util::GeneralUtils

private set[str] primitiveWrappers = {"Byte", "Character", "Short", "Integer", "Long", "Float", "Double", "Boolean"};

public set[str] getPrimitiveWrappers() {
	return primitiveWrappers;
}