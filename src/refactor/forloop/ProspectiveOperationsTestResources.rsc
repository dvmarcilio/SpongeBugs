module refactor::forloop::ProspectiveOperationsTestResources

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import MethodVar;

public tuple [set[MethodVar] vars, EnhancedForStatement loop] simpleShort() {
	fileLoc = |project://rascal-Java8//testes/ProspectiveOperation/SimpleShortEnhancedLoop|;
	enhancedForLoop = parse(#EnhancedForStatement, readFile(fileLoc));
	return <{}, enhancedForLoop>; 
}