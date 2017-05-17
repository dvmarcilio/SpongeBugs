module Driver

import IO;
import String; 
import DateTime; 
import List; 
import Set;
import ParseTree; 
import util::Math;

import io::IOUtil; 

import lang::java::refactoring::MultiCatch;
import lang::java::refactoring::SwitchString;
import lang::java::refactoring::VarArgs; 
import lang::java::refactoring::Diamond;

import lang::java::util::ManageCompilationUnit;
import lang::java::m3::M3Util;
import lang::java::\syntax::Java18;
DateTime t0, t1;
str logFile = "";

/**
 * Analyze all projecteds listed in 
 * the input file. 
 */
public void refactorProjects(loc input, bool verbose = true) {
    str ctime =  printTime(now(), "YYYYMMDDHHmmss");
    logFile = "log-" + ctime;
    list[str] projects = readFileLines(input);
     
    for(p <- projects) {
       if(startsWith(p, "#")) {
         continue;
       }
       t0 = now();
       list[str] projectDescriptor = split(",", p);
       println("[Project Analyzer] project: " + projectDescriptor[0]);
       logMessage("[Project Analyzer] processing project: " + projectDescriptor[0]);
      
       list[loc] projectFiles = findAllFiles(|file:///| + projectDescriptor[4], "java");
       println("Processing " + projectDescriptor[0] + ...");
       switch(projectDescriptor[2]) {
          case /MC/: executeTransformations(projectFiles, toInt(projectDescriptor[3]), verbose, refactorMultiCatch, "multicatch");
          case /SS/: executeTransformations(projectFiles, toInt(projectDescriptor[3]), verbose, refactorSwitchString, "switchstring");
          case /VA/: executeTransformations(projectFiles, toInt(projectDescriptor[3]), verbose, refactorVarArgs, "varargs");
          case /DI/: executeTransformations(projectFiles, toInt(projectDescriptor[3]), verbose, refactorDiamond, "diamond");
          default: logMessage(" ... nothing to be done");
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
public void executeTransformations(list[loc] files, int percent, bool verbose, tuple[int, CompilationUnit](CompilationUnit) transformation, str name) {
  list[tuple[int, loc, CompilationUnit]] processedFiles = [];
  int errors = 0; 
  int totalOfTransformations = 0;
  for(file <- files) {
     contents = readFile(file);
     try {
       unit = parse(#CompilationUnit, contents);
       tuple[int, CompilationUnit] res = transformation(unit);
       if(res[0] > 0) {
         totalOfTransformations = totalOfTransformations + res[0];
         processedFiles += <res[0], file, res[1]>;
         println("  " + toString(res[0]) + " of " + size(files) + " processed succesfully!");
       }
     }
     catch : { 
     	errors += 1; 
        println("  file processed with errors!");
     };
  }
  int total = size(processedFiles);
  int toExecute = numberOfTransformationsToApply(total, percent);
  set[int] toApply = generateRandomNumbers(toExecute, total);
  int totalOfChangedFiles = exportResults(toApply, processedFiles, verbose, name);
  t1 = now();
  logMessage("- Number of files:  " + toString(size(files)));
  logMessage("- Processed Filies: " + toString(size(processedFiles)));
  logMessage("- Exported Files:   " + toString(size(toApply))); 
  logMessage("- Total of files changed: " + toString(totalOfChangedFiles));
  logMessage("- Total of transformations: " + toString(totalOfTransformations));
  logMessage("- Errors: " + toString(errors));
  logMessage("- Final Time: " + printTime(now(), "YYYYMMDDHHmmss"));
  logMessage("- Elapsed Time: " + prettyPrinterDuration(t1 - t0, "ms") + "ms");
}

/**
 * Export the results of a subset of the transformations. The results 
 * are exported to the original files.  
 */ 
int exportResults(set[int] toApply, list[tuple[int, loc, CompilationUnit]] processedFiles, bool verbose, str name) {
 int total = 0;
 println(toString(size(toApply)));
 for(v <- toApply) {
     output = processedFiles[v][1];
     unit = processedFiles[v][2];
     if(verbose) {
       logMessage("- applying " + name + " into " + output.path); 
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
   int res = total * percent / 100; 
   if(res <= 10 && total >= 10) {
     return 10; 
   }
   else if(res <= 10 && total < 10) {
     return total; 
   }
   return res;
}

void logMessage(str message) {
  loc out = |project://rascal-Java8/output/|;
  out += logFile; 
  if(!exists(out)) {
     println("Creating log file at: " + out.path);	
     writeFile(out, "");
  } 
  appendToFile(out, message  + "\n");
}
