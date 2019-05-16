module lang::java::util::CompilationUnitUtils

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;

public CompilationUnit retrieveCompilationUnitFromLoc(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	return parse(#CompilationUnit, javaFileContent);
}

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

public CompilationUnit addImport(CompilationUnit unit, list[ImportDeclaration] importDecls, str importPackageOrType) {
	importDecls += parse(#ImportDeclaration, "import <importPackageOrType>;");
	importDeclsStrs = [ unparse(importDecl) | ImportDeclaration importDecl <- importDecls ];
	unit = top-down-break visit(unit) {
		case Imports _ => parse(#Imports, intercalate("\n", importDeclsStrs))
	}
	return unit;
}