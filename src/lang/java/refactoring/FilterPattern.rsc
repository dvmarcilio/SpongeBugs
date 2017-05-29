module lang::java::refactoring::FilterPattern

import ParseTree;
import lang::java::\syntax::Java18;

/**
 * Refactor a compilation unit to replace 
 * foreach statements, according to the 
 * exist pattern, into a lambda expression.
 */ 
public tuple[int, CompilationUnit] refactorFilterPattern(CompilationUnit cu) {
   int total = 0; 
   CompilationUnit unit =  visit(cu) {
       case(BlockStatements)`for(<UnannType t> <Identifier var> : <Expression exp>) { if(<Expression e>) { return true; }}` : {
      	  total += 1;
          insert  (BlockStatements)`c  = exp.stream().filter(var -\> e).list();`;
     }
   };
   return <total, unit>;
}