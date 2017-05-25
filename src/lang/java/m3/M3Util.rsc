module lang::java::m3::M3Util

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

import IO;
import String; 
import List;

import io::IOUtil;

/**
 * List all class files from a given location. 
 * This location might be either a directory, a jar 
 * filer, a zip file or a .class file.  
 *
 * listAllClassFiles(|jar:///Users/rbonifacio/Documents/workspace-rascal/rascal-Java8/lib/rt.jar!|);
 */ 
list[loc] listAllClassFiles(loc location) {
    return findAllFiles(location, "class");
}

map[str, map[str,str]] classesHierarchy(list[loc] classPath) {
   list[M3] models = createM3FromClassPath(classPath); 
   map[str, map[str,str]] res = ();
   for(m <- models) {
     for(<C,S> <- m@extends) {
        p = packageFromFullQualifiedName(javaPathSeparator(C));
        c = typeNameFromFullQualifiedName(javaPathSeparator(C)); 
        s = javaPathSeparator(S);
        if(p in res) {
           res[p] += (c:s); 
        }
        else {
           map[str, str] v = (c:s);
           res += (p : v);
        }
     }
   }
   return res; 
   //return ( p : <c, s>  
   //       | m <- models
   //       , <C, S> <- m@extends
   //       , c := typeNameFromFullQualifiedName(javaPathSeparator(C))
   //       , s := javaPathSeparator(S)
   //       , p := packageFromFullQualifiedName(javaPathSeparator(C)));
}



private str javaPathSeparator(loc l) { 
  return replaceFirst(replaceAll(l.path, "/", "."), ".", "");
}

private str typeNameFromFullQualifiedName(str fullQualifiedName) {
   return last(split(".", fullQualifiedName));
}

private str packageFromFullQualifiedName(str fullQualifiedName) {
   int idx = findLast(fullQualifiedName, ".");
   if(idx > 0) return substring(fullQualifiedName, 0, idx);
   else return fullQualifiedName;
}

/*
 * computes a list of class names from a classpath, 
 * that is, a list of Jar files. 
 */ 
list[str] classesFromClassPath(list[loc] classPath) {
   list[M3] models = createM3FromClassPath(classPath);
   return [ replaceFirst(replaceAll(N.path, "/", "."), ".", "") | m <- models, <N, S> <- m@declarations, N.scheme == "java+class"];
}

/*
 * computes a list of class names from a classpath, 
 * that is, a list of Jar files. 
 */ 
list[str] interfacesFromClassPath(list[loc] classPath) {
   list[M3] models = createM3FromClassPath(classPath);
   println([e | m <- models, e <- m@extends]);
   return [ replaceFirst(replaceAll(N.path, "/", "."), ".", "") | m <- models, <N, S> <- m@declarations, N.scheme == "java+interface"];
}

/* Auxiliarly functions */ 

list[M3] createM3FromClassPath(list[loc] locations) {
   list[loc] classes = [ c | l <- locations,  c <- listAllClassFiles(l) ];
   return [ createM3FromJarClass(c) | c <- classes ];
}

list[loc] listAllJavaFiles(loc location) {
	return findAllFiles(location, "java");
}