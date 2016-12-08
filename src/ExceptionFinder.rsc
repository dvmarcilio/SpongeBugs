module ExceptionFinder

import IO;
import lang::java::m3::M3Util;
import lang::java::\syntax::Java18;
import ParseTree;

set[str] findCheckedExceptions(list[loc] locs) {
	set[str] classesToBeVerified = {};
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
				
			 	if (superClassName in checkedExceptionClasses) {
					className = retrieveClassNameFromUnit(unit);
					checkedExceptionClasses = checkedExceptionClasses + className;
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