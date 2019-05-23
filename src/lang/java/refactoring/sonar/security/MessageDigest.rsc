/**
 * A module for repairing the use of insecure algorithms of  
 * the MessageDigest class. 
 * 
 * @see http://find-sec-bugs.github.io/bugs.htm
 */ 

module lang::java::refactoring::sonar::security::MessageDigest

import lang::java::util::CompilationUnitUtils;
import lang::java::\syntax::Java18;

import IO;
import ParseTree;

public set[str] insecureAlgorithms = {"MD2", "MD4", "MD5"};

public CompilationUnit refactorInsecureMessageDigest(CompilationUnit unit) = 
 visit(unit) { //TODO: for some reason, it didn't work with a when clause
	case (Expression)`MessageDigest.getInstance("MD5")`=> (Expression)`MessageDigest.getInstance("SHA-256")` 
	case (Expression)`MessageDigest.getInstance("MD2")`=> (Expression)`MessageDigest.getInstance("SHA-256")` 
	case (Expression)`MessageDigest.getInstance("MD4")`=> (Expression)`MessageDigest.getInstance("SHA-256")` 
};

public CompilationUnit refactorInsecureMessageDigest(loc fileLoc) { 
  unit = retrieveCompilationUnitFromLoc(fileLoc); 
  return refactorInsecureMessageDigest(unit);
}


