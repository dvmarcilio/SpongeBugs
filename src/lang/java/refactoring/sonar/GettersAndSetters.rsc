module lang::java::refactoring::sonar::GettersAndSetters

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import util::Math;
import List;

public data GettersAndSetters = newGettersAndSetters(list[MethodDeclaration] getters, list[MethodDeclaration] setters);

private data GetterOrSetter = newGetterOrSetter(bool isGetter, bool isSetter);

// debugging
public void findGettersAndSetters(list[loc] locs) {
	GettersAndSetters gettersAndSetters = newGettersAndSetters([], []);
	
	for(fileLoc <- locs) {
		javaFileContent = readFile(fileLoc);
		try {
			unit = parse(#CompilationUnit, javaFileContent);
			currGettersAndSetters = retrieveGetterOrSetters(unit);
			gettersAndSetters.getters += currGettersAndSetters.getters;
			gettersAndSetters.setters += currGettersAndSetters.setters;
		} catch:
			continue;
	}
	
	println(size(gettersAndSetters.getters));
	println(size(gettersAndSetters.setters));
}

public GettersAndSetters retrieveGetterOrSetters(CompilationUnit unit) {
	list [MethodDeclaration] getters = [];
	list [MethodDeclaration] setters = [];
	visit(unit) {
		case MethodDeclaration mdl: {
			top-down-break visit(mdl) {		
				case (MethodDeclaration) `public <MethodHeader mHeader> <MethodBody _>`: {
					getterOrSetter = checkIfGetterOrSetter(mHeader);
					if(getterOrSetter.isGetter)
						getters += mdl;
					else if(getterOrSetter.isSetter)
						setters += mdl;
				}
			}
		}
	}
	return newGettersAndSetters(getters, setters);
}

private GetterOrSetter checkIfGetterOrSetter(MethodHeader methodHeader) {
	GetterOrSetter getterOrSetter = newGetterOrSetter(false, false);
	top-down-break visit(methodHeader) {
		case MethodDeclarator mDecl: {
			mDeclStr = "<mDecl>";
			if (startsWith(mDeclStr, "get"))
				getterOrSetter.isGetter = true;
			else if(startsWith(mDeclStr, "set"))
				getterOrSetter.isSetter = true;
		}	
	}
	return getterOrSetter;
}
