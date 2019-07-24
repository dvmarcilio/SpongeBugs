module lang::java::refactoring::sonar::replaceEmptyConstantWithGenericMethod::replaceEmptyConstantWithGenericMethod

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import Set;
import lang::java::util::MethodDeclarationUtils;
import lang::java::util::CompilationUnitUtils;

private set[str] constantsToCheck = {"EMPTY_SET", "EMPTY_LIST", "EMPTY_MAP"};

private set[str] collections = {"List", "ArrayList", "LinkedList", "Set", "HashSet", "LinkedHashSet",
	 "TreeSet", "Queue", "Stack", "SortedSet", "EnumSet", "ArrayDeque", "ConcurrentLinkedDeque", "ConcurrentLinkedQueue",
	 "Vector", "Deque", "NavigableSet"};

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
								if (methodReturnsACollection(mdl)) {
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


private bool isConstantOfInterest(str constName) {
	return constName in constantsToCheck;
}

private bool methodReturnsACollection(MethodDeclaration mdl) {
	methodReturn = retrieveMethodReturnTypeAsStr(mdl);
	for (collectionType <- collections) {
		if (startsWith(methodReturn, collectionType))
			return true;
	}
	return false;
}

private Expression generateCorrectMethodInvocationFromConstantName(str constName) {
	return parse(#Expression, "Collections." + methodInvocationByConstantName[constName]);
}