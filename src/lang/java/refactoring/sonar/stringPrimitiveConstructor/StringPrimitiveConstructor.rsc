module lang::java::refactoring::sonar::stringPrimitiveConstructor::StringPrimitiveConstructor

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import lang::java::util::CompilationUnitUtils;
import String;

// TODO: BigInteger, BigDecimal, Byte, Character, Short
private set[str] classesToCheck = {"String", "Long", "Float", "Double", "Integer", "Boolean"};
//private set[str] classesToCheck = {"BigDecimal"};

public void stringPrimitiveConstructor(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			refactorStringPrimitiveConstructor(fileLoc);
		} catch: {
			println("Exception file: " + fileLoc.file);
			continue;
		}	
	}
}

public void refactorStringPrimitiveConstructor(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	unit = parse(#CompilationUnit, javaFileContent);
	
	unit = top-down visit(unit) {
		case (Expression) `new <Identifier typeInstantiated><TypeArgumentsOrDiamond? _>(<ArgumentList? arguments>)`: {
			classType = "<typeInstantiated>";
			args = "<arguments>";
			if (isViolation(classType, args)) {
				refactored = refactorViolation(classType, args);
				insert (Expression) `<Expression refactored>`;
			}
		}
		case (MethodInvocation) `<Primary possibleInstantiation> . <TypeArguments? ts> <Identifier id> (<ArgumentList? args>)`: {
			modified = false;
			possibleInstantiation = visit(possibleInstantiation) {
				case (Primary) `new <Identifier typeInstantiated><TypeArgumentsOrDiamond? _>(<ArgumentList? arguments>)`: {
					classType = "<typeInstantiated>";
					instantiationArgs = "<arguments>";
					if (isViolation(classType, instantiationArgs)) {
						refactored = refactorViolationAsPrimary(classType, instantiationArgs);
						modified = true;
						insert (Primary) `<Primary refactored>`;
					}
				}
			}
			if (modified)
				insert (MethodInvocation) `<Primary possibleInstantiation>.<TypeArguments? ts><Identifier id>(<ArgumentList? args>)`;
		}
	}
	
	writeFile(fileLoc, unit);
}

private bool isViolation(str typeInstantiated, str args) {
	if (typeInstantiated in classesToCheck) {
		if (typeInstantiated == "String") {
			return (isEmpty(args) || isOnlyOneArgument(args)) && findFirst(args, "\"") != -1;
		} else if(typeInstantiated == "BigDecimal") {
			return isOnlyOneArgument(args) && isNotCast(args) && findFirst(args, "\"") == -1 && findFirst(args, "BigInteger") == -1 && findFirst(args, "group()") == -1;
		} else {
			// maybe redundant since wrapper classes only have constructors with one argument
			// code wouldn´t compile at all
			// BigDecimal has more than one argument
			return isOnlyOneArgument(args) && isNotCast(args);
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

private bool isNotCast(str args) {
	try {
		parse(#CastExpression, args);
		return false;
	} catch:
		return true;
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

private Primary refactorViolationAsPrimary(str classType, str arg) {
	refactoredExp = refactorViolation(classType, arg);
	return parse(#Primary, "<refactoredExp>");
}