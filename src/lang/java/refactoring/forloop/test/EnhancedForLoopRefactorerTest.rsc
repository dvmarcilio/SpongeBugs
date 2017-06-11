module lang::java::refactoring::forloop::\test::EnhancedForLoopRefactorerTest

import IO;
import ParseTree;
import lang::java::\syntax::Java18;
import lang::java::refactoring::forloop::EnhancedForLoopRefactorer;

public test bool refactorableInnerLoopButNotOuterLoop() {
	classLoc = |project://rascal-Java8//testes/forloop/Refactorer/ClassRefactorableInnerLoopButNotOuter|;
	unit = parse(#CompilationUnit, classLoc);
	refactored = refactorEnhancedForStatements(unit);
	
	println("\n\n printando teste \n\n");
	println(refactored);
	
	return false;
}