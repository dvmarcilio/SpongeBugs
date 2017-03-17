module ExceptionFinder

import IO;
import lang::java::m3::M3Util;
import lang::java::\syntax::Java18;
import ParseTree;
import Set;
import Map;

private map[str, set[str]] superClassesBySubClasses;
private set[str] checkedExceptionClasses;

set[str] findCheckedExceptions(list[loc] javaFilesLocations) {
	initializeClassesFound();
	for(javaFileLocation <- javaFilesLocations) {
		javaFileContent = readFile(javaFileLocation);
		tryToNavigateClassesFindingSubClassesOfException(javaFileContent);
	}
	return checkedExceptionClasses;
}

private void initializeClassesFound() {
	superClassesBySubClasses = ();
	checkedExceptionClasses = {"Exception"};
}

private void tryToNavigateClassesFindingSubClassesOfException(str javaFileContent) {
	try {
			compilationUnit = parse(#CompilationUnit, javaFileContent);
			handleIfClassHasASuperClass(compilationUnit);
		} catch: 
			continue;
}

private void handleIfClassHasASuperClass(unit) {
	superClass = retrieveSuperClass(unit);
	if (superClass.present) {
		className = retrieveClassNameFromUnit(unit);
		handleIfClassIsAnException(className, superClass.name);
	}
}

private tuple[bool present, str name] retrieveSuperClass(unit) {
	tuple[bool present, str name] superClass = <false, "">;
	visit(unit) {
		case(Superclass) `extends <Identifier id>`: {
			superClass.present = true;
			superClass.name = unparse(id);
		}
	}
	return superClass;
}

private str retrieveClassNameFromUnit(unit) {
	visit(unit) {
		case(NormalClassDeclaration) `<ClassModifier* _> class <Identifier id> <TypeParameters? _> <Superclass? _> <Superinterfaces? _> <ClassBody _>`:
			return unparse(id);
	}
	// Not the best solution. quick workaround
	throw "Could not find class name";
}

private void handleIfClassIsAnException(str className, str superClassName) {
 	if (superClassName in checkedExceptionClasses)
		addClassAndItsSubClassesAsExceptions(className);
	else    
		addClassAsASubClassOfItsSuperClass(className, superClassName);
}

private void addClassAndItsSubClassesAsExceptions(str className) {
	checkedExceptionClasses += className;				
	if (className in superClassesBySubClasses)
		addAllSubClassesOf(className);
}

private void addClassAsASubClassOfItsSuperClass(str className, str superClassName) {
	if (superClassName in superClassesBySubClasses)
		superClassesBySubClasses[superClassName] += {className};
 	else 
		superClassesBySubClasses[superClassName] = {className};
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