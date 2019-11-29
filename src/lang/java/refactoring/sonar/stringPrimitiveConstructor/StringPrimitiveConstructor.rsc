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
	
	javaFileContent = readFile(fileLoc);
	unit = parse(#CompilationUnit, javaFileContent);
	doRefactorStringPrimitiveConstructor(fileLoc, unit);
}

public void refactorStringPrimitiveConstructor(loc fileLoc, loc logPathArg) {
	shouldWriteLog = true;
	logPath = logPathArg;
	
	javaFileContent = readFile(fileLoc);
	unit = parse(#CompilationUnit, javaFileContent);
	doRefactorStringPrimitiveConstructor(fileLoc, unit);
}

public void stringPrimitiveConstructor(list[loc] locs) {
	shouldWriteLog = false;
	doStringPrimitiveConstructor(locs);
}

private void doStringPrimitiveConstructor(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			javaFileContent = readFile(fileLoc);
			unit = parse(#CompilationUnit, javaFileContent);
			doRefactorStringPrimitiveConstructor(fileLoc, unit);
		} catch: {
			println("Exception file (StringPrimitiveConstructor): " + fileLoc.file);
			continue;
		}	
	}
}

private void doStringPrimitiveConstructor(loc fileLoc, CompilationUnit unit) {
	//if (shouldAnalyzeFile(unit))
	doRefactorStringPrimitiveConstructor(fileLoc, unit);
}

// we need to measure how long it takes with and without
private bool shouldAnalyzeFile(CompilationUnit unit) {
	unitStr = "<unit>";
	for (classToCheck <- classesToCheck) {
		if (findFirst(unitStr, "new <classToCheck>(") != -1)
			return true;
	}	
	return false;
}

private void doRefactorStringPrimitiveConstructor(loc fileLoc, CompilationUnit unit) {
	try {
		reallyDoRefactorStringPrimitiveConstructor(fileLoc, unit);
	} catch:
		println("Exception file (StringPrimitiveConstructor): " + fileLoc.file);
}

private void reallyDoRefactorStringPrimitiveConstructor(loc fileLoc, CompilationUnit unit) {
	shouldRewrite = false;
	
	timesReplacedByScope = ();
	
	unit = top-down visit(unit) {
		case (MethodDeclaration) `<MethodDeclaration mdl>`: {
			modified = false;
			methodSignature = retrieveMethodSignature(mdl);
			
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
						case (Expression) `new <Identifier typeInstantiated><TypeArgumentsOrDiamond? _>(<ArgumentList? arguments>)`: {
							classType = "<typeInstantiated>";
							instantiationArgs = "<arguments>";
							if (isViolation(classType, instantiationArgs, unit, mdl)) {
								refactored = refactorViolationAsExpression(classType, instantiationArgs);
								modified = true;
								countModificationForLog(methodSignature);
								insert (Expression) `<Primary refactored>`;
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
		
		case (MethodInvocation) `<MethodInvocation mi>`: {
			mi = top-down-break visit(mi) {
				case (MethodInvocation) `<Primary possibleInstantiation> . <TypeArguments? ts> <Identifier id> (<ArgumentList? args>)`: {
					miModified = false;
					possibleInstantiation = visit(possibleInstantiation) {
						case (Expression) `new <Identifier typeInstantiated><TypeArgumentsOrDiamond? _>(<ArgumentList? arguments>)`: {
							classType = "<typeInstantiated>";
							instantiationArgs = "<arguments>";
							if (isViolation(classType, instantiationArgs, unit)) {
								refactored = refactorViolationAsExpression(classType, instantiationArgs);
								modified = true;
								miModified = true;
								insert (Expression) `<Primary refactored>`;
							}
						}
					}
					if (miModified) {
						insert mi;
					}
				}
			}
		}	
	}
	
	
	if (shouldRewrite) {
		writeFile(fileLoc, unit);
		//doWriteLog(fileLoc);
	}
}

private bool isViolation(str typeInstantiated, str args, CompilationUnit unit) {
	if (trim(typeInstantiated) in classesToCheck) {
		if (typeInstantiated == "String") {
			return (isEmpty(args) || isOnlyOneArgument(args)) && findFirst(args, "\"") != -1;
		} else if(typeInstantiated == "BigDecimal") {
			return isOnlyOneArgument(args) && isNotCast(args) && canRefactorBigDecimal(args, unit);
		} else {
			return isOnlyOneArgument(args) && isNotCast(args) && isArgumentPrimitiveOfWrapper(typeInstantiated, args, unit);
		}
	}
	return false;
}

private bool isViolation(str typeInstantiated, str args, CompilationUnit unit, MethodDeclaration mdl) {
	if (trim(typeInstantiated) in classesToCheck) {
		if (typeInstantiated == "String") {
			return (isEmpty(args) || isOnlyOneArgument(args)) && findFirst(args, "\"") != -1;
		} else if(typeInstantiated == "BigDecimal") {
			return isOnlyOneArgument(args) && isNotCast(args) && canRefactorBigDecimal(args, unit, mdl);
		} else {
			return isOnlyOneArgument(args) && isNotCast(args) && isArgumentPrimitiveOfWrapper(typeInstantiated, args, unit, mdl);
		}
	}
	return false;
}

private bool canRefactorBigDecimal(str args, CompilationUnit unit) {
	set[MethodVar] fields = findClassFields(unit);
	
	return isDoubleOrFloatConstants(args) || 
		isVarADoubleOrFloat(args, fields) ||
		isANumberCallingDoubleOrFloatValue(args, fields);
}

private bool isVarADoubleOrFloat(str varName, set[MethodVar] availableVars) {
	try {
		return isArgumentFromMethodVarsADoubleOrFloat(varName, availableVars);
	} catch: { 
		return false;	
	}
}

private bool isArgumentFromMethodVarsADoubleOrFloat(str args, set[MethodVar] availableVars) {
	MethodVar methodVar = findByName(availableVars, trim(args));
	return isDouble(methodVar) || isFloat(methodVar);
}

private bool isANumberCallingDoubleOrFloatValue(str args, set[MethodVar] availableVars) {
	try {
		return checkIfIsANumberCallingDoubleOrFloatValue(args, availableVars);
	} catch:
		return false;
}

private bool checkIfIsANumberCallingDoubleOrFloatValue(str args, set[MethodVar] availableVars) {
	MethodInvocation mi = parse(#MethodInvocation, args);
	visit(mi) {
		case (MethodInvocation) `<ExpressionName varName>.doubleValue()`: {
			MethodVar possibleNumberVar = findByName(availableVars, "<varName>");
			return isNumber(possibleNumberVar);
		}
		case (MethodInvocation) `<ExpressionName varName>.floatValue()`: {
			MethodVar possibleNumberVar = findByName(availableVars, "<varName>");
			return isNumber(possibleNumberVar);
		}
	}
	return false;
}

private bool isDoubleOrFloatConstants(str args) {
	args = trim(args);
	list[str] classes = ["Double", "Float"];
	list[str] constants = [
		"POSITIVE_INFINITY", "NEGATIVE_INFINITY", "NaN", 
		"MAX_VALUE", "MIN_NORMAL", "MIN_VALUE"
		];
		
	for (class <- classes) {
		for (constant <- constants) {
			if(args == "<class>.<constant>" || args == "-<class>.<constant>") {
				return true;
			}		
		}
	}
	
	return false;
}

private bool canRefactorBigDecimal(str args, CompilationUnit unit, MethodDeclaration mdl) {
	set[MethodVar] fields = findClassFields(unit);
	set[MethodVar] localVars = findlocalVars(mdl);
	set[MethodVar] availableVars = fields + localVars;
	
	return isVarADoubleOrFloat(args, availableVars) ||
		isDoubleOrFloatConstants(args) ||
		isANumberCallingDoubleOrFloatValue(args, availableVars);
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

private Expression refactorViolationAsExpression(str classType, str arg) {
	return refactorViolation(classType, arg);
}

private void countModificationForLog(str scope) {
	if (scope in timesReplacedByScope) {
		timesReplacedByScope[scope] += 1;
	} else { 
		timesReplacedByScope[scope] = 1;
	}
}

private void doWriteLog(loc fileLoc) {
	if (shouldWriteLog)
		writeLog(fileLoc, logPath, detailedLogFileName, countLogFileName, timesReplacedByScope);
}