module lang::java::refactoring::sonar::SonarFixes

import lang::java::refactoring::sonar::stringLiteralDuplicated::StringLiteralDuplicated;
import lang::java::refactoring::sonar::stringPrimitiveConstructor::StringPrimitiveConstructor;
import lang::java::refactoring::sonar::replaceEmptyConstantWithGenericMethod::replaceEmptyConstantWithGenericMethod;
import lang::java::refactoring::sonar::stringIndexOfSingleQuoteChar::StringIndexOfSingleQuoteChar;
import lang::java::refactoring::sonar::stringLiteralLHSEquality::StringLiteralLHSEquality;
//import lang::java::refactoring::sonar::stringEqualsIgnoreCase::StringEqualsIgnoreCase;
import lang::java::refactoring::sonar::collectionIsEmpty::CollectionIsEmpty;
import lang::java::refactoring::sonar::stringConcatenatedLoop::StringConcatenatedLoop;
//import lang::java::refactoring::sonar::resourcesShouldBeClosed::ResourcesShouldBeClosed;
import lang::java::refactoring::sonar::referenceComparison::ReferenceComparison;
import lang::java::refactoring::sonar::mapEntrySetInsteadOfKeySet::MapEntrySetInsteadOfKeySet;
import lang::java::refactoring::sonar::parseToConvertStringToPrimitive::parseToConvertStringToPrimitive;
import lang::java::refactoring::sonar::stringLiteralDuplicated::StringLiteralsAlreadyDefinedAsConstant;
import IO;
import String;
import Map;
import List;
import lang::java::m3::M3Util;
import DateTime;

import lang::java::\syntax::Java18;
import ParseTree;

public void allSonarFixesForDirectory(loc dirLoc, bool ignoreTestFiles) {
    javaFiles = javaFilesFromDir(dirLoc, ignoreTestFiles);
    allSonarFixes(javaFiles);
}

private list[loc] javaFilesFromDir(loc dirLoc, bool ignoreTestFiles) {
	javaFiles = listAllJavaFiles(dirLoc);
    if (!ignoreTestFiles) {
    	return javaFiles;
    }
    
	return filterLocs(javaFiles);
}

private list[loc] filterLocs(list[loc] files) {
	javaFilesToFix = [];
	for (javaFile <- files) {
		if (shouldAnalyzeFile(javaFile))
			javaFilesToFix += javaFile;
	}
	return javaFilesToFix;
}

private bool shouldAnalyzeFile(loc fileLoc) {
	fileName = fileNameWithoutExtension(fileLoc);
	return !endsWith(fileName, "Test.java") && findFirst(fileLoc.path, "src/test/java") == -1
		&& !startsWith(fileName, "package-info");
}

public void allSonarFixesForDirectory(loc dirLoc, bool ignoreTestFiles, loc logPath) {
    javaFiles = javaFilesFromDir(dirLoc, ignoreTestFiles);
    doAllSonarFixes(javaFiles, createNowFolderForLogs(logPath));
}

public void allSonarFixes(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			if (!startsWith(fileLoc.file, "_"))
				allSonarFixesForFile(fileLoc);
		} catch: {
			println("Exception file (SonarFixes): " + fileLoc.file);
			continue;
		}	
	}
}

public void allSonarFixes(list[loc] locs, bool ignoreTestFiles, loc logPath) {
	if (ignoreTestFiles)
		locs = filterLocs(locs);
	doAllSonarFixes(locs, createNowFolderForLogs(logPath));
}

private loc createNowFolderForLogs(loc logPath) {
	if(!exists(logPath))
		mkDirectory(logPath);
	
	if (!isDirectory(logPath))
		throw "logPath is not a directory";

	nowStr = printDateTime(now(), "dd-MM-yy_HH-mm-ss");
	nowLogPath = logPath + nowStr;
	mkDirectory(nowLogPath);
	return nowLogPath;
}

private void doAllSonarFixes(list[loc] locs, loc logPath) {
	nowLogPath = createNowFolderForLogs(logPath);
	for(fileLoc <- locs) {
		try {
			if (!startsWith(fileLoc.file, "_"))
				doAllSonarFixesForFile(fileLoc, nowLogPath);
		} catch: {
			println("Exception file (SonarFixes): " + fileLoc.file);
		}
	}
}

public void tryToParseAll(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			if (!startsWith(fileLoc.file, "_") && !startsWith(fileLoc.file, "package-info"))
				parse(#CompilationUnit, readFile(fileLoc));
		} catch: {
			println("Exception file (SonarFixes): " + fileLoc.file);
		}	
	}
}

