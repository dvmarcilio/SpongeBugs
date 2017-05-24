module lang::java::refactoring::FilterPatternToLambda

import ParseTree;
import lang::java::\syntax::Java18;

public tuple[int, CompilationUnit] refactorFilterPattern(CompilationUnit cu) {
   int total = 0; 
   CompilationUnit unit =  visit(cu) {
       case(BlockStatements)`for(<UnannType t> <Identifier var> : <Expression exp>) { if(<Expression e>) { return true; } } return false;` : {
      	  total += 1;
          insert  (BlockStatements)`return <Identifier exp>.stream().anyMatches(<Identifier var> -\> <Expression e>);`;
     }
   };
   return <total, unit>;
}