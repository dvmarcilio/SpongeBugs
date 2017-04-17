module Driver

import IO;
import String; 
import List; 
import Set;
import ParseTree; 
import util::Math;

import io::IOUtil; 

import MultiCatch; 
import lang::java::\syntax::Java18;


/**
 * Analyze all projecteds listed in 
 * the input file. 
 */
public void analyzeProjects(loc input, bool verbose = false) {
    list[str] projects = readFileLines(input);
    
    for(p <- projects) {
       list[str] projectDescriptor = split(";", p);
       println("[Project Analyzer] processing project: " + projectDescriptor[0]);
      
       list[loc] projectFiles = findAllFiles(|file:///| + projectDescriptor[4], "java");
    
       switch(projectDescriptor[2]) {
          case /MC/: runMultiCatch(projectFiles, toInt(projectDescriptor[3]), verbose);
          default: println("... nothing to be done");
       }
    }  
}

/**
 * Aplica a transformacao multicatch a todos os arquivos de 
 * um projeto. Acredito que essa funcao possa ser generalizada, 
 * uma vez que apenas a linha que chama "refactorMultiCatch" e 
 * uma que realiza o println precisam ser alteradas para as 
 * demais transformacoes. Algor para ser investigado posteriormente. 
 *
 * Alem disso, deve ser possivel utilizar um estilo mais funcional 
 * nessa implementacao. Mas ok, eh a primeira tentativa. Depois 
 * melhoramos. 
 */ 
public void runMultiCatch(list[loc] files, int percent, bool verbose) {
  list[tuple[int, loc, CompilationUnit]] processedFiles = [];
  int errors = 0; 
  for(file <- files) {
     contents = readFile(file);
     try {
       unit = parse(#CompilationUnit, contents);
       tuple[int, CompilationUnit] res = refactorMultiCatch(unit);
       if(res[0] > 0) {
         processedFiles += <res[0], file, res[1]>;
       }
     }
     catch : { errors += 1; };
  }
  int total = size(processedFiles);
  int toExecute = numberOfTransformationsToApply(total, percent);
  set[int] toApply = generateRandomNumbers(toExecute, total);
  int totalTransformations = exportResults(toApply, processedFiles, verbose);
  print("Total of applied transformations: ");
  println(totalTransformations);
  print("Errors: ");
  println(errors);
}

/**
 * Export the results of a subset of the transformations. The results 
 * are exported to the original files.  
 */ 
int exportResults(set[int] toApply, list[tuple[int, loc, CompilationUnit]] processedFiles, bool verbose) {
 int total = 0;
 for(v <- toApply) {
     output = processedFiles[v][1];
     unit = processedFiles[v][2];
     if(verbose) {
       print("[Project Analyzer] applying multicatch into ");
       println(output); 
     }
     writeFile(output, unit);
     total = total + processedFiles[v][0];
  }
  return total;
}

/**
 * generate a set of random numbers with the 
 * position of the files whose transformations 
 * must be realized. 
 */ 
set[int] generateRandomNumbers(int toExecute, int total) {
  set[int] res = {};
  while(size(res) < toExecute) {
     res += arbInt(total);
  };
  return res;
}

int numberOfTransformationsToApply(int total, int percent) {
   if(total <=10) {
     return total; 
   }
   return total * percent / 100;
}