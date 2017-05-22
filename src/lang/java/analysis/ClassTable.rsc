module lang::java::analysis::ClassTable

import Map;
import ParseTree;
import IO;

import io::IOUtil;

import lang::java::analysis::GraphDependency;
import lang::java::m3::M3Util;
import lang::java::\syntax::Java18;

// the project class table considered in the source 
// code. 
map[str, str] projectClassTable = ();

// the library class table considered in the source 
// code analysis and transformations. 
map[str, tuple[str,str]] libClassTable = ();


/**
 * Load a class table from a list of JAR files. 
 * It uses a simple cache mechanism to avoid loading the 
 * class table each time it is necessary. 
 */ 
map[str, tuple[str,str]] loadLibClassTable(list[loc] jars) {
  if(size(libClassTable) == 0) {
      libClassTable = classesHierarchy(jars);
  }
  return libClassTable;
}

map[str, tuple[str, str]] allProjectDeclarations(loc dir) {
   map[str, tuple[str, str]] decls = ();
   list[CompilationUnit] unities = [];
   list[loc] files = findAllFiles(dir, "java");
   for(f <- files) { 
     try {
 		unities += parse(#CompilationUnit, readFile(f));
     } 
  	 catch : { println("erro"); continue; };
  }
  for(u <- unities) {
     decls += declarations(u);
  }
  return decls; 
}

map[str, str] loadProjectClassTable(loc dir) {
  list[CompilationUnit] unities = [];
  list[loc] files = findAllFiles(dir, "java");
  for(f <- files) { 
     try {
 		unities += parse(#CompilationUnit, readFile(f));
     } 
  	 catch : { println("erro"); continue; };
  }
  for(u <- unities) {
    projectClassTable +=  (t:s | td <- enrichedClassTable(u), <t, s> := classTableEntryFromTypeDeclaration(td)); 
  }
  return projectClassTable;	
}

/**
 * Converts a TypeDeclaration into a more simple 
 * format of a class table entry. 
 */ 
tuple[str, str] classTableEntryFromTypeDeclaration(td) {
  switch(td) {
    case class(p, n, sc, _, _) : return <p + n, sc>;
    case interface(p, n, _, _) : return <p + n, "-">; 
    case enum(p, n) : return <p + n, "-">;
  } 
}

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
