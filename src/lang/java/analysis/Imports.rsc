module lang::java::analysis::Imports

import ParseTree;
import lang::java::\syntax::Java18;

/*
 * A datatype for representing imports, in java source 
 * code. 
 */ 
data ImportClause = singleTypeImport(str importedType) 
                  | onDemandImport(str package);
         
/* 
 * Return a list of imports from a compilation unit. 
 */                   
list[ImportClause] listOfImports(CompilationUnit unit) {
  list[ImportClause] res = [];
  visit(unit) {
     case (SingleTypeImportDeclaration)`import <TypeName t>;` : {
        res += singleTypeImport(unparse(t));
     }
     case (TypeImportOnDemandDeclaration)`import <PackageOrTypeName package>.*;`: {
        res += onDemandImport(unparse(package)); 
     }
    //TODO: I am not sure if we should deal with the other import cases. 
   }
  return res;
}