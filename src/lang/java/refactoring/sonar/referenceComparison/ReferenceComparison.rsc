module lang::java::refactoring::sonar::referenceComparison::ReferenceComparison

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import Set;
import Map;
import lang::java::util::CompilationUnitUtils;
import lang::java::refactoring::forloop::MethodVar;
import lang::java::refactoring::forloop::LocalVariablesFinder;
import lang::java::refactoring::forloop::ClassFieldsFinder;
import lang::java::util::GeneralUtils;

private data Var = newVar(str name, str varType);

private map[str, Var] fieldsByName = ();

private set[str] primitiveTypes = {"int", "double", "float", "char", "byte", "short", "long", "boolean"};

// List and Collections actually does not override equals
private set[str] typesWithoutEquals = {"List", "Set", "Map", "ArrayList", "LinkedList", "HashSet", "LinkedHashSet", "HashMap"};

// there is a rule that enums should be compared using "=="
private set[str] ignoreTypes = { "enum", "Object" } + primitiveTypes + typesWithoutEquals;

// Moving towards String and Boxed types. Less intrusive transformations
// We could change if we know that a class overrides equals() 
private set[str] classesToConsider = getPrimitiveWrappers() + "String";

private loc logPath;

private bool shouldWriteLog = false;

private str detailedLogFileName = "REFERENCE_COMPARISON_DETAILED.txt";
private str countLogFileName = "REFERENCE_COMPARISON_COUNT.txt";

private int timesModified = 0;

private map[str, int] timesReplacedByScope = ();

public void refactorAllReferenceComparison(list[loc] locs) {
	shouldWriteLog = false;
	doRefactorAllReferenceComparison(locs);
}

private void doRefactorAllReferenceComparison(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			if (shouldContinueWithASTAnalysis(fileLoc)) {
				fieldsByName = ();
				refactorFileReferenceComparison(fileLoc);
			}
		} catch: {
			println("Exception file: " + fileLoc.file);
			continue;
		}
	}
}

public void refactorAllReferenceComparison(list[loc] locs, loc logPathArg) {
	shouldWriteLog = true;
	logPath = logPathArg;
	doRefactorAllReferenceComparison(locs);
}

private bool shouldContinueWithASTAnalysis(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	return hasWrapper(javaFileContent) && hasEqualityOperator(javaFileContent); 
}

private bool hasWrapper(str javaFileContent) {
	for (wrapper <- classesToConsider) {
		if (findFirst(javaFileContent, wrapper) != -1)
			return true;
	}
	return false;
}

private bool hasEqualityOperator(str javaFileContent) {
	return findFirst(javaFileContent, "==") != -1 || findFirst(javaFileContent, "!=") != -1;
}

public void refactorFileReferenceComparison(loc fileLoc) {
	unit = retrieveCompilationUnitFromLoc(fileLoc);
	
	shouldRewrite = false;
	timesReplacedByScope = ();
	
	unit = top-down-break visit(unit) {
		case (MethodDeclaration) `<MethodDeclaration mdl>`: {
			mDeclStr = "";
			continueWithAnalysis = true;
			map[str, Var] localVarsByName = ();
			modified = false;
			visit(mdl) {
				case (MethodDeclarator) `<MethodDeclarator mDecl>`: {
					// Not analyzing equals()
					mDeclStr = "<mDecl>";
					continueWithAnalysis = findFirst(mDeclStr, "equals(") != 1;
				}
			}
			if (continueWithAnalysis) {
				mdl = visit(mdl) {
					case (Expression) `<EqualityExpression lhs> == <RelationalExpression rhs>`: {
						findFields(unit);
						if(isEmpty(localVarsByName)) 
							localVarsByName = findVarsInstantiatedInMethod(mdl);
						if (isComparisonOfInterest("<lhs>", "<rhs>", localVarsByName)) {
							modified = true;
							countModificationForLog(mDeclStr);
							insert(parse(#Expression, "<lhs>.equals(<rhs>)"));
						}					
					}
					case (Expression) `<EqualityExpression lhs> != <RelationalExpression rhs>`: {
						findFields(unit);
						if(isEmpty(localVarsByName)) 
							localVarsByName = findVarsInstantiatedInMethod(mdl);
						if (isComparisonOfInterest("<lhs>", "<rhs>", localVarsByName)) {
							modified = true;
							countModificationForLog(mDeclStr);
							insert(parse(#Expression, "!<lhs>.equals(<rhs>)"));
						}					
					}
				}
				if (modified) {
					shouldRewrite = true;
					insert mdl;
				}
			}
		}
		case (Expression) `<EqualityExpression lhs> == <RelationalExpression rhs>`: {
			findFields(unit);
			if (isComparisonOfInterest("<lhs>", "<rhs>")) {
				shouldRewrite = true;
				countModificationForLog("outside of method");
				insert(parse(#Expression, "<lhs>.equals(<rhs>)"));
			}
		}
		case (Expression) `<EqualityExpression lhs> != <RelationalExpression rhs>`: {
			findFields(unit);
			if (isComparisonOfInterest("<lhs>", "<rhs>")) {
				shouldRewrite = true;
				countModificationForLog("outside of method");
				insert(parse(#Expression, "!<lhs>.equals(<rhs>)"));
			}
		}
		
	}

	if (shouldRewrite) {
		writeFile(fileLoc, unit);
		writeLog(fileLoc);
	} 
}

private void findFields(CompilationUnit unit) {
	if(isEmpty(fieldsByName)) {
		set[MethodVar] fields = findClassFields(unit);
		for (field <- fields) {
			fieldsByName[field.name] = newVar(field.name, field.varType);
		}
	}
}

private map[str, Var] findVarsInstantiatedInMethod(MethodDeclaration mdl) {
	map[str, Var] varsInMethod = ();
	set[MethodVar] vars = findlocalVars(mdl);
	for (var <- vars) {
		varsInMethod[var.name] = newVar(var.name, var.varType);
	}
	return varsInMethod;
}

private bool isComparisonOfInterest(str exp1, str exp2) {
	return isExpOfInterest(exp1, fieldsByName) && isExpOfInterest(exp2, fieldsByName);
}

private bool isComparisonOfInterest(str exp, str exp2, map[str, Var] localVarsByName) {
	if (equalsNulls(exp) || equalsNulls(exp2)) return false;
	exp = trim(exp);
	exp2 = trim(exp2);
	exp1OfInterest = isExpOfInterest(exp, localVarsByName, fieldsByName);
	exp2OfInterest = isExpOfInterest(exp2, localVarsByName, fieldsByName);
	return exp1OfInterest && exp2OfInterest;
}

private bool equalsNulls(str exp) {
	return trim(exp) == "null";
}

private bool isExpOfInterest(str exp, map[str, Var] map1, map[str, Var] map2) {
	return isExpOfInterest(exp, map1) || isExpOfInterest(exp, map2);
}

private bool isExpOfInterest(str exp, map[str, Var] varByName) {
	if (exp in varByName) {
		var = varByName[exp];
		return var.varType in classesToConsider;
	}
	
	return isStringLiteral(exp);
}

// Can be used if we want to transform for all classes
private bool isExpOfInterestGeneralReference(str exp, map[str, Var] varByName) {
	if(exp in varByName) {
		var = varByName[exp];
		return var.varType notin ignoreTypes;
	}	
	
	return isStringLiteral(exp);
}

private bool isStringLiteral(str exp) {
	try {
		parse(#StringLiteral, exp);
		return true;
	} catch: {
		return false;
	}
}

private bool isLiteral(str exp) {
	try {
		parse(#Literal, exp);
		return true;
	} catch:
		return false;
}

private void countModificationForLog(str scope) {
	if (scope in timesReplacedByScope) {
		timesReplacedByScope[scope] += 1;
	} else { 
		timesReplacedByScope[scope] = 1;
	}
}

private void writeLog(loc fileLoc) {
	if (shouldWriteLog)
		doWriteLog(fileLoc);
}

private void doWriteLog(loc fileLoc) {
	if(!exists(logPath))
		mkDirectory(logPath);
	
	filePathStr = fileLoc.authority + fileLoc.path;
		
	detailedLogMap = createDetailedLogMap(filePathStr);
	detailedFilePath = logPath + detailedLogFileName;
	writeToLogFile(detailedLogMap, detailedFilePath);
	
	writeToCountLogFile(filePathStr);
}

private map[str, list[str]] createDetailedLogMap(str filePathStr) {
	map[str, list[str]] logMap = ();
	logMap[filePathStr] = [];
	
	for (scope <- domain(timesReplacedByScope)) {
		timesReplaced = timesReplacedByScope[scope];
		logMap[filePathStr] += "Replaced <timesReplaced> in <scope>";
	}
	
	return logMap;
}

private void writeToLogFile(map[str, list[str]] detailedLogMap, loc filePath) {
	mapStr = toString(detailedLogMap);
	if (exists(filePath))
		appendToFile(filePath, "\n" + mapStr);
	else
		writeFile(filePath, mapStr);
}

private void writeToCountLogFile(str filePathStr) {
	countFilePath = logPath + countLogFileName;
	
	timesReplaced = 0;
	for (scope <- domain(timesReplacedByScope)) {
		timesReplaced += timesReplacedByScope[scope];
	}
	
	countStr = "<filePathStr>: <timesReplaced>";
	
	writeToLogFile(countStr, countFilePath);
} 

private void writeToLogFile(str countStr, loc fileLoc) {
	if (exists(fileLoc))
		appendToFile(fileLoc, "\n" + countStr);
	else
		writeFile(fileLoc, countStr);
}