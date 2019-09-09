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
import lang::java::refactoring::sonar::stringLiteralDuplicated::StringLiteralIsAlreadyDefinedAsConstant;
import IO;
import String;
import Map;
import List;
import lang::java::m3::M3Util;

import lang::java::\syntax::Java18;
import ParseTree;

private bool skipTestFiles = true;

public void allSonarFixesForDirectory(loc dirLoc, bool ignoreTestFiles) {
    javaFiles = javaFilesFromDir(dirLoc, ignoreTestFiles);
    allSonarFixes(javaFiles);
}

private list[loc] javaFilesFromDir(loc dirLoc, bool ignoreTestFiles) {
	javaFiles = listAllJavaFiles(dirLoc);
    if (!ignoreTestFiles) {
    	return javaFiles;
    }
    
	javaFilesToFix = [];
	for (javaFile <- javaFiles) {
		if (shouldAnalyzeFile(javaFile))
			javaFilesToFix += javaFile;
	}
	return javaFilesToFix;
    
}

public void allSonarFixes(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			if (!startsWith(fileLoc.file, "_"))
				doAllSonarFixesForFile(fileLoc);
		} catch: {
			println("Exception file (SonarFixes): " + fileLoc.file);
			continue;
		}	
	}
}

public void tryToParseAll(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			if (!startsWith(fileLoc.file, "_") != -1 && !startsWith(fileName, "package-info"))
				parse(#CompilationUnit, readFile(fileLoc));
		} catch: {
			println("Exception file (SonarFixes): " + fileLoc);
		}	
	}
}

public int countConsideredFiles(list[loc] locs) {
	count = 0;
	for (fileLoc <- locs) {
		if (!startsWith(fileLoc.file, "_")) {
			if (shouldAnalyzeFile(fileLoc)){
				count += 1;	
			}
		}
	}
	return count;
}

public void doAllSonarFixesForFile(loc fileLoc) {
	if (shouldAnalyzeFile(fileLoc))
		allSonarFixesForFile(fileLoc);
}

private bool shouldAnalyzeFile(loc fileLoc) {
	if (!skipTestFiles)
		return true;
	fileName = fileNameWithoutExtension(fileLoc);
	return !endsWith(fileName, "Test") && findFirst(fileLoc.path, "src/test/java") == -1
		&& !startsWith(fileName, "package-info");
}

private str fileNameWithoutExtension(loc fileLoc) {
	indexOfExtension = findLast(fileLoc.file, ".java");
	return substring(fileLoc.file, 0, indexOfExtension);
}

private map[str, void (list[loc])] functionByRule = 
	(
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

private void stringLiteralDuplicated(list[loc] fileAsList) {
	transformStringLiteralDuplicated(fileAsList[0]);
	allStringLiteralsAlreadyDefinedAsConstant(fileAsList);
}

private void stringPrimitiveConstructor(list[loc] fileAsList) {
	refactorStringPrimitiveConstructor(fileAsList[0]);
}

public void sonarFixesForFileIncludes(loc javaFile, list[str] rules) {
	fixForRulesFromFile(javaFile, rules);
}

public void sonarFixesForDirectoryIncludes(loc dirLoc, list[str] rules, bool ignoreTestFiles) {
	list[loc] javaFiles = javaFilesFromDir(dirLoc, ignoreTestFiles);
	fixForRules(javaFiles, rules);
}

private void fixForRules(list[loc] javaFiles, list[str] rules) {
	for(javaFile <- javaFiles) {
		fixForRulesFromFile(javaFile, rules);
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

private void doFixForRulesFromFile(loc javaFile, list[str] rules) {
	if (!startsWith(javaFile.file, "_")) {
		for (rule <- rulesOrder) {
			if (rule in rules) {
				refactorFunction = functionByRule[rule];
				refactorFunction([fileLoc]);
			}
		}
	}
}

public void sonarFixesForFileExcludes(loc javaFile, list[str] excludeRules) {
	fixForRulesFromFile(javaFile, rulesAfterExclusion(excludeRules));
}

public void sonarFixesForDirectoryExcludes(loc dirLoc, list[str] excludeRules, bool ignoreTestFiles) {
	list[loc] javaFiles = javaFilesFromDir(dirLoc, ignoreTestFiles);
	fixForRules(javaFiles, rulesAfterExclusion(excludeRules));
}

private list[str] rulesAfterExclusion(list[str] excludeRules) {
	rulesAfter = [];
	for (rule <- rulesOrder) {
		if (rule notin excludeRules)
			rulesAfter += rule;
	}
	return rulesAfter;
}
