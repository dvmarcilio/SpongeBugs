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
import lang::java::refactoring::sonar::LogUtils;
import lang::java::util::MethodDeclarationUtils;

private set[str] classesToCheck = getPrimitiveWrappers() + "String" + "BigDecimal";

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

private bool shouldWriteLog = false;

private loc logPath;

private str detailedLogFileName = "WRAPPERS_CONSTRUCTORS_DETAILED.txt";
private str countLogFileName = "WRAPPERS_CONSTRUCTORS_COUNT.txt";

private map[str, int] timesReplacedByScope = ();

public void stringPrimitiveConstructor(list[loc] locs, loc logPathArg) {
	shouldWriteLog = true;
	logPath = logPathArg;
	doStringPrimitiveConstructor(locs);
}

public void refactorStringPrimitiveConstructor(loc fileLoc) {
	shouldWriteLog = false;
	doRefactorStringPrimitiveConstructor(fileLoc);
}

public void refactorStringPrimitiveConstructor(loc fileLoc, loc logPathArg) {
	shouldWriteLog = true;
	logPath = logPathArg;
	doRefactorStringPrimitiveConstructor(fileLoc);
}

public void stringPrimitiveConstructor(list[loc] locs) {
	shouldWriteLog = false;
	doStringPrimitiveConstructor(locs);
}

private void doStringPrimitiveConstructor(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			doRefactorStringPrimitiveConstructor(fileLoc);
		} catch: {
			println("Exception file (StringPrimitiveConstructor): " + fileLoc.file);
			continue;
		}	
	}
}

private void doRefactorStringPrimitiveConstructor(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	unit = parse(#CompilationUnit, javaFileContent);
	shouldRewrite = false;
	
	// TODO find fields
	timesReplacedByScope = ();
	
	unit = top-down visit(unit) {
		case (Expression) `new <Identifier typeInstantiated><TypeArgumentsOrDiamond? _>(<ArgumentList? arguments>)`: {
			classType = "<typeInstantiated>";
			args = "<arguments>";
			if (isViolation(classType, args, unit)) {
				refactored = refactorViolation("<classType>", "<args>");
				shouldRewrite = true;
				countModificationForLog("outside of method");
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
						countModificationForLog("outside of method");
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
			methodSignature = retrieveMethodSignature(mdl);
			
			// TODO find methodVars
			
			mdl = visit(mdl) {
				case (Expression) `new <Identifier typeInstantiated><TypeArgumentsOrDiamond? _>(<ArgumentList? arguments>)`: {
					classType = "<typeInstantiated>";
					args = "<arguments>";
					if (isViolation(classType, args, unit, mdl)) {
						refactored = refactorViolation(classType, args);
						modified = true;
						countModificationForLog(methodSignature);
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
								countModificationForLog(methodSignature);
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
		writeLog(fileLoc, logPath, detailedLogFileName, countLogFileName, timesReplacedByScope);
	}
}

private bool isViolation(str typeInstantiated, str args, CompilationUnit unit) {
	if (typeInstantiated in classesToCheck) {
		if (typeInstantiated == "String") {
			return (isEmpty(args) || isOnlyOneArgument(args)) && findFirst(args, "\"") != -1;
		} else if(typeInstantiated == "BigDecimal") {
			return isOnlyOneArgument(args) && isNotCast(args) && findFirst(args, "\"") == -1 &&
				 findFirst(args, "BigInteger") == -1 && findFirst(args, "group()") == -1;
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
			return isOnlyOneArgument(args) && isNotCast(args) && findFirst(args, "\"") == -1 &&
			 	findFirst(args, "BigInteger") == -1 && findFirst(args, "group()") == -1;
		} else {
			return isOnlyOneArgument(args) && isNotCast(args) && isArgumentPrimitiveOfWrapper(typeInstantiated, args, unit, mdl);
		}
	}
	return false;
}

// TODO: need to rethink this 
private bool canRefactorBigDecimal(str args, CompilationUnit unit) {
	set[MethodVar] fields = findClassFields(unit);
	
	try {
		return !isArgumentFromMethodVarsAString(args, fields);
	} catch:
		return false; // being over cautious
}

// TODO: need to rethink this
private bool canRefactorBigDecimal(str args, CompilationUnit unit, MethodDeclaration mdl) {
	set[MethodVar] fields = findClassFields(unit);
	set[MethodVar] localVars = findlocalVars(mdl);
	
	try {
		return !isArgumentFromMethodVarsAString(args, fields + localVars);
	} catch: 
		return false; // being over cautious
}

private bool isArgumentFromMethodVarsAString(str args, set[MethodVar] availableVars) {
	MethodVar v = findByName(availableVars, trim(args));
	return trim(v.varType) == "String";
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

private void countModificationForLog(str scope) {
	if (scope in timesReplacedByScope) {
		timesReplacedByScope[scope] += 1;
	} else { 
		timesReplacedByScope[scope] = 1;
	}
}