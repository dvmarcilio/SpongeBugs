module refactor::forloop::\test::BreakIntoStatementsTest

import IO;
import refactor::forloop::BreakIntoStatements;
import lang::java::\syntax::Java18;
import refactor::forloop::ProspectiveOperationTestResources; 
import refactor::forloop::ForLoopBodyReferences;
import ParseTree;
import ParseTreeVisualization;

public test bool ex1() {
	fileLoc = |project://rascal-Java8//testes/ProspectiveOperation/SimpleShortEnhancedLoop|;
	enhancedForLoop = parse(#EnhancedForStatement, readFile(fileLoc));
	loopBody = retrieveLoopBodyFromEnhancedFor(enhancedForLoop);
	
	stmts = breakIntoStatements(loopBody);
	
	Stmt stmt = stmts[0];
	return size(stmts) == 1 &&
		"<stmt.statement>" == "writer.write(thing);" &&
		stmt.stmtType == "ExpressionStatement";
}

public test bool ex2() {
	fileLoc = |project://rascal-Java8//testes/ProspectiveOperation/ContinueAndReturnEnhancedLoop|;
	enhancedForLoop = parse(#EnhancedForStatement, readFile(fileLoc));
	loopBody = retrieveLoopBodyFromEnhancedFor(enhancedForLoop);
	
	stmts = breakIntoStatements(loopBody);
	
	return size(stmts) == 2 &&
		"<stmts[0].statement>" == "if(e.getGrammarName() == null) continue;" &&
		stmts[1].stmtType == "IfThenStatement" && 
		"<stmts[1].statement>" == "if(e.getGrammarName().equals(grammarName))\r\n        return true;" &&
		stmts[1].stmtType == "IfThenStatement";
}

public test bool ex3() {
	fileLoc = |project://rascal-Java8//testes/ProspectiveOperation/FilterMapReduceEnhancedLoop|;
	enhancedForLoop = parse(#EnhancedForStatement, readFile(fileLoc));
	loopBody = retrieveLoopBodyFromEnhancedFor(enhancedForLoop);
	
	stmts = breakIntoStatements(loopBody);
	
	Stmt stmt = stmts[0];
	return size(stmts) == 1 &&
		"<stmt.statement>" == "if(rule.hasErrors())\r\n        count += rule.getErrors().size();" &&
		stmt.stmtType == "IfThenStatement";
}

public test bool ex4() {
	enhancedForLoop = parse(#EnhancedForStatement, "for (Entry\<E\> entry : entries) {\n      elementsBuilder.add(entry.getElement());\n      // cumulativeCounts[i + 1] = cumulativeCounts[i] + entry.getCount();\n      i++;\n    }");
	loopBody = retrieveLoopBodyFromEnhancedFor(enhancedForLoop);
	
	stmts = breakIntoStatements(loopBody);
	
	return size(stmts) == 2 &&
		"<stmts[0].statement>" == "elementsBuilder.add(entry.getElement());" &&
		stmts[0].stmtType == "ExpressionStatement" &&
		"<stmts[1].statement>" == "i++;" &&
		stmts[1].stmtType == "ExpressionStatement";
}

public test bool ex5() {
	enhancedForLoop = parse(#EnhancedForStatement, "for (K key : keysToLoad) {\n            V value = newEntries.get(key);\n            if (value == null) {\n              throw new InvalidCacheLoadException(\"loadAll failed to return a value for \" + key);\n            }\n            result.put(key, value);\n          }");
	loopBody = retrieveLoopBodyFromEnhancedFor(enhancedForLoop);
	
	stmts = breakIntoStatements(loopBody);
	
	return size(stmts) == 3 &&
		"<stmts[0].statement>" == "V value = newEntries.get(key);" &&
		stmts[0].stmtType == "LocalVariableDeclarationStatement" &&
		"<stmts[1].statement>" == "if (value == null) {\n              throw new InvalidCacheLoadException(\"loadAll failed to return a value for \" + key);\n            }" &&
		stmts[1].stmtType == "IfThenStatement" &&
		"<stmts[2].statement>" == "result.put(key, value);" &&
		stmts[2].stmtType == "ExpressionStatement";
}

public test bool ex6() {
	fileForLoc = |project://rascal-Java8//testes/ForLoopToFunctional/ForIfWithTwoStmtsInsideAndStmtAfterBlock.java|;
	enhancedForLoop = parse(#EnhancedForStatement, readFile(fileForLoc));
	loopBody = retrieveLoopBodyFromEnhancedFor(enhancedForLoop);
	
	stmts = breakIntoStatements(loopBody);
	printStmtsBrokenInto(stmts);
	
	return false;
}