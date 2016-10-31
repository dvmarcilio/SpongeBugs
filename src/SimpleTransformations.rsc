module SimpleTransformations

import lang::java::\syntax::Java18;
import ParseTree; 
import IO;
import Set; 

CompilationUnit transformNaiveIfStatement(CompilationUnit unit) {
   return visit(unit) {
       case (Statement) `if (<Expression cond>) { return true; } else { return false; }` =>  (Statement) `return <Expression cond>;`
       case (Statement) `if (<Expression cond>)  return true;  else return false;` =>  (Statement) `return <Expression cond>;`  
   };
}

int countClassDeclarations(CompilationUnit unit) {
  int res = 0;
  
  visit(unit) {
    case normalClassDeclaration(_, _, _, _, _, _): { res += 1; }  
  }
  return res; 
}

CompilationUnit visitMethodDeclaration(CompilationUnit unit) =  visit(unit) {
      case (MethodDeclarator)`<Identifier n>(<UnannType t> <Identifier arg>[])` => 
        (MethodDeclarator)`<Identifier n>(<UnannType t>... <Identifier arg>)`
        
      case (MethodDeclarator)`<Identifier n>(<{FormalParameter ","}+ pmts>, <UnannType t> <Identifier arg>[])` => 
        (MethodDeclarator)`<Identifier n>(<{FormalParameter ","}+ pmts>, <UnannType t> ... <Identifier arg>)` 
 };


int countPmtClassDeclarations(CompilationUnit unit) {
  int res = 0; 
  visit(unit) {
     case normalClassDeclaration(mds, name, pmts, super, infs, bdy): { 
        if(size({n | /typeParameter(_, n, _) <- pmts}) > 0) {
           res = res + 1; 
        }
     }
  }
  return res;
}
// sample: code = (CompilationUnit) `class MyClass { int m() { if (x) { return true;} else {return false; }} }`;
//code = parse(#CompilationUnit, |project://JavaSamples/src/br/unb/cic/Rascal/Main.java|);