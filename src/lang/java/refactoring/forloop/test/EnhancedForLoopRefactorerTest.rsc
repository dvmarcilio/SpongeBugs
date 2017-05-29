module lang::java::refactoring::forloop::\test::EnhancedForLoopRefactorerTest

import IO;
import lang::java::refactoring::forloop::EnhancedForLoopRefactorer;

public test bool refactorableInnerLoopButNotOuterLoop() {
	classLoc = |project://rascal-Java8//testes/forloop/Refactorer/ClassRefactorableInnerLoopButNotOuter|;
	forLoopToFunctional([classLoc], {});
	return false;
}