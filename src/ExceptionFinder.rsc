module ExceptionFinder

import IO;
import lang::java::m3::M3Util;
import lang::java::\syntax::Java18;
import ParseTree;
import Set;
import Map;

private map[str, set[str]] superClassesBySubClasses = ();
private set[str] checkedExceptionClasses = {"Exception"};

set[str] findCheckedExceptions(list[loc] locs) {
	for(int i <- [0 .. size(locs)]) {
		location = locs[i];
		content = readFile(location);
		
		try {
				unit = parse(#CompilationUnit, content);

				superClass = retrieveSuperClass(unit);
				
				if (superClass.present) {
					subClassName = retrieveClassNameFromUnit(unit);
					
					//println("Current class (subClass): " + subClassName);
					//println("Super class: " + superClass.name);
					//println("checkedExceptionClasses: " + toString(checkedExceptionClasses));
					//println("superClassesBySubClasses: " + toString(superClassesBySubClasses));
					//println();
					
					// If class extends Exception or class that is a subclass of Exception
				 	if (superClass.name in checkedExceptionClasses) {
						checkedExceptionClasses += subClassName;
						
						if (subClassName in superClassesBySubClasses) {
							println();
							addAllSubClassesOf(subClassName);
						}
						
					} else { // Class has a superClass that we don't know yet if it's a sub class of Exception
						
						// TODO: check if superClass is already a sub class mapped to another superclass
						   
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
	println(checkedExceptionClasses);
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

private void addAllSubClassesOf(str className) {
	set[str] allSubClasses = {};
	allSubClasses += superClassesBySubClasses[className];
	println("className: " + className);
	println("allSubClasses (pre-while): " + toString(allSubClasses)); 
	println("checkedExceptionClasses (pre-while): " + toString(checkedExceptionClasses));
	while(!isEmpty(allSubClasses)) {
		println();
		currentClass = getOneFrom(allSubClasses);
		println("currentClass: " + currentClass);
		checkedExceptionClasses += currentClass;
		println("checkedExceptionClasses: " + toString(checkedExceptionClasses));
		allSubClasses -= currentClass;
		println("allSubClasses (removing current): " + toString(allSubClasses));
		
		if (currentClass in superClassesBySubClasses) {
			directSubClasses = superClassesBySubClasses[currentClass];
			println("directSubClasses: " + toString(directSubClasses));
			allSubClasses += directSubClasses;
			println("allSubClasses (adding direct sub: " + toString(allSubClasses)); 
		}
		
		superClassesBySubClasses = delete(superClassesBySubClasses, currentClass);
	}
	
	
	////println();
	//println("subClassName: " + subClassName);
	////println("directSubClasses: " + toString(directSubClasses));
	////println();
	//
	//list[str] directSubClassesList = toList(directSubClasses);
	//println("directSubClasses: " + toString(directSubClassesList));
	//for(int i <- [0 .. size(directSubClassesList)]) {
	//	addAllSubClassesOf(directSubClassesList[i]);	
	//}
}

private set[str] retrieveDirectSubClasses(str className) {
	return superClassesBySubClasses[className];
}