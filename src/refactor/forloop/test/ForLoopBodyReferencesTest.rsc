module refactor::forloop::\test::ForLoopBodyReferencesTest

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import Set;
import refactor::forloop::ForLoopBodyReferences;
import MethodVar;

public test bool variablesReferenced1() {
	fileForLoc = |project://rascal-Java8//testes/ForLoopToFunctional/ForWith3StatementsMapBody.java|;
	forStmt = parse(#EnhancedForStatement, readFile(fileForLoc));
	loopBody = retrieveLoopBodyFromEnhancedFor(forStmt);
	
	result = findVariablesReferenced(loopBody);
	
	return size(result) == 5 && 
		"previous" in result &&
		"snapshot" in result &&
		"updated" in result &&
		"changedFiles" in result &&
		"changeSet" in result;
}

public test bool variablesReferenced2() {
	fileForLoc = |project://rascal-Java8//testes/ForLoopToFunctional/ForWithMultiStatementMap.java|;
	EnhancedForStatement forStmt = parse(#EnhancedForStatement, readFile(fileForLoc));
	loopBody = retrieveLoopBodyFromEnhancedFor(forStmt);
	
	result = findVariablesReferenced(loopBody);
	
	return size(result) == 5 && 
		"key" in result &&
		"keysIt" in result &&
		"value" in result &&
		"v" in result &&
		"result" in result;
}

public test bool variablesReferenced3() {
	fileForLoc = |project://rascal-Java8//testes/ForLoopToFunctional/T2For2.java|;
	EnhancedForStatement forStmt = parse(#EnhancedForStatement, readFile(fileForLoc));
	loopBody = retrieveLoopBodyFromEnhancedFor(forStmt);
	
	result = findVariablesReferenced(loopBody);
	
	return size(result) == 4 && 
		"map" in result &&
		"entry" in result &&
		"expectedHash" in result &&
		"expectedEntrySetHash" in result;
}