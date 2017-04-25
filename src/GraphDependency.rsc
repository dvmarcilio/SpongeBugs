module GraphDependency

import lang::java::\syntax::Java18;
import ParseTree; 

import JavaTypes; 

import IO;
import List;
import String;

data Member = method(str name, str returnType, list[str] args, list[str] thrw, list[str] dependencies)
            | field(str name, str fieldType);

data TypeDeclaration = class(str package, str name, str superClass, list[str] superInterfaces, list[Member] members)
                     | interface(str package, str name, list[str] superInterfaces, list[Member] members)
                     | enum(str package, str name);
                     
/* (utility function) 
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

/* (utility function) 
 * return the list of declared classes from a given package. 
 */
map[str,str] listClassesFromPackage(str package, map[str, tuple[str, str]] decls) {
  list[tuple[str, str]] classes = [<c, k> | k <- decls, <p, c> <- decls[k], p == package];
  map[str, str] res = ();
  for(<c, k> <- classes) {
     res = res + (c:k);
  }
  return res;
} 

/*
 * returns an enriched class table, given a compilation unit. 
 * this class table contains all definitions of classes, interfaces, and 
 * enumerations- plus their dependencies. 
 */
list[TypeDeclaration] classTable(CompilationUnit unit) {
   str package = "";
   list[TypeDeclaration] classes = [];
   visit(unit) {
     case (PackageDeclaration)`package <{Identifier "."}+ ids>;` : { 
        package = unparse(ids); 
     }
     case normalClassDeclaration(mds, id, typeParameters, superClass, superInterfaces, body) : {
        classes = classes + classDeclaration(package, id, superClass, superInterfaces, body);	
     }
     //TODO: complement with interfaces and annotations. 
   }
   return classes;
}

/*
 * returns a specific class declaration. 
 */ 
private TypeDeclaration classDeclaration(package, id, superClass, superInterfaces, body) {
   str super = visitSuperClass(superClass);
   list[str] interfaces = visitSuperInterfaces(superInterfaces);
   list[Member] fields = fieldDeclarations(body);
   list[Member] methods = methodDeclarations(fields, body);
   list[Member] members = fields + methods; 
   return class(package, unparse(id), super, interfaces, members);
}

/*
 * returns the super class of a class as string. 
 */ 
str visitSuperClass(superClass) {
  str res = "Object"; 
  visit(superClass) {
    case(Superclass)`extends <ClassType t>` : { res = trim(unparse(t)); }
  };
  return res;
} 

/*
 * returns the super interfaces of a class as a list of strings. 
 */ 
list[str] visitSuperInterfaces(superInterfaces) {
   list[str] res = []; 
   visit(superInterfaces) {
     case (Superinterfaces)`implements <{InterfaceType ","}+ ins>` : { 
       res = split(",", trim(unparse(ins))); 
     }
   }
   return res;
}

/*
 * returns the field declarations from a class body.   
 */
private list[Member] fieldDeclarations(body) {
   list[Member] deps = [];
   visit(body) {
      case (FieldDeclaration)`<FieldModifier* mds> <UnannType fieldType> <VariableDeclaratorList vars>;` : { 
         str t = referenceType(fieldType);
         list[str] names = fieldNames(vars);
         deps = deps + [field(n, t) | n <-names];
      }
   }    
   return deps;  
}

/*
 * returns the method declarations from a class body. 
 * it uses a list of field declarations to build an initial 
 * symbol table that is considered for building the method 
 * dependencies. 
 */ 
private list[Member] methodDeclarations(fields, body) {
  map[str, str] symbolTable = ();
  list[Member] methods = []; 
  //initialize the simble table from fields. 
  for(Member f <- fields) {
     switch(f) {
       case field(n, t) : { symbolTable = (n:t) + symbolTable; }
     }
  }
  //visit the class body to retrieve the list of method declarations.  
  visit(body) {
    case(MethodDeclaration)`<MethodModifier* mds> <Result res> <Identifier id>(<{FormalParameter ","}+ pmts>) <Dims? d> <Throws? thrw> <MethodBody mb>` : {
       map[str,str] args = argumentDeclarations(pmts);
       symbolTable = symbolTable + args + localVariableDeclarations(mb);
       list[str] dps = methodCallDependencies(mb, symbolTable);
       //TODO: exceptions
       methods = methods + method(unparse(id), referenceType(res), [args[p] | p<- args], [], dps);
    }
    case(MethodDeclaration)`<MethodModifier* mds> <Result res> <Identifier id>() <Dims? d> <Throws? thrw> <MethodBody mb>` : {
       symbolTable = symbolTable + localVariableDeclarations(mb);
       list[str] dps = methodCallDependencies(mb, symbolTable);
       //TODO: exceptions
       methods = methods + method(unparse(id), referenceType(res), [], [], dps);
    }
    //TODO: method declarations with lastFormalArgs.
  }
  return methods;
}

/*
 * returns a map from argument names into types. 
 */
map[str, str] argumentDeclarations(pmts) {
  map[str, str] args = ();
  visit(pmts)  {    
    case (FormalParameter)`<VariableModifier* mds> <UnannType t> <Identifier v>` : {
        str t = referenceType(t);
        str p = unparse(v);
        args = (p:t) + args;
      }
    }
  return args;  
}
/*
 * from a method body, this function returns a map from variable names into 
 * types. 
 */ 
private map[str, str] localVariableDeclarations(methodBody) {
   map[str, str] symbolTable = ();
 
   visit(methodBody) {
     case (LocalVariableDeclaration)`<VariableModifier* mds> <UnannType varType> <VariableDeclaratorList vars>` : {
       str t = referenceType(varType);
       list[str] names = fieldNames(vars);
       for(n <- names) {
         symbol = (n:t) + symbolTable;
       }
     }
   }
   return symbolTable;
}

/*
 * returns the method call dependencies. 
 */
list[str] methodCallDependencies(mb, symbolTable) {
   list [str] deps = []; 
   visit(mb) {
     case (MethodInvocation)`<Identifier id> . <Identifier m> (<ArgumentList? args>)`: {
       str objId = unparse(id);
       if(objId in symbolTable) {
          objId = symbolTable[objId];
       }
       else {
          objId = "-";
       }          
       deps = deps + (objId + "." + unparse(m));
    }
  }
  return deps; 
}

/*
 * retrieves the type name from an reference type. if the type t 
 * is not a reference type, it returns the string "primitive-type". 
 */
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
         visit(var) {
           case(Identifier)`<Identifier id>` :  { res = res + unparse(id); }
         }
      }
      case(VariableDeclarator)`<Identifier id> <Dims? d>` : { res = res + unparse(id); }
   }
   return res; 
}

str pp(TypeDeclaration decl) {
  switch(decl) {
    case class(p, n, s, i, members) : { 
       return pp(p, n, s, i, members); 
    } 
    default: return "";
  }  
}

str pp(Member m) { 
 str res = "";
 switch(m) {
   case field(name, fieldType) : { 
     res = "<fieldType> <name>"; 
   }
   case method(name, rt, args, excs, deps) : {
      res = "<rt> <name>(<args>)";
   }
 }
 return res;
} 

list[str] dependencies(Member m) {
   list[str] res = [];
   switch(m) {
     case method(name, rt, args, excs, deps) : {
        res = deps;
     }
   }
   return res;
}

str ppName(Member m) {
  str res = "";
  switch(m) {
   case field(name, fieldType) : { 
     res = "<name>"; 
   }
   case method(name, rt, args, excs, deps) : {
      res = "<name>";
   }
 }
 return res;
}
str pp(package, name, superClass, interfaces, members) = 
 "{
  '  class   : <package>.<name>
  '  extends : <superClass> 
  '  implements: <interfaces>
  '}";
  
    //'  members : [<for(m <- members){>
  //'               <pp(m)>,
  //'            <}>]
  //' dependencies = [
  //'                <for(m <- members){>
  //'                  <ppName(m)> : <dependencies(m)>
  //'                <}>] 
