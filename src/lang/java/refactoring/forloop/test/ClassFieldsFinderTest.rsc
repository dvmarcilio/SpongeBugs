module lang::java::refactoring::forloop::\test::ClassFieldsFinderTest

import lang::java::\syntax::Java18;
import ParseTree;
import lang::java::refactoring::forloop::ClassFieldsFinder;
import lang::java::refactoring::forloop::MethodVar;
import Set;

public test bool shouldReturnAllClassFields() {
	fileLoc = |project://rascal-Java8//testes/forloop/localVariables/ClassWithFields.java|;
	unit = parse(#CompilationUnit, fileLoc);
	
	classFields = findClassFields(unit);
	
	return size(classFields) == 6 && 
		methodVar(true,"NAME","String",false,false,true) in classFields &&
		methodVar(false,"name","String",false,false,true) in classFields &&
		methodVar(true,"NUMBERS_SIZE","int",false,false,true) in classFields &&
	    methodVar(false,"objArray2","Object[]",false,false,true) in classFields &&
	    methodVar(false,"numbers","List\<Integer\>",false,false,true) in classFields &&
	    methodVar(false,"objArray","Object[]",false,false,true) in classFields;
}