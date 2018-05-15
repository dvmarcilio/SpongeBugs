module lang::java::refactoring::sonar::mutableMembersUsage::\test::MutableMembersUsageTestResources

import IO;
import lang::java::\syntax::Java18;
import ParseTree;

public CompilationUnit simpleViolationsUnit() {
	fileLoc = |project://rascal-Java8//testes/sonar/MutableMembersUsage/SimpleViolations.java|;
	return parse(#CompilationUnit, readFile(fileLoc));
}