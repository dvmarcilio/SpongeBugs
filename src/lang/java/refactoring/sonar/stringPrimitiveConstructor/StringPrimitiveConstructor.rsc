module lang::java::refactoring::sonar::stringPrimitiveConstructor::StringPrimitiveConstructor

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import lang::java::util::CompilationUnitUtils;
import String;
import lang::java::util::GeneralUtils;
import lang::java::refactoring::forloop::MethodVar;
import lang::java::refactoring::forloop::LocalVariablesFinder;
import lang::java::refactoring::forloop::ClassFieldsFinder;

private set[str] classesToCheck = getPrimitiveWrappers() + "String";

private map[str, str] primitivesByWrappers = (
	"Float": "float",
	"Integer": "int",
	"Boolean": "boolean",
	"Short": "short",
	"Long": "long",
	"Double": "double",
	"Character": "char",
	"Byte": "byte"
);

private bool shouldRewrite = false;

public void stringPrimitiveConstructor(list[loc] locs) {
	for(fileLoc <- locs) {
		//try {
			refactorStringPrimitiveConstructor(fileLoc);
		//} catch: {
		//	println("Exception file: " + fileLoc.file);
		//	continue;
		//}	
	}
}

public void refactorStringPrimitiveConstructor(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	unit = parse(#CompilationUnit, javaFileContent);
	shouldRewrite = false;
	
	unit = top-down visit(unit) {
		case (Expression) `new <Identifier typeInstantiated><TypeArgumentsOrDiamond? _>(<ArgumentList? arguments>)`: {
			classType = "<typeInstantiated>";
			args = "<arguments>";
			if (isViolation(classType, args, unit)) {
				refactored = refactorViolation(classType, args, unit);
				shouldRewrite = true;
				insert (Expression) `<Expression refactored>`;
			}
		}
		case (MethodInvocation) `<Primary possibleInstantiation> . <TypeArguments? ts> <Identifier id> (<ArgumentList? args>)`: {
			modified = false;
			possibleInstantiation = visit(possibleInstantiation) {
				case (Primary) `new <Identifier typeInstantiated><TypeArgumentsOrDiamond? _>(<ArgumentList? arguments>)`: {
					classType = "<typeInstantiated>";
					instantiationArgs = "<arguments>";
					if (isViolation(classType, instantiationArgs, unit)) {
						refactored = refactorViolationAsPrimary(classType, instantiationArgs);
						modified = true;
						insert (Primary) `<Primary refactored>`;
					}
				}
			}
			if (modified) {
				shouldRewrite = true;
				insert (MethodInvocation) `<Primary possibleInstantiation>.<TypeArguments? ts><Identifier id>(<ArgumentList? args>)`;
			}
		}
		
		case (MethodDeclaration) `<MethodDeclaration mdl>`: {
			modified = false;
			mdl = visit(mdl) {
				case (Expression) `new <Identifier typeInstantiated><TypeArgumentsOrDiamond? _>(<ArgumentList? arguments>)`: {
					classType = "<typeInstantiated>";
					args = "<arguments>";
					if (isViolation(classType, args, unit, mdl)) {
						refactored = refactorViolation(classType, args);
						modified = true;
						insert (Expression) `<Expression refactored>`;
					}
				}
				case (MethodInvocation) `<Primary possibleInstantiation> . <TypeArguments? ts> <Identifier id> (<ArgumentList? args>)`: {
					possibleInstantiation = visit(possibleInstantiation) {
						case (Primary) `new <Identifier typeInstantiated><TypeArgumentsOrDiamond? _>(<ArgumentList? arguments>)`: {
							classType = "<typeInstantiated>";
							instantiationArgs = "<arguments>";
							if (isViolation(classType, instantiationArgs, unit, mdl)) {
								refactored = refactorViolationAsPrimary(classType, instantiationArgs);
								modified = true;
								insert (Primary) `<Primary refactored>`;
							}
						}
					}
					if (modified) {
						insert (MethodInvocation) `<Primary possibleInstantiation>.<TypeArguments? ts><Identifier id>(<ArgumentList? args>)`;
					}
				}				
			}
			if (modified) {
				shouldRewrite = true;
				insert mdl;
			}
		}
		
		
	}
	
	if (shouldRewrite) {
		writeFile(fileLoc, unit);
	}
}

private bool isViolation(str typeInstantiated, str args, CompilationUnit unit) {
	if (typeInstantiated in classesToCheck) {
		if (typeInstantiated == "String") {
			return (isEmpty(args) || isOnlyOneArgument(args)) && findFirst(args, "\"") != -1;
		} else if(typeInstantiated == "BigDecimal") {
			return isOnlyOneArgument(args) && isNotCast(args) && findFirst(args, "\"") == -1 && findFirst(args, "BigInteger") == -1 && findFirst(args, "group()") == -1;
		} else {
			return isOnlyOneArgument(args) && isNotCast(args) && isArgumentPrimitiveOfWrapper(typeInstantiated, args, unit);
		}
	}
	return false;
}

private bool isViolation(str typeInstantiated, str args, CompilationUnit unit, MethodDeclaration mdl) {
	if (typeInstantiated in classesToCheck) {
		if (typeInstantiated == "String") {
			return (isEmpty(args) || isOnlyOneArgument(args)) && findFirst(args, "\"") != -1;
		} else if(typeInstantiated == "BigDecimal") {
			return isOnlyOneArgument(args) && isNotCast(args) && findFirst(args, "\"") == -1 && findFirst(args, "BigInteger") == -1 && findFirst(args, "group()") == -1;
		} else {
			return isOnlyOneArgument(args) && isNotCast(args) && isArgumentPrimitiveOfWrapper(typeInstantiated, args, unit, mdl);
		}
	}
	return false;
}

private bool isArgumentPrimitiveOfWrapper(str typeInstantiated, str args, CompilationUnit unit) {
	str correctPrimitive = primitivesByWrappers[typeInstantiated];
	set[MethodVar] fields = findClassFields(unit);
	
	try {
		return isArgumentPrimitiveOfWrapper(correctPrimitive, typeInstantiated, args, fields);
	} catch: 
		return false;
}

private bool isArgumentPrimitiveOfWrapper(str correctPrimitive, str typeInstantiated, str possibleVar, set[MethodVar] avaialableVars) {
	MethodVar v = findByName(avaialableVars, possibleVar);
	return trim(v.varType) == correctPrimitive || trim(v.varType) == trim(typeInstantiated);
}

private bool isArgumentPrimitiveOfWrapper(str typeInstantiated, str args, CompilationUnit unit, MethodDeclaration mdl) {
	str correctPrimitive = primitivesByWrappers[typeInstantiated];
	set[MethodVar] fields = findClassFields(unit);
	set[MethodVar] localVars = findlocalVars(mdl);
	
	try {
		return isArgumentPrimitiveOfWrapper(correctPrimitive, typeInstantiated, args, fields + localVars);
	} catch: 
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