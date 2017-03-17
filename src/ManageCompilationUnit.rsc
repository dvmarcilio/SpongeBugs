module ManageCompilationUnit

import lang::java::\syntax::Java18;
import ParseTree; 
import List;
import IO;

/**
 * Load java files and generate the 'CompilationUnit' from each file.
 */
list[CompilationUnit] listCompilations(loc location){
	try{
		entries = listJavaFiles(location);
		list[CompilationUnit] listCompilations = [];
		
		for(loc entry <- entries) {	     
		    try {
		        contents = readFile(entry);
		        CompilationUnit unit = parse(#CompilationUnit, contents);
		        listCompilations = listCompilations + unit;
		     }
		     catch ParseError(loc entry): {
		        println("Found an error at line <entry.begin.line>, column <entry.begin.column>."); 
		     }
	   	}
	   	
	   	return listCompilations;
	}
	catch: {
    	println("Sorry, an error occurred while loading the compilations unit."); 
    }
}


/**
 * List all java files from a location
 */
list[loc] listJavaFiles(loc location) {
	list[loc] allFiles = location.ls;
	listFiles = [];
   
	for(loc file <- allFiles) {
		if(isDirectory(file)) {
  			listFiles = listFiles + (listJavaFiles(file));
		}
		else {
  			if(file.extension == "java") {
     			listFiles = listFiles + file;
  			}
		}
	}

	return listFiles; 
}


// local = |project://find-class/testes|;