module lang::java::refactoring::ExistPatternToLambda

import ParseTree;
import lang::java::\syntax::Java18;

/**
 * Refactor a compilation unit to replace 
 * foreach statements, according to the 
 * exist pattern, into a lambda expression.
 */ 
public tuple[int, CompilationUnit] refactorExistPattern(CompilationUnit cu) {
   int total = 0; 
   CompilationUnit unit =  visit(cu) {
       case(BlockStatements)`for(<UnannType t> <Identifier var> : <Expression exp>) { if(<Expression e>) { return true; } } return false;` : {
      	  total += 1;
          insert  (BlockStatements)`return <Identifier exp>.stream().anyMatch(<Identifier var> -\> <Expression e>);`;
     }
   };
   return <total, unit>;
}