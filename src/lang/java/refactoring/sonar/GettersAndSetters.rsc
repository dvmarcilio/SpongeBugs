module lang::java::refactoring::sonar::GettersAndSetters

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import util::Math;
import List;

// debugging
public void findGetters(list[loc] locs) {
	list[MethodDeclaration] getters = [];
	for(fileLoc <- locs) {
		javaFileContent = readFile(fileLoc);
		try {
			unit = parse(#CompilationUnit, javaFileContent);
			getters += retrieveGetterMethods(unit);
		} catch:
			continue;
	}
}

public list[MethodDeclaration] retrieveGetterMethods(CompilationUnit unit) {
	list [MethodDeclaration] getters = [];
	visit(unit) {
		case MethodDeclaration mdl: {
			if (isGetterMethod(mdl)) getters += mdl;
		}
	}
	//if (size(getters) > 0) {
	//	println("size: " + toString(size(getters)));
	//	for (getter <- getters) {
	//		println("<getter>");
	//	}
	//	println();		
	//}
	return getters;
}


private bool isGetterMethod(MethodDeclaration mdl) {
	top-down visit(mdl) {
		case MethodModifier mdf: {
			if ("<mdf>" != "public") return false;
		}
		
		case MethodDeclarator mDecl: {
			if (!startsWith("<mDecl>", "get")) return false;
		}
	}
	return true;
} 

public list[MethodDeclaration] retrieveSetterMethods(CompilationUnit unit) {

}