module AllTestes

import Java18;
import ParseTree; 
import IO;

/**
 * Parse all files within the testes directory.
 * This method is usefull for testing the Java18 grammar.
 */
void parseAllFiles() {
  entries = listJavaFiles(|project://rascal-Java8/testes|);  
  
  for(loc s <- entries) {
     print("[parsing file:] " + s.path);
     
     try {
        //f = find(s, [|project://rascal-Java8/testes|]);
        contents = readFile(s);
        CompilationUnit cu = parse(#CompilationUnit, contents);
        println("... ok");
     }
     catch ParseError(loc l): {
        println("... found an error at line <l.begin.line>, column <l.begin.column> "); 
     }
  }
}

/**
 * List all Java files from an original location. 
 */
list[loc] listJavaFiles(loc location) {
  res = [];
  list[loc] allFiles = location.ls;
       
  for(loc l <- allFiles) {
    if(isDirectory(l)) {
      res = res + (listJavaFiles(l));
    }
    else {
      if(l.extension == "java") {
         res = l + res;
      };
    };
  };
  return res; 
}


