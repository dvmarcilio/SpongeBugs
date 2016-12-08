module ExceptionFinder

import IO;
import lang::java::m3::M3Util;
import lang::java::\syntax::Java18;
import ParseTree;
import Map;

set[str] findCheckedExceptions(list[loc] locs) {
	map[str, set[str]] superClassesBySubClasses = ();
	set[str] checkedExceptionClasses = {"Exception"};
	for(int i <- [0 .. size(locs) - 1]) {
		location = locs[i];
		content = readFile(location);
		
		try {
				unit = parse(#CompilationUnit, content);
				
				bool unitHasSuperClass = false;
				str superClassName = "";
				visit(unit) {
					case(Superclass) `extends <Identifier id>`: {
						unitHasSuperClass = true;
						superClassName = unparse(id);
					}
				}
				
				if (unitHasSuperClass) {
					subClassName = retrieveClassNameFromUnit(unit);
				 	if (superClassName in checkedExceptionClasses) {
						checkedExceptionClasses += subClassName;
						
						if (subClassName in superClassesBySubClasses) {
							checkedExceptionClasses += superClassesBySubClasses[subClassName];
							delete(superClassesBySubClasses, subClassName);
						}
						
					} else {
						if (superClassName in superClassesBySubClasses) {
							superClassesBySubClasses[superClassName] += {subClassName};
						} else {
							superClassesBySubClasses[superClassName] = {subClassName};
						}
					}
				}
				
		} catch: 
			continue;
		
		
	}
	return checkedExceptionClasses;
}

str retrieveClassNameFromUnit(unit) {
	visit(unit) {
		case(NormalClassDeclaration) `<ClassModifier _> class <Identifier id> <TypeParameters? _> <Superclass? _> <Superinterfaces? _> <ClassBody _>`:
			return unparse(id);
	}
	// Not the best solution. quick workaround
	throw "Could not find class name";
}