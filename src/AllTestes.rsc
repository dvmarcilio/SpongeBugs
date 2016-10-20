module AllTestes

import lang::java::\syntax::Java18;
import ParseTree; 
import IO;
import util::Math;

/**
 * Parse all files within the testes directory.
 * This method is usefull for testing the Java18 grammar.
 */
void parseAllFiles(bool verbose, loc baseDir) {
  real ok = 0.0; 
  real nok = 0.0; 
  entries = listJavaFiles(baseDir);  
  
  for(loc s <- entries) {
     if(verbose) { 
        print("[parsing file:] " + s.path);
     }
     
     try {
        //f = find(s, [|project://rascal-Java8/testes|]);
        contents = readFile(s);
        CompilationUnit cu = parse(#CompilationUnit, contents);
        if(verbose) {println("... ok");}
        ok = ok + 1.0;
     }
     catch ParseError(loc l): {
        if(!verbose) {
           print("[parsing file:] " + s.path);
        }
        println("... found an error at line <l.begin.line>, column <l.begin.column> "); 
        nok = nok + 1.0;
     }
   	}
   	real res = ok / (nok + ok);
    println("[Total of Java Files]: <nok + ok>");
    println("[Success Rate]: <res>");
 
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


