module lang::java::refactoring::VarArgs

import lang::java::\syntax::Java18;
import ParseTree; 
import IO;
import List;

/**
 * Refactor a compilation unit to use VarArgs. 
 */
public tuple[int, CompilationUnit] refactorVarArgs(CompilationUnit unit) {
  int numberOfOccurences = 0;
  CompilationUnit cu = visit(unit) {
    case (MethodDeclarator)`<Identifier n>(<VariableModifier* mds> <UnannType t> <Identifier arg>[])` : {
      numberOfOccurences += 1; 
      insert (MethodDeclarator)`<Identifier n>(<VariableModifier* mds> <UnannType t>... <Identifier arg>) /*varagrs refactor*/`;
    }    
    case (MethodDeclarator)`<Identifier n>(<{FormalParameter ","}+ pmts>, <VariableModifier* mds> <UnannType t> <Identifier arg>[])` : {
      numberOfOccurences += 1; 
      insert (MethodDeclarator)`<Identifier n>(<{FormalParameter ","}+ pmts>, <VariableModifier* mds> <UnannType t> ... <Identifier arg>) /*varagrs refactor*/`; 
    }
    case (MethodDeclarator)`<Identifier n>(<VariableModifier* mds> <UnannPrimitiveType t>[] <Identifier arg>)` : {
      numberOfOccurences += 1; 
      insert (MethodDeclarator)`<Identifier n>(<VariableModifier* mds> <UnannType t>... <Identifier arg>) /*varagrs refactor*/`;
    }
    case (MethodDeclarator)`<Identifier n>(<VariableModifier* mds> <UnannClassOrInterfaceType t>[] <Identifier arg>)` : {
      numberOfOccurences += 1; 
      insert (MethodDeclarator)`<Identifier n>(<VariableModifier* mds> <UnannType t>... <Identifier arg>) /*varagrs refactor*/`;
    }
    case (MethodDeclarator)`<Identifier n>(<{FormalParameter ","}+ pmts2>, <VariableModifier* mds> <UnannPrimitiveType t>[] <Identifier arg>[])` : {
      numberOfOccurences += 1; 
      insert (MethodDeclarator)`<Identifier n>(<{FormalParameter ","}+ pmts2>, <VariableModifier* mds> <UnannType t> ... <Identifier arg>) /*varagrs refactor*/`;
    } 
    case (MethodDeclarator)`<Identifier n>(<{FormalParameter ","}+ pmts3>, <VariableModifier* mds> <UnannClassOrInterfaceType t>[] <Identifier arg>[])` : {
      numberOfOccurences += 1; 
      (MethodDeclarator)`<Identifier n>(<{FormalParameter ","}+ pmts3>, <VariableModifier* mds> <UnannType t> ... <Identifier arg>) /*varagrs refactor*/`;
    }
  };
  return <numberOfOccurences, cu>;
}
