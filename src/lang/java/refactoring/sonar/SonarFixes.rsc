module lang::java::refactoring::sonar::SonarFixes

import lang::java::refactoring::sonar::stringLiteralDuplicated::StringLiteralDuplicated;
import lang::java::refactoring::sonar::stringPrimitiveConstructor::StringPrimitiveConstructor;
import lang::java::refactoring::sonar::replaceEmptyConstantWithGenericMethod::replaceEmptyConstantWithGenericMethod;
import lang::java::refactoring::sonar::stringIndexOfSingleQuoteChar::StringIndexOfSingleQuoteChar;
import lang::java::refactoring::sonar::stringLiteralLHSEquality::StringLiteralLHSEquality;
import lang::java::refactoring::sonar::stringEqualsIgnoreCase::StringEqualsIgnoreCase;
import lang::java::refactoring::sonar::collectionIsEmpty::CollectionIsEmpty;
import lang::java::refactoring::sonar::stringConcatenatedLoop::StringConcatenatedLoop;
import lang::java::refactoring::sonar::resourcesShouldBeClosed::ResourcesShouldBeClosed;
import lang::java::refactoring::sonar::referenceComparison::ReferenceComparison;
import lang::java::refactoring::sonar::mapEntrySetInsteadOfKeySet::MapEntrySetInsteadOfKeySet;
import lang::java::refactoring::sonar::parseToConvertStringToPrimitive::parseToConvertStringToPrimitive;
import IO;
import String;

private bool skipTestFiles = true;

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

public void allSonarFixesForFile(loc fileLoc) {
	//transformStringLiteralDuplicated(fileLoc);
	refactorStringPrimitiveConstructor(fileLoc);
	
	// avoiding modifying each module
	fileAsList = [fileLoc];
	
	refactorAllReferenceComparison(fileAsList);
	//refactorAllStringLiteralLHSEquality(fileAsList);

	replaceAllEmptyConstantWithGenericMethods(fileAsList);
	stringIndexOfSingleQuoteChar(fileAsList);
	refactorAllToEqualsIgnoreCase(fileAsList);
	//refactorAllToCollectionIsEmpty(fileAsList);
	refactorAllStringConcatenatedLoop(fileAsList);
	resourcesShouldAllBeClosed(fileAsList);
	refactorAllEntrySetInsteadOfKeySet(fileAsList);
	refactorAllParseToConvertStringToPrimitive(fileAsList);
}
