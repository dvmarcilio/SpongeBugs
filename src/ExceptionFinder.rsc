module ExceptionFinder

import IO;
import lang::java::m3::M3Util;
import lang::java::\syntax::Java18;
import ParseTree;
import Map;

private map[str, set[str]] superClassesBySubClasses = ();
private set[str] checkedExceptionClasses = {"Exception"};

set[str] findCheckedExceptions(list[loc] locs) {
	for(int i <- [0 .. size(locs) - 1]) {
		location = locs[i];
		content = readFile(location);
		
		try {
				unit = parse(#CompilationUnit, content);

				superClass = retrieveSuperClass(unit);
				
				if (superClass.present) {
					subClassName = retrieveClassNameFromUnit(unit);
					
					// If class extends Exception or class that is a subclass of Exception
				 	if (superClass.name in checkedExceptionClasses) {
						checkedExceptionClasses += subClassName;
						
						
						if (subClassName in superClassesBySubClasses) {
							// All subClasses of class extends Exception indirectly
							checkedExceptionClasses += superClassesBySubClasses[subClassName];
							delete(superClassesBySubClasses, subClassName);
						}
						
					} else { // Class has a superClass that we don't know yet if it's a sub class of Exception
						if (superClass.name in superClassesBySubClasses) {
							superClassesBySubClasses[superClass.name] += {subClassName};
						} else {
							superClassesBySubClasses[superClass.name] = {subClassName};
						}
					}
				}
				
		} catch: 
			continue;
		
		
	}
	return checkedExceptionClasses;
}

private tuple[bool present, str name] retrieveSuperClass(unit) {
	tuple[bool present, str name] SuperClass = <false, "">;
	visit(unit) {
		case(Superclass) `extends <Identifier id>`: {
			SuperClass.present = true;
			SuperClass.name = unparse(id);
		}
	}
	return SuperClass;
}


private str retrieveClassNameFromUnit(unit) {
	visit(unit) {
		case(NormalClassDeclaration) `<ClassModifier _> class <Identifier id> <TypeParameters? _> <Superclass? _> <Superinterfaces? _> <ClassBody _>`:
			return unparse(id);
	}
	// Not the best solution. quick workaround
	throw "Could not find class name";
}