module lang::java::analysis::JavaTypes

import lang::java::\syntax::Java18;
import ParseTree; 

import IO;
import List;
import String; 


/*
 * Returns a mapping with all type declarations from a 
 * CompilationUnit. This mapping is just a utility for 
 * querying type declarations, and it maps full 
 * qualified type names into tuples of (package name, type name). 
 */                      
public map[str, tuple[str, str]] declarations(CompilationUnit unit) {
   str package = "";
   map[str, tuple[str,str]] decls = ();
   visit(unit) {
     case (PackageDeclaration)`package <{Identifier "."}+ ids>;` : { 
        package = unparse(ids); 
     }
     case normalClassDeclaration(mds, id, typeParameters, superClass, superInterfaces, body) : {
         str typeName = unparse(id);
         str qualifiedName = package + "." + typeName;
         decls = decls + (qualifiedName : <package, typeName>);
     }
     case enumDeclaration(mds, id, superInterfaces, body) : {
         str typeName = unparse(id);
         str qualifiedName = package + "." + typeName;
         decls = decls + (qualifiedName : <package, typeName>);
     }
     case normalInterfaceDeclaration(mds, id, typeParameters, superInterfaces, body) : {
         str typeName = unparse(id);
         str qualifiedName = package + "." + typeName;
         decls = decls + (qualifiedName : <package, typeName>);
     }
     // TODO: I am not sure if we should also visit annotation declarations. 
   }
   return decls;
}

/*
 * given a qualified named type, this function 
 * returns the name of the type. 
 *
 * e.g.: typeFromQualifiedName("br.unb.cic.GameEngine") = "GameEngine" 
 *       typeFromQualifiedName("Foo") = "Foo"   
 */
str typeFromQualifiedName(str qname) {
  return last(split(".", qname));
}
