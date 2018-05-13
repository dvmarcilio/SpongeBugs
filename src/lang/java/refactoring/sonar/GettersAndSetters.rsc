module lang::java::refactoring::sonar::GettersAndSetters

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import util::Math;
import List;

public data GettersAndSetters = newGettersAndSetters(list[MethodDeclaration] getters, list[MethodDeclaration] setters);

private data GetterOrSetter = newGetterOrSetter(bool isGetter, bool isSetter);

public void findGettersAndSettersFunctional(list[loc] locs) {
	GettersAndSetters gettersAndSetters = newGettersAndSetters([], []);
	
	for(fileLoc <- locs) {
		javaFileContent = readFile(fileLoc);
		try {
			unit = parse(#CompilationUnit, javaFileContent);
			currGettersAndSetters = retrieveGettersAndSettersFunctional(unit);
			gettersAndSetters.getters += currGettersAndSetters.getters;
			gettersAndSetters.setters += currGettersAndSetters.setters;
		} catch:
			continue;
	}
	
	printGettersAndSetters(gettersAndSetters);
}

public GettersAndSetters retrieveGettersAndSettersFunctional(CompilationUnit unit) {
	return doRetrieveGettersAndSettersFunctional(unit, isGetter, isSetter);
}

public GettersAndSetters doRetrieveGettersAndSettersFunctional(CompilationUnit unit,
 bool (MethodHeader) getterChecker, bool (MethodHeader) setterChecker) {
	list [MethodDeclaration] getters = [];
	list [MethodDeclaration] setters = [];
	top-down visit(unit) {
		case MethodDeclaration mdl: {
			top-down-break visit(mdl) {		
				case (MethodDeclaration) `<Annotation _> public <MethodHeader mHeader> <MethodBody _>`: {
					if(getterChecker(mHeader))
						getters += mdl;
					else if(setterChecker(mHeader))
						setters += mdl;
				}
				case (MethodDeclaration) `public <MethodHeader mHeader> <MethodBody _>`: {
					if(getterChecker(mHeader))
						getters += mdl;
					else if(setterChecker(mHeader))
						setters += mdl;
				}
			}
		}
	}
	return newGettersAndSetters(getters, setters);
}

public bool isGetter(MethodHeader mHeader) {
	top-down-break visit(mHeader) {
		case Result returnType: {
			if ("<returnType>" == "void")
				return false;
		}
		case MethodDeclarator mDecl: {
			return startsWith("<mDecl>", "get");
		}
	}
	return false;
}

public bool isSetter(MethodHeader mHeader) {
	top-down-break visit(mHeader) {
		case Result returnType: {
			if ("<returnType>" != "void")
				return false;
		}
		case MethodDeclarator mDecl: {
			return startsWith("<mDecl>", "set");
		}
	}
	return false;
}

public str retrieveReturnTypeFromMethodDeclaration(MethodDeclaration mdl) {
	visit(mdl) {
		case Result result:
			return "<result>";		
	}
}


public void printGettersAndSetters(GettersAndSetters gas) {
	println(toString(size(gas.getters)) + " getters");
	for (getter <- gas.getters) {
		println("-------");
		println("<getter>");
		println("Return Type: " + retrieveReturnTypeFromMethodDeclaration(getter));
	}
	println();
	println(toString(size(gas.setters)) + " setters");
	for (setter <- gas.setters) {
		println("-------");
		println("<setter>");
		println("Return Type: " + retrieveReturnTypeFromMethodDeclaration(setter));
	}
}
