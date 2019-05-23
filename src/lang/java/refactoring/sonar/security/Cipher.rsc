/**
 * A module for repairing the use of insecure algorithms of 
 * the Cipher class. 
 * 
 * @see http://find-sec-bugs.github.io/bugs.htm
 */ 

module lang::java::refactoring::sonar::security::Cipher

import lang::java::util::CompilationUnitUtils;
import lang::java::\syntax::Java18;

import IO;
import ParseTree;

public set[str] insecureAlgorithms = {"DES/ECB/PKCS5Padding"};

public CompilationUnit refactorInsecureCipher(CompilationUnit unit) = 
 visit(unit) { //TODO: for some reason, it didn't work with a when clause
	case (Expression)`Cipher.getInstance("DES/ECB/PKCS5Padding")`=> (Expression)`Cipher.getInstance("AES/GCM/NoPadding")` 
	case (Expression)`Cipher.getInstance("DESede/ECB/PKCS5Padding")`=> (Expression)`Cipher.getInstance("AES/GCM/NoPadding")`
	case (Expression)`Cipher.getInstance("RSA/NONE/NoPadding")`=> (Expression)`Cipher.getInstance("RSA/ECB/OAEPWithMD5AndMGF1Padding")`
	case (Expression)`Cipher.getInstance("AES/CBC/PKCS5Padding")`=> (Expression)`Cipher.getInstance("AES/GCM/NoPadding")`
	case (Expression)`Cipher.getInstance("AES/ECB/NoPadding")`=> (Expression)`Cipher.getInstance("AES/GCM/NoPadding")`  
	case (Expression)`Cipher.getInstance("AES")`=> (Expression)`Cipher.getInstance("AES/GCM/NoPadding")`  
};

public CompilationUnit refactorInsecureCipher(loc fileLoc) { 
  unit = retrieveCompilationUnitFromLoc(fileLoc); 
  return refactorInsecureMessageDigest(unit);
}
