module PrettyPrinter

import Java18;
import ParseTree;

string prettyPrinter(CompilationUnit cu) {
   compilationUnit(packageDec, imports, types) <- cu;
   return prettyPrinter(packages);
}

string prettyPrinter([PackageDec] packageDEC) {
   
}