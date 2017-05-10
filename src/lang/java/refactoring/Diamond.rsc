module lang::java::refactoring::Diamond 

import lang::java::\syntax::Java18;
import ParseTree; 
import IO;
import List;
import Node;

/**
 * Refactor a compilation unit to use Diamond. 
 */
public tuple[int, CompilationUnit] refactorDiamond(CompilationUnit unit) {
  int numberOfOccurences = 0;
  CompilationUnit cu = visit(unit) 
  {
    case (FieldDeclaration)`<FieldModifier* fm> <Identifier idt> <TypeArguments tas><VariableDeclaratorList vdl> ;` : {
      visit(vdl){ //case lvalue is a generic type
        //Case where generics isn't especified
        case (ClassOrInterfaceTypeToInstantiate)`<{AnnotatedType "."}* aType>` : {
          println("Casou lvalue com tipo 1(inferencia de tipo: " + vdl);
          numberOfOccurences += 1; 
          insert (ClassOrInterfaceTypeToInstantiate)`<{AnnotatedType "."}* aType>\<\>`;
        }
        //Case where generics may be simplified to <>
        case (ClassOrInterfaceTypeToInstantiate)`<{AnnotatedType "."}* aType> <TypeArguments args>` : {
          numberOfOccurences += 1; 
          if (/`\<\>`/ !:= toString(args)){
      	      insert (ClassOrInterfaceTypeToInstantiate)`<{AnnotatedType "."}* aType>\<\>`;
          }
        }
      } 
    }
   
    case (LocalVariableDeclaration)`<VariableModifier* fm> <Identifier idt> <TypeArguments tas> <VariableDeclaratorList vdl>` : {
      visit(vdl){ //case lvalue is a generic type
        //Case where generics isn't especified
        case (ClassOrInterfaceTypeToInstantiate)`<{AnnotatedType "."}* aType>` : {
          numberOfOccurences += 1; 
          insert (ClassOrInterfaceTypeToInstantiate)`<{AnnotatedType "."}* aType>\<\>`;
        }
        //Case where generics may be simplified to <>
        case (ClassOrInterfaceTypeToInstantiate)`<{AnnotatedType "."}* aType> <TypeArguments args>` : {
          numberOfOccurences += 1; 
          if (/`\<\>`/ !:= toString(args)){
      	    insert (ClassOrInterfaceTypeToInstantiate)`<{AnnotatedType "."}* aType>\<\>`;
          }
        }
      }    
    }    
  };
  return <numberOfOccurences, cu>;
}