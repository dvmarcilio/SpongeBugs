module lang::java::refactoring::sonar::security::\test::CipherTest

import lang::java::\syntax::Java18;
import lang::java::refactoring::sonar::security::Cipher;

import IO;
import ParseTree;

str tc01 = " import javax.crypto.Cipher; 
           ' class TestCase { 
           '   public void method() {
           '      Cipher c = Cipher.getInstance(\"DES/ECB/PKCS5Padding\");      	
           '   } 
           '}";
           

str tc02 = " import java.security.MessageDigest; 
           ' class TestCase { 
           '   public void method() {
           '      Cipher c = Cipher.getInstance(\"DESede/ECB/PKCS5Padding\");      	
           '   } 
           '}";
           
str tc03 = " import javax.crypto.Cipher; 
           ' class TestCase { 
           '   public void method() {
           '      Cipher c = Cipher.getInstance(\"RSA/NONE/NoPadding\");      	
           '   } 
           '}";
           
str tc04 = " import javax.crypto.Cipher; 
           ' class TestCase { 
           '   public void method() {
           '      Cipher c = Cipher.getInstance(\"AES/CBC/PKCS5Padding\");      	
           '   } 
           '}";
                      
str tc05 = " import javax.crypto.Cipher; 
           ' class TestCase { 
           '   public void method() {
           '      Cipher c = Cipher.getInstance(\"AES/ECB/NoPadding\");      	
           '   } 
           '}";     
           
str tc06 = " import javax.crypto.Cipher; 
           ' class TestCase { 
           '   public void method() {
           '      Cipher c = Cipher.getInstance(\"AES\");      	
           '   } 
           '}";                      
           

str res1 = " import javax.crypto.Cipher; 
           ' class TestCase { 
           '   public void method() {
           '      Cipher c = Cipher.getInstance(\"AES/GCM/NoPadding\");      	
           '   } 
           '}";
           

str res2 = " import javax.crypto.Cipher; 
           ' class TestCase { 
           '   public void method() {
           '      Cipher c = Cipher.getInstance(\"RSA/ECB/OAEPWithMD5AndMGF1Padding\");      	
           '   } 
           '}";
           
test bool runTC01() {
	code = parse(#CompilationUnit, tc01);
	expected = parse(#CompilationUnit, res1); 
	return expected == refactorInsecureCipher(code); 	
}           
           
           

test bool runTC02() {
	code = parse(#CompilationUnit, tc02);
	expected = parse(#CompilationUnit, res1); 
	
	println(code);
	println(expected);
	println(refactorInsecureCipher(code)); 
	return expected == refactorInsecureCipher(code); 	
}                     


test bool runTC03() {
	code = parse(#CompilationUnit, tc03);
	expected = parse(#CompilationUnit, res2); 
	return expected == refactorInsecureCipher(code); 	
}          


test bool runTC04() {
	code = parse(#CompilationUnit, tc04);
	expected = parse(#CompilationUnit, res1); 
	return expected == refactorInsecureCipher(code); 	
}           
           
           

test bool runTC05() {
	code = parse(#CompilationUnit, tc05);
	expected = parse(#CompilationUnit, res1); 
	return expected == refactorInsecureCipher(code); 	
}                     


test bool runTC06() {
	code = parse(#CompilationUnit, tc06);
	expected = parse(#CompilationUnit, res1); 
	return expected == refactorInsecureCipher(code); 	
}    