public int countConsideredFiles(list[loc] locs, bool ignoreTestFiles = true) {
	count = 0;
	for (fileLoc <- locs) {
		if (!startsWith(fileLoc.file, "_")) {
			if (ignoreTestFiles && shouldAnalyzeFile(fileLoc)){
				count += 1;	
			}
		}
	}
	return count;
}

private void doAllSonarFixesForFile(loc fileLoc, loc logPath) {
	nowLogPath = createNowFolderForLogs(logPath);
	allSonarFixesForFile(fileLoc, nowLogPath);
}

private str fileNameWithoutExtension(loc fileLoc) {
	indexOfExtension = findLast(fileLoc.file, ".java");
	return substring(fileLoc.file, 0, indexOfExtension);
}

private map[str, void (list[loc])] functionByRule = (
	"B1": refactorAllReferenceComparison,
	"B2": stringPrimitiveConstructor,
	"C1": stringLiteralDuplicated,
	"C2": stringIndexOfSingleQuoteChar,
	"C3": refactorAllStringConcatenatedLoop,
	"C4": refactorAllParseToConvertStringToPrimitive,
	"C5": refactorAllStringLiteralLHSEquality,
	"C7": refactorAllEntrySetInsteadOfKeySet,
	"C8": refactorAllToCollectionIsEmpty,
	"C9": replaceAllEmptyConstantWithGenericMethods
);

private map[str, void (list[loc], loc)] logFunctionByRule = (
	"B1": refactorAllReferenceComparison,
	"B2": stringPrimitiveConstructor,
	"C1": stringLiteralDuplicated,
	"C2": stringIndexOfSingleQuoteChar,
	"C3": refactorAllStringConcatenatedLoop,
	"C4": refactorAllParseToConvertStringToPrimitive,
	"C5": refactorAllStringLiteralLHSEquality,
	"C7": refactorAllEntrySetInsteadOfKeySet,
	"C8": refactorAllToCollectionIsEmpty,
	"C9": replaceAllEmptyConstantWithGenericMethods
);
	
// should we review this order?	
private list[str] rulesOrder = ["B2", "B1", "C9", "C2", "C8", "C3", "C7", "C4", "C1", "C5"];

	//resourcesShouldAllBeClosed(fileAsList);	
	//refactorAllToEqualsIgnoreCase(fileAsList);
public void allSonarFixesForFile(loc fileLoc) {
	fileAsList = [fileLoc];
	refactorStringPrimitiveConstructor(fileLoc);

	refactorAllReferenceComparison(fileAsList);

	replaceAllEmptyConstantWithGenericMethods(fileAsList);
	stringIndexOfSingleQuoteChar(fileAsList);
	refactorAllToCollectionIsEmpty(fileAsList);
	refactorAllStringConcatenatedLoop(fileAsList);
	refactorAllEntrySetInsteadOfKeySet(fileAsList);
	refactorAllParseToConvertStringToPrimitive(fileAsList);
	
	transformStringLiteralDuplicated(fileLoc);
	allStringLiteralsAlreadyDefinedAsConstant(fileAsList);
	
	refactorAllStringLiteralLHSEquality(fileAsList);
}

public void allSonarFixesForFile(loc fileLoc, loc logPath) {
	fileAsList = [fileLoc];
	logPath = createNowFolderForLogs(logPath);

	refactorStringPrimitiveConstructor(fileLoc, logPath);

	refactorAllReferenceComparison(fileAsList, logPath);

	replaceAllEmptyConstantWithGenericMethods(fileAsList, logPath);
	stringIndexOfSingleQuoteChar(fileAsList, logPath);
	refactorAllToCollectionIsEmpty(fileAsList, logPath);
	refactorAllStringConcatenatedLoop(fileAsList, logPath);
	refactorAllEntrySetInsteadOfKeySet(fileAsList, logPath);
	refactorAllParseToConvertStringToPrimitive(fileAsList, logPath);
	
	transformStringLiteralDuplicated(fileLoc, logPath);
	allStringLiteralsAlreadyDefinedAsConstant(fileAsList, logPath);
	
	refactorAllStringLiteralLHSEquality(fileAsList, logPath);
}

private void stringLiteralDuplicated(list[loc] fileAsList) {
	transformStringLiteralDuplicated(fileAsList[0]);
	allStringLiteralsAlreadyDefinedAsConstant(fileAsList);
}

private void stringLiteralDuplicated(list[loc] fileAsList, loc logPath) {
	transformStringLiteralDuplicated(fileAsList[0], logPath);
	allStringLiteralsAlreadyDefinedAsConstant(fileAsList, logPath);
}

public void sonarFixesForFileIncludes(loc javaFile, list[str] rules) {
	fixForRulesFromFile(javaFile, rules);
}

public void sonarFixesForFileIncludes(loc javaFile, list[str] rules, loc logPath) {
	nowLogPath = createNowFolderForLogs(logPath);
	fixForRulesFromFile(javaFile, rules, nowLogPath);
}

public void sonarFixesForDirectoryIncludes(loc dirLoc, list[str] rules, bool ignoreTestFiles) {
	list[loc] javaFiles = javaFilesFromDir(dirLoc, ignoreTestFiles);
	fixForRules(javaFiles, rules);
}

// debug without runner
public void sonarFixesForDirsIncludes(list[loc] dirLocs, list[str] rules, bool ignoreTestFiles = true) {
	list[loc] javaFiles = [];
	for (dirLoc <- dirLocs) {
		javaFiles += javaFilesFromDir(dirLoc, ignoreTestFiles);
	}
	println(size(javaFiles));
	fixForRules(javaFiles, rules);
}

public void sonarFixesForDirectoryIncludes(loc dirLoc, list[str] rules, bool ignoreTestFiles, loc logPath) {
	list[loc] javaFiles = javaFilesFromDir(dirLoc, ignoreTestFiles);
	nowLogPath = createNowFolderForLogs(logPath);
	fixForRules(javaFiles, rules, nowLogPath);
}

private void fixForRules(list[loc] javaFiles, list[str] rules) {
	for(javaFile <- javaFiles) {
		fixForRulesFromFile(javaFile, rules);
	}
}

private void fixForRules(list[loc] javaFiles, list[str] rules, loc logPath) {
	for(javaFile <- javaFiles) {
		fixForRulesFromFile(javaFile, rules, logPath);
	}
}

private void fixForRulesFromFile(loc javaFile, list[str] rules) {
	try {
		doFixForRulesFromFile(javaFile, rules);
	} catch: {
		println("Exception file (SonarFixes): " + fileLoc.file);
		continue;
	}
}

private void fixForRulesFromFile(loc javaFile, list[str] rules, loc logPath) {
	try {
		doFixForRulesFromFile(javaFile, rules, logPath);
	} catch: {
		println("Exception file (SonarFixes): " + fileLoc.file);
		continue;
	}
}

private void doFixForRulesFromFile(loc javaFile, list[str] rules) {
	if (!startsWith(javaFile.file, "_")) {
		for (rule <- rulesOrder) {
			if (rule in rules) {
				refactorFunction = functionByRule[rule];
				refactorFunction([javaFile]);
			}
		}
	}
}

private void doFixForRulesFromFile(loc javaFile, list[str] rules, loc logPath) {
	if (!startsWith(javaFile.file, "_")) {
		for (rule <- rulesOrder) {
			if (rule in rules) {
				refactorFunction = logFunctionByRule[rule];
				refactorFunction([javaFile], logPath);
			}
		}
	}
}

public void sonarFixesForFileExcludes(loc javaFile, list[str] excludeRules) {
	fixForRulesFromFile(javaFile, rulesAfterExclusion(excludeRules));
}

public void sonarFixesForFileExcludes(loc javaFile, list[str] excludeRules, loc logPath) {
	nowLogPath = createNowFolderForLogs(logPath);
	fixForRulesFromFile(javaFile, rulesAfterExclusion(excludeRules), nowLogPath);
}

public void sonarFixesForDirectoryExcludes(loc dirLoc, list[str] excludeRules, bool ignoreTestFiles) {
	list[loc] javaFiles = javaFilesFromDir(dirLoc, ignoreTestFiles);
	fixForRules(javaFiles, rulesAfterExclusion(excludeRules));
}

public void sonarFixesForDirectoryExcludes(loc dirLoc, list[str] excludeRules, bool ignoreTestFiles, loc logPath) {
	nowLogPath = createNowFolderForLogs(logPath);
	list[loc] javaFiles = javaFilesFromDir(dirLoc, ignoreTestFiles);
	fixForRules(javaFiles, rulesAfterExclusion(excludeRules), nowLogPath);
}

private list[str] rulesAfterExclusion(list[str] excludeRules) {
	rulesAfter = [];
	for (rule <- rulesOrder) {
		if (rule notin excludeRules)
			rulesAfter += rule;
	}
	return rulesAfter;
}
