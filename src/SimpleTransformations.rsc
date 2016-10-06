module SimpleTransformations

import Java18;
import ParseTree; 

CompilationUnit transformNaiveIfStatement(CompilationUnit unit) {
   return visit(unit) {
       case (Stm) `if (<Expr cond>) { return true } else { return false; }` =>  (Stm) `return <Expr cond>;`
       case (Stm) `if (<Expr cond>)  return true;  else return false;` =>  (Stm) `return <Expr cond>;`  
   };
}

// sample: code = (CompilationUnit) `class MyClass { int m() { if (x) { return true;} else {return false; }} }`;
