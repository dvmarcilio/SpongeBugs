module GraphDependency

import lang::java::\syntax::Java18;
import ParseTree; 

import JavaTypes; 

import IO;
import List;
import String;

data Member = method(str name, str returnType, list[str] args, list[str] dependencies)
            | field(str name, str fieldType);

data TypeDeclaration = class(str package, str name, str superClass, list[str] superInterfaces, list[Member] members)
                     | interface(str package, str name, list[str] superInterfaces, list[Member] members)
                     | enum(str package, str name);
                     
/*
 * return the name of the types imported by a translation unit and 
 * a set of type declarations. In this way, it is possible to deal 
 * with situations like import <package>.* (all declarations within 
 * <package>) and all declarations within the same package of the 
 * compilation unit.  
 */ 
map[str,str] importedClasses(CompilationUnit, map[str, tuple[str, str]] decls) {
   str package = "";
   list[str,str] imports = ();
   visit(unit) {
     case (PackageDeclaration)`package <{Identifier "."}+ ids>;` : { 
        package = unparse(ids);  
        imports = imports + listClassesFromPackage(package, decls);
     } 
     case (SingleTypeImportDeclaration)`import <TypeName t>;` : {
        str typeName = typeFromQualifiedName(unparse(t));
        imports = imports + (typeName : unparse(t));
     }
     case (TypeImportOnDemandDeclaration)`import <PackageOrTypeName package>.*;`: {
        imports = imports + listClassesFromPackage(package, decls); 
     }
    //TODO: I am not sure if we should deal with the other import cases. 
   }
}

/*
 * return the list of declared classes from a 
 * given package. 
 */
map[str,str] listClassesFromPackage(str package, map[str, tuple[str, str]] decls) {
  list[tuple[str, str]] classes = [<c, k> | k <- decls, <p, c> <- decls[k], p == package];
  map[str, str] res = ();
  for(<c, k> <- classes) {
     res = res + (c:k);
  }
  return res;
} 

list[TypeDeclaration] dependencies(CompilationUnit unit) {
   str package = "";
   list[TypeDeclaration] classes = [];
   visit(unit) {
     case (PackageDeclaration)`package <{Identifier "."}+ ids>;` : { 
        package = unparse(ids); 
     }
     case normalClassDeclaration(mds, id, typeParameters, superClass, superInterfaces, body) : {
        c = classDependencies(package, id, superClass, superInterfaces, body);
        classes = c + classes;	
     }
   }
   return classes;
}

/*
 * compute the dependencies of a given class attributes: 
 *  - name, superClass, superInterfaces, and body 
 */ 
private TypeDeclaration classDependencies(package, id, superClass, superInterfaces, body) {
   str sc = ""; 
   list[str] si = [];
   visit(superClass) {
     case(Superclass)`extends <ClassType t>` : { sc = trim(unparse(t)); }
   };
   visit(superInterfaces) {
     case (Superinterfaces)`implements <{InterfaceType ","}+ ins>` : { si = split(",", unparse(ins)); }
   }
   return class(package, unparse(id), sc, si, memberDependencies(body));
}

private list[Member] memberDependencies(body) {
   list[Member] depds = [];
  
   visit(body) {
      case (FieldDeclaration)`<FieldModifier* mds> <UnannType fieldType> <VariableDeclaratorList vars>;` : { 
         println(vars);
         str t = referenceType(fieldType);
         list[str] names = fieldNames(vars);
         depds = depds + [field(n, t) | n <-names];
      }
   };    
   return depds;  
}

private str referenceType(t) {
  str res = "primitive-type";
  visit(t) {
     case (UnannClassType)`<Identifier id>` : { res = unparse(id); } 
  } 
  return res; 
}
/*
 * retrieves a list of field names from 
 * variable declarations. please, see the 
 * Java18 syntax definition. 
 */ 
private list[str] fieldNames(vars) {
   list[str] res = [];
   visit(vars) {
      case(VariableDeclarator)`<VariableDeclaratorId var> = <VariableInitializer init>` : {
         println(var); 
         visit(var) {
           case(Identifier)`<Identifier id>` :  { res = res + unparse(id); }
         }
      }
      case(VariableDeclarator)`<Identifier id> <Dims? d>` : { res = res + unparse(id); }
   }
   return res; 
}

str pp(TypeDeclaration c) = 
 "{
  '  class   : <c.package>.<c.name>
  '  members : []
  '}";
