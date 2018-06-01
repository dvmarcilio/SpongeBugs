module lang::java::util::CompilationUnitUtils

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;

public list[ImportDeclaration] retrieveImportDeclarations(CompilationUnit unit) {
	importDecls = [];
	top-down visit(unit) {
		case ImportDeclaration importDecl:
			importDecls += importDecl;
	}
	return importDecls;
}

public bool isImportPresent(CompilationUnit unit, str importStrs...) {
	top-down visit(unit) {
		case ImportDeclaration importDecl: {
			for (importStr <- importStrs) {
				if (contains("<importDecl>", importStr))
					return true;
			}
		}
	}
	
	return false;
}

public bool isImportPresent(list[ImportDeclaration] importDecls, str importStrs...) {
	for(importDecl <- importDecls) {
		for(importStr <- importStrs) {
			if(contains("<importDecl>", importStr))
				return true;
		}
	}
	return false;
}