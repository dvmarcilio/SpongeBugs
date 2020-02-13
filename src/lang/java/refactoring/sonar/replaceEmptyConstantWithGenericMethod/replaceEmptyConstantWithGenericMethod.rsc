module lang::java::refactoring::sonar::replaceEmptyConstantWithGenericMethod::replaceEmptyConstantWithGenericMethod

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import Set;
import lang::java::util::MethodDeclarationUtils;
import lang::java::util::CompilationUnitUtils;
import lang::java::refactoring::sonar::LogUtils;

private bool shouldWriteLog = false;

private loc logPath;

private str detailedLogFileName = "EMPTY_CONSTANT_WITH_GENERIC_METHOD_DETAILED.txt";
private str countLogFileName = "EMPTY_CONSTANT_WITH_GENERIC_METHOD_COUNT.txt";

private map[str, int] timesReplacedByScope = ();

private set[str] constantsToCheck = {"EMPTY_SET", "EMPTY_LIST", "EMPTY_MAP"};

 private set[str] maps = {"Map", "HashMap", "LinkedHashMap", "TreeMap", "EnumMap", "ConcurrentHashMap",
 	"ConcurrentMap", "SortedMap", "NavigableMap"};
 private set[str] sets = {"Set", "HashSet", "LinkedHashSet",
	 "TreeSet",  "SortedSet", "EnumSet", "NavigableSet"};
 private set[str] lists = {"List", "ArrayList", "LinkedList", "Stack", "Vector"};
 private set[str] collections = maps + sets + lists;
	 
private map[str, str] methodInvocationByConstantName = (
	"EMPTY_SET": "emptySet()",
	"EMPTY_LIST": "emptyList()",
	"EMPTY_MAP": "emptyMap()"
);

public void replaceAllEmptyConstantWithGenericMethods(list[loc] locs) {
	shouldWriteLog = false;
	doReplaceAllEmptyConstantWithGenericMethods(locs);
}

public void replaceAllEmptyConstantWithGenericMethods(list[loc] locs, loc logPathArg) {
	shouldWriteLog = true;
	logPath = logPathArg;
	doReplaceAllEmptyConstantWithGenericMethods(locs);
}

private void doReplaceAllEmptyConstantWithGenericMethods(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			if (shouldContinueWithASTAnalysis(fileLoc)) {
				doReplaceEmptyConstantWithGenericMethod(fileLoc);	
			}
		} catch: {
			continue;
		}	
	}
}

private bool shouldContinueWithASTAnalysis(loc fileLoc) {
	// incredibly speeding up matching
	javaFileContent = readFile(fileLoc);
	return findFirst(javaFileContent, "Collections.EMPTY") != -1;
}

public void replaceEmptyConstantWithGenericMethod(loc fileLoc) {
	shouldWriteLog = false;
	doReplaceEmptyConstantWithGenericMethod(fileLoc);
}

public void replaceEmptyConstantWithGenericMethod(loc fileLoc, loc logPathArg) {
	shouldWriteLog = true;
	logPath = logPathArg;
	doReplaceEmptyConstantWithGenericMethod(fileLoc);
}

private void doReplaceEmptyConstantWithGenericMethod(loc fileLoc) {
	unit = retrieveCompilationUnitFromLoc(fileLoc);
	
	shouldRewrite = false;
	timesReplacedByScope = ();
	
	unit = top-down visit(unit) {
		case (MethodDeclaration) `<MethodDeclaration mdl>`: {
			modified = false;
			mdl = visit(mdl) {
				case (Expression) `Collections.<Identifier constantName>`: {
					if (isConstantOfInterest("<constantName>")) {
						modified = true;
						Expression refactored = generateCorrectMethodInvocationFromConstantName("<constantName>");
						countModificationForLog(retrieveMethodSignature(mdl));
						insert (Expression) `<Expression refactored>`;
					}
				}
			}
			if (modified) {
				shouldRewrite = true;
				insert (MethodDeclaration) `<MethodDeclaration mdl>`;
			}
		}

		case (Expression) `Collections.<Identifier constantName>`: {
			if (isConstantOfInterest("<constantName>")) {
				shouldRewrite = true;
				Expression refactored = generateCorrectMethodInvocationFromConstantName("<constantName>");
				countModificationForLog("outside of method");
				insert (Expression) `<Expression refactored>`;
			}
		}
	}
	
	if (shouldRewrite) {
		writeFile(fileLoc, unit);
		doWriteLog(fileLoc);
	}	
}


private bool isConstantOfInterest(str constName) {
	return constName in constantsToCheck;
}

private Expression generateCorrectMethodInvocationFromConstantName(str constName) {
	return parse(#Expression, "Collections." + methodInvocationByConstantName[constName]);
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
