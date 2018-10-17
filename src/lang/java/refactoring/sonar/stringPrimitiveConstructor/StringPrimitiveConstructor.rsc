module lang::java::refactoring::sonar::stringPrimitiveConstructor::StringPrimitiveConstructor

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import lang::java::util::CompilationUnitUtils;
import lang::java::analysis::ParseTreeVisualization;
import String;

// TODO: BigInteger, BigDecimal, Byte, Character, Short
private set[str] classesToCheck = {"String", "Long", "Float", "Double", "Integer", "Boolean"};

public void refactorStringPrimitiveConstructor(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	unit = parse(#CompilationUnit, javaFileContent);
	
	//visualize(unit);
	
	unit = top-down visit(unit) {
		case (Expression) `new <Identifier typeInstantiated><TypeArgumentsOrDiamond? _>(<ArgumentList? arguments>)`: {
			classType = "<typeInstantiated>";
			args = "<arguments>";
			if (isViolation(classType, args)) {
				refactored = refactorViolation(classType, args);
				insert (Expression) `<Expression refactored>`;
			}
		}
	}
	
	writeFile(fileLoc, unit);
}

private bool isViolation(str typeInstantiated, str args) {
	if (typeInstantiated in classesToCheck) {
		if (typeInstantiated == "String") {
			return isEmpty(args) || isOnlyOneArgument(args); 
		} else {
			// maybe redundant since wrapper classes only have constructors with one argument
			// code wouldn´t compile at all
			return isOnlyOneArgument(args);
		}
	}
	return false;
}


// FIXME Fails HARD on strings, as string with "," would return false
private bool isOnlyOneArgument(str args) {
	if(!isEmpty(args)) {
		return !contains(args, ",");
	}
	return false;
}

private Expression refactorViolation(str classType, str arg) {
	if(classType == "String") {
		return refactorStringViolation(arg);
	} else {
		return refactorNonStringViolation(classType, arg);
	}
}

private Expression refactorStringViolation(str arg) {
	if (isEmpty(arg))
		arg = "\"\"";
	return parse(#Expression, "<arg>");
}

private Expression refactorNonStringViolation(str classType, str arg) {
	return parse(#Expression, "<classType>.valueOf(<arg>)");
}