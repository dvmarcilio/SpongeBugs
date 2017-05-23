module lang::java::refactoring::AnonymousToLambda

import lang::java::\syntax::Java18;
import lang::java::analysis::Imports;

import ParseTree; 
import IO;

void findAnonymousInnerClass(CompilationUnit unit) {
   visit(unit) {
     case (Expression)`new <Identifier id>() <ClassBody body>` : { 
         println("AIC new <id> <body>"); 
      } 
   };
}


public tuple[int, CompilationUnit] refactorAnonymousInnerClass(CompilationUnit unit) {
   list[ImportClause] imports = listOfImports(unit);
   int total = 0;
   CompilationUnit res = visit(unit) {
     case (Expression)`new <ClassOrInterfaceTypeToInstantiate id>() {<MethodModifier m> <Result res> <Identifier methodName> () { <Statement stmt> } }` : 
     {
       if(!checkConstraints(stmt, methodName, imports)) { 
         total += 1;
         insert (Expression)`()-\> { <Statement stmt >}`;
       }
     }
     case (Expression)`new <ClassOrInterfaceTypeToInstantiate id>() {<MethodModifier m> <Result res> <Identifier methodName> (<FormalParameter fp>) {<Statement stmt>}}` : 
     { 
     	if(!checkConstraints(stmt, methodName, imports)) {
     	  total += 1;
          insert (Expression)`(<FormalParameter fp>)-\>{ <Statement stmt>}`;
        }   
     }
   };
   return <total, res>;
}

/**
 * Check the constraints related to the 
 * annonymousToLambda refactoring. 
 */
bool checkConstraints(Statement stmt, Identifier methodName, list[ImportClause] imports)  {
  res = false; 
  visit(stmt) { 
    case (Expression)`this` : res = true;
    case (FieldAccess)`super.<Identifier id>` : res = true;
    case (MethodInvocation)`super.<TypeArguments args><Identifier id>(<ArgumentList args>)` : res = true;
    case (MethodInvocation)`methodName(<ArgumentList args>)` : res = true;  
    case (ThrowStatement)`throw <Expression e>;` : { println("throws in annonymous"); res = true; } 
  };
  return res; 
}