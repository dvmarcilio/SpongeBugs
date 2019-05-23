module lang::java::refactoring::sonar::security::\test::MessageDigestTest

import lang::java::\syntax::Java18;
import lang::java::refactoring::sonar::security::MessageDigest;

import IO;
import ParseTree;

str tc01 = " import java.security.MessageDigest; 
           ' class TestCase { 
           '   public void method() {
           '      MessageDigest md = MessageDigest.getInstance(\"MD5\");      	
           '   } 
           '}";
           

str tc02 = " import java.security.MessageDigest; 
           ' class TestCase { 
           '   public void method() {
           '      MessageDigest md = MessageDigest.getInstance(\"MD2\");      	
           '   } 
           '}";
           
str tc03 = " import java.security.MessageDigest; 
           ' class TestCase { 
           '   public void method() {
           '      MessageDigest md = MessageDigest.getInstance(\"MD4\");      	
           '   } 
           '}";
           

str res = " import java.security.MessageDigest; 
           ' class TestCase { 
           '   public void method() {
           '      MessageDigest md = MessageDigest.getInstance(\"SHA-256\");      	
           '   } 
           '}";
 
test bool runTC01() {
	code = parse(#CompilationUnit, tc01);
	expected = parse(#CompilationUnit, res); 
	return expected == refactorInsecureMessageDigest(code); 	
}

test bool runTC02() {
	code = parse(#CompilationUnit, tc02);
	expected = parse(#CompilationUnit, res); 
	return expected == refactorInsecureMessageDigest(code); 	
}

test bool runTC03() {
	code = parse(#CompilationUnit, tc03);
	expected = parse(#CompilationUnit, res); 
	return expected == refactorInsecureMessageDigest(code); 	
}