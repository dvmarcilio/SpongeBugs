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

public void allSonarFixes(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			allSonarFixesForFile(fileLoc);
		} catch: {
			println("Exception file: " + fileLoc.file);
			continue;
		}	
	}
}

public void allSonarFixesForFile(loc fileLoc) {
	transformStringLiteralDuplicated(fileLoc);
	refactorStringPrimitiveConstructor(fileLoc);
	
	// avoiding modifying each module
	fileAsList = [fileLoc];
	
	replaceAllEmptyConstantWithGenericMethods(fileAsList);
	stringIndexOfSingleQuoteChar(fileAsList);
	refactorAllStringLiteralLHSEquality(fileAsList);
	refactorAllToEqualsIgnoreCase(fileAsList);
	refactorAllToCollectionIsEmpty(fileAsList);
	refactorAllStringConcatenatedLoop(fileAsList);
	resourcesShouldAllBeClosed(fileAsList);
	refactorAllReferenceComparison(fileAsList);
	refactorAllEntrySetInsteadOfKeySet(fileAsList);
	refactorAllParseToConvertStringToPrimitive(fileAsList);
}
