module AnonymousToLambda

import lang::java::\syntax::Java18;
import ParseTree; 
import IO;

void findAnonymousInnerClass(CompilationUnit unit) {
   visit(unit) {
     case (Expression)`new <Identifier id>() <ClassBody body>` : { 
         println("AIC new <id> <body>"); 
      } 
   };
}


CompilationUnit refactorAnonymousInnerClass(CompilationUnit unit) =  visit(unit) {
    case (Expression)`new <ClassOrInterfaceTypeToInstantiate id>() {<MethodModifier m> <Result res> <Identifier methodName> () { <Statement stmt> } }`  
      => (Expression)`()-\> { <Statement stmt >}`
    when !checkConstraints(stmt, methodName)  
    
    case (Expression)`new <ClassOrInterfaceTypeToInstantiate id>() {<MethodModifier m> <Result res> <Identifier methodName> (<FormalParameter fp>) {<Statement stmt>}}` 
      => (Expression)`(<FormalParameter fp>)-\>{ <Statement stmt>}`
    when !checkConstraints(stmt, methodName)  
      
    
};

bool checkConstraints(Statement stmt, Identifier methodName)  {
  res = false; 
  visit(stmt) { 
    case (Expression)`this` : res = true;
    case (FieldAccess)`super.<Identifier id>` : res = true;
    case (MethodInvocation)`super.<TypeArguments args><Identifier id>(<ArgumentList args>)` : res = true;
    case (MethodInvocation)`methodName(<ArgumentList args>)` : res = true;  
  };
  return res; 
}