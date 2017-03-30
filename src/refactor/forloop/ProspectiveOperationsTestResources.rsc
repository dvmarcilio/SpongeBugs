module refactor::forloop::ProspectiveOperationsTestResources

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import MethodVar;
import LocalVariablesFinder;

public tuple [set[MethodVar] vars, EnhancedForStatement loop] simpleShort() {
	fileLoc = |project://rascal-Java8//testes/ProspectiveOperation/SimpleShortEnhancedLoop|;
	enhancedForLoop = parse(#EnhancedForStatement, readFile(fileLoc));
	return <{}, enhancedForLoop>; 
}

public tuple [set[MethodVar] vars, EnhancedForStatement loop] continueAndReturn() {
	fileLoc = |project://rascal-Java8//testes/ProspectiveOperation/ContinueAndReturnEnhancedLoop|;
	enhancedForLoop = parse(#EnhancedForStatement, readFile(fileLoc));
	return <continueAndReturnVars(), enhancedForLoop>; 
}

private set[MethodVar] continueAndReturnVars() {
	methodHeader = parse(#MethodHeader, "boolean isEngineExisting(String grammarName)");
	methodBody = parse(#MethodBody, "{\n for(GrammarEngine e : importedEngines) { \n if(e.getGrammarName() == null) continue; \n if(e.getGrammarName().equals(grammarName))\n return true; \n } \n return false; \n}" );
	return findLocalVariables(methodHeader, methodBody);
}

public tuple [set[MethodVar] vars, EnhancedForStatement loop] filterMapReduce() {
	fileLoc = |project://rascal-Java8//testes/ProspectiveOperation/FilterMapReduceEnhancedLoop|;
	enhancedForLoop = parse(#EnhancedForStatement, readFile(fileLoc));
	return <filterMapReduceVars(), enhancedForLoop>; 
}

private set[MethodVar] filterMapReduceVars() {
	methodHeader = parse(#MethodHeader, "int getNumberOfErrors()");
	methodBody = parse(#MethodBody, "{\n    int count = 0;\n    for (ElementRule rule : getRules()) {\n      if(rule.hasErrors())\n        count += rule.getErrors().size();\n    }\n    return count;\n  }");
	return findLocalVariables(methodHeader, methodBody);
}

public tuple [set[MethodVar] vars, EnhancedForStatement loop] filterAndMergedForEach() {
	fileLoc = |project://rascal-Java8//testes/ProspectiveOperation/FilterAndMergedForEach|;
	enhancedForLoop = parse(#EnhancedForStatement, readFile(fileLoc));
	return <filterAndMergedForEachVars(), enhancedForLoop>; 
}

private set[MethodVar] filterAndMergedForEachVars() {
	methodHeader = parse(#MethodHeader, "List\<String\> findReloadedContextMemoryLeaks()");
	methodBody = parse(#MethodBody, "{\n    List\<String\> result = new ArrayList\<String\>();\n    for (Map.Entry\<ClassLoader, String\> entry :\n        childClassLoaders.entrySet())\n      if(isValid(entry)) {\n        ClassLoader cl = entry.getKey();\n        if (!((WebappClassLoader)cl).isStart())\n          result.add(entry.getValue());\n      }\n   return result;\n  }");
	return findLocalVariables(methodHeader, methodBody);
}