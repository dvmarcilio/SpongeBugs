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
    case (Expression)`new <ClassOrInterfaceTypeToInstantiate id>() {<MethodModifier m> <Result res> <Identifier methodName> () <Block bl>}` => (Expression)`()-\><Block bl>`
    
    case (Expression)`new <ClassOrInterfaceTypeToInstantiate id>() {<MethodModifier m> <Result res> <Identifier methodName> (<FormalParameter fp>) <Block bl>}` => (Expression)`(<FormalParameter fp>)-\><Block bl>`
    
};
