module lang::java::m3::M3Util

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

import IO;
import String; 

import io::IOUtil;

/**
 * List all class files from a given location. 
 * This location might be either a directory, a jar 
 * filer, a zip file or a .class file.  
 */ 
list[loc] listAllClassFiles(loc location) {
    return findAllFiles(location, "class");
}

list[loc] listAllJavaFiles(loc location) {
	return findAllFiles(location, "java");
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
   println("*******************");
   return [ replaceFirst(replaceAll(N.path, "/", "."), ".", "") | m <- models, <N, S> <- m@declarations, N.scheme == "java+interface"];
}

/* Auxiliarly functions */ 

private list[M3] createM3FromClassPath(list[loc] locations) {
   list[loc] classes = [ c | l <- locations,  c <- listAllClassFiles(l) ];
   return [ createM3FromJarClass(c) | c <- classes ];
}
