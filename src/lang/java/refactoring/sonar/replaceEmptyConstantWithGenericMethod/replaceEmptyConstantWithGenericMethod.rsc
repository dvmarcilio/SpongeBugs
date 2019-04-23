module lang::java::refactoring::sonar::replaceEmptyConstantWithGenericMethod::replaceEmptyConstantWithGenericMethod

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import Set;
import lang::java::util::MethodDeclarationUtils;

private set[str] constantsToCheck = {"EMPTY_SET", "EMPTY_LIST", "EMPTY_MAP"};

private bool shouldRewrite = false;

private map[str, str] methodInvocationByConstantName = (
	"EMPTY_SET": "emptySet()",
	"EMPTY_LIST": "emptyList()",
	"EMPTY_MAP": "emptyMap()"
);

public void replaceAllEmptyConstantWithGenericMethods(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			if (shouldContinueWithASTAnalysis(fileLoc)) {
				shouldRewrite = false;
				replaceEmptyConstantWithGenericMethod(fileLoc);	
			}
		} catch: {
			continue;
		}	
	}
}

private bool shouldContinueWithASTAnalysis(loc fileLoc) {
	// incredibly speeding up matching
	javaFileContent = readFile(fileLoc);
	return findFirst(javaFileContent, "Collections.EMPTY") != -1;
}

// FieldAccess = Primary "." Identifier 
public void replaceEmptyConstantWithGenericMethod(loc fileLoc) { 
	unit = retrieveCompilationUnitFromLoc(fileLoc);
	modified = false;
	
	unit = top-down visit(unit) {
		case (MethodDeclaration) `<MethodDeclaration mdl>`: {
			modified = false;
			mdl = visit(mdl) {
				case (ReturnStatement) `return <Expression exp>;`: {
					exp = visit(exp) {
						case (Expression) `Collections.<Identifier constantName>`: {						
							if (isConstantOfInterest("<constantName>")) {
								if (methodHasGenericReturnType(mdl)) {
									modified = true;
									Expression refactored = generateCorrectMethodInvocationFromConstantName("<constantName>");
									insert (Expression) `<Expression refactored>`;
								}
							}
						}
					}
					if (modified) {
						insert (ReturnStatement) `return <Expression exp>;`;
					}
				}
			}
			if (modified) {
				shouldRewrite = true;
				insert (MethodDeclaration) `<MethodDeclaration mdl>`;
			}
		}
	}
	
	if (shouldRewrite) {
		writeFile(fileLoc, unit);
	}	
}

private CompilationUnit retrieveCompilationUnitFromLoc(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	return parse(#CompilationUnit, javaFileContent);
}

private bool isConstantOfInterest(str constName) {
	return constName in constantsToCheck;
}

private bool methodHasGenericReturnType(MethodDeclaration mdl) {
	return findFirst(retrieveMethodReturnTypeAsStr(mdl), "\<") != -1;
}

private Expression generateCorrectMethodInvocationFromConstantName(str constName) {
	return parse(#Expression, "Collections." + methodInvocationByConstantName[constName]);
}