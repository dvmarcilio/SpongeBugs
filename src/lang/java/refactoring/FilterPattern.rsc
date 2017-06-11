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
       case(BlockStatements)`for(<UnannType t> <Identifier var> : <Expression exp>) { if(<Expression e>) { <Identifier v>.add(<Identifier var>); } }` : {
      	  total += 1;
          insert  (BlockStatements)`<Identifier v>  = <Identifier exp>.stream().filter(<Identifier var> -\> <Expression e>).collect(Collectors.toList());`;
     }
   };
   if(total > 0) {
      unit = visit(unit) {
         case(Imports)`<ImportDeclaration* imports>` : {
           insert (Imports)`<ImportDeclaration* imports>import java.util.stream.Collectors;`;
         } 
      }
   }
   return <total, unit>;
}