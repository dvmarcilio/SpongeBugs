module SimpleMetrics

import lang::java::\syntax::Java18;
import ManageCompilationUnit;
import ParseTree; 
import List;
import Set;
import IO;

/**
 * Count the number of variables presents in the classes.
 */
int countVariablesOfClasses(loc location){
	try{
		int count = 0;
		
		for(CompilationUnit compilation <- listCompilations(location)){
	   		visit(compilation) {
		       case variableDeclaratorList (variables): { 
			       	if(size({variable | /variableDeclarator(variable,_) <- variables}) > 0) {
			           count = count + 1; 
			        }
		       	}
		   	}
	   	}
	   	
	   	return count;
	}
	catch: {
		println("Sorry, an error occurred while count the number of variables present in the classes.");
	}
}


/**
 * Count the number of methods of the classes.
 */
int countMethodsOfClass(loc location) {
	try{
		int count = 0;
		
	   	for(CompilationUnit compilation <- listCompilations(location)){
	   		visit(compilation) {
		       case methodDeclaration (_, _, _): { 
			       	count = count + 1;
		       	}
		   	}
	   	}
	   	
	   	return count;
	}
	catch:{
		println("Sorry, an error occurred while count the number of methods of the classes.");
	}
}


/**
 * Count the number of class declaration within a compilation unit. 
 * TODO: I'd rather use ConcreteSyntax instead. 
 */
int countClasses(loc location) {
	try{
		int count = 0;
		
		for(CompilationUnit compilation <- listCompilations(location)){
	   		visit(compilation) {
				case normalClassDeclaration (_, _, _, _, _, _): { 
					count = count + 1;
				}
			}
	   	}
	   	
		return count;
	}
	catch:{
		println("Sorry, an error occurred while count the number of classes.");
	}
}


/**
 * Count the number of parameterized classes. 
 * TODO: Now, it seems to me that it would be better to work with ConcreteSyntax. 
 */
int countClassParameters(loc location) {
   	try{
	   	int count = 0;
	   	
	   	for(CompilationUnit compilation <- listCompilations(location)){
	   		visit(compilation) {
		       	case normalClassDeclaration(mds, name, pmts, super, infs, bdy): { 
			        if(size({n | /typeParameter(_, n, _) <- pmts}) > 0) {
			           count = count + 1; 
			        }
			     }
	   		}
	   	}
	   	
  	   	return count;
   	}
   	catch:{
   		println("Sorry, an error occurred while count the class parameters."); 
   	}
}