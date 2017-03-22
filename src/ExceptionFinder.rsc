module ExceptionFinder

import IO;
import lang::java::m3::M3Util;
import lang::java::\syntax::Java18;
import ParseTree;
import Set;
import Map;
import util::Math;

private map[str, set[str]] superClassesBySubClasses = ();
private set[str] checkedExceptionClasses = {"Exception"};
private list[loc] fileLocationsThatCouldNotBeParsed = [];

private data ClassAndSuperClass = classAndSuperClass(str className, str superClassName);

private bool printAllFileNamesThatCouldNotBeParsed = false;

set[str] findCheckedExceptions(list[loc] javaFilesLocations) {
	initializeClassesFound();
	for(javaFileLocation <- javaFilesLocations)
		tryToVisitFileLookingForClassesWithSubClasses(javaFileLocation);
	
	printJavaFilesThatCouldNotBeParsed();
	return checkedExceptionClasses;
}

private void initializeClassesFound() {
	superClassesBySubClasses = ();
	checkedExceptionClasses = {"Exception"};
	fileLocationsThatCouldNotBeParsed = [];
}

private void tryToVisitFileLookingForClassesWithSubClasses(loc javaFileLocation) {
	javaFileContent = readFile(javaFileLocation);
	try
		visitFileLookingForClassesWithSubClasses(javaFileContent);
	catch:
		fileLocationsThatCouldNotBeParsed += javaFileLocation;
}

private void visitFileLookingForClassesWithSubClasses(str javaFileContent) {
	compilationUnit = parse(#CompilationUnit, javaFileContent);
	classesAndSuperClasses = retrieveClassesAndSuperClassesFromCompilationUnit(compilationUnit);
	for(classAndSuperClass <- classesAndSuperClasses)
		handleIfClassIsAnException(classAndSuperClass);
}

private list[ClassAndSuperClass] retrieveClassesAndSuperClassesFromCompilationUnit(compilationUnit) {
	list[ClassAndSuperClass] classesAndSuperClasses = [];
	visit(compilationUnit) {
		case(NormalClassDeclaration) `<ClassModifier* _> class <Identifier className> <TypeParameters? _> extends <Identifier superClassName> <Superinterfaces? _> <ClassBody _>`:
			classesAndSuperClasses += classAndSuperClass(unparse(className), unparse(superClassName));
	}
	return classesAndSuperClasses;
}

private void handleIfClassIsAnException(ClassAndSuperClass cas) {
 	if (cas.superClassName in checkedExceptionClasses)
		addClassAndItsSubClassesAsExceptions(cas.className);
	else    
		addClassAsASubClassOfItsSuperClass(cas);
}

private void addClassAndItsSubClassesAsExceptions(str className) {
	checkedExceptionClasses += className;				
	if (className in superClassesBySubClasses)
		addAllSubClassesOf(className);
}

private void addClassAsASubClassOfItsSuperClass(ClassAndSuperClass cas) {
	if (cas.superClassName in superClassesBySubClasses)
		superClassesBySubClasses[cas.superClassName] += {cas.className};
 	else 
		superClassesBySubClasses[cas.superClassName] = {cas.className};
}

private void addAllSubClassesOf(str className) {
	directSubClasses = getAllDirectSubClassesOf(className);
	checkedExceptionClasses += directSubClasses;
	superClassesBySubClasses = delete(superClassesBySubClasses, className);

	for (str className <- directSubClasses)
		addAllSubClassesOf(className); 
}

private set[str] getAllDirectSubClassesOf(str className) {
	directSubClasses = {};
	if (className in superClassesBySubClasses)
		directSubClasses = superClassesBySubClasses[className];
	return directSubClasses;
}

private void printJavaFilesThatCouldNotBeParsed() {
	if (printAllFileNamesThatCouldNotBeParsed) {
		str filesNotParsedCount = toString(size(fileLocationsThatCouldNotBeParsed));
		println(filesNotParsedCount + " Java File Locations that could not be parsed. ");
	
		for(fileLoc <- fileLocationsThatCouldNotBeParsed)
			print(fileLoc.file + ", ");
		println();
	}
	
	println();
}