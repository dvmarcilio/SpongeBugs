module lang::java::refactoring::forloop::\test::EnhancedForLoopRefactorerTest

import IO;
import lang::java::refactoring::forloop::EnhancedForLoopRefactorer;
import lang::java::refactoring::forloop::\test::resources::RefactorerTestResources;

// comparing an entire file is not that practical	
// comparing methods then
// but definitely should automate test for entire compilation unit 
public test bool shouldRefactorInnerLoopButNoutOuterLoop() {
	refactorable = innerLoopButNotOuterLoop();
	
	refactored = refactorEnhancedForStatementsInMethodBody(refactorable.unit, refactorable.header, refactorable.body);
	
	return refactored.body == refactorable.refactored &&
		refactored.occurrences == 1;
}