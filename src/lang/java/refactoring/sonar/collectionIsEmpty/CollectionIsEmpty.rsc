module lang::java::refactoring::sonar::collectionIsEmpty::CollectionIsEmpty

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import lang::java::util::CompilationUnitUtils;
import lang::java::refactoring::forloop::ClassFieldsFinder;
import lang::java::refactoring::forloop::LocalVariablesFinder;
import lang::java::refactoring::forloop::MethodVar;

private bool shouldRewrite = false;

public void refactorAllToCollectionIsEmpty(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			if (shouldContinueWithASTAnalysis(fileLoc)) {
				shouldRewrite = false;
				refactorCollectionIsEmpty(fileLoc);
			}
		} catch: {
			println("Exception file: " + fileLoc.file);
			continue;
		}	
	}
}

private bool shouldContinueWithASTAnalysis(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	return findFirst(javaFileContent, "import java.util.") != -1 && hasSizeComparison(javaFileContent);
}

private bool hasSizeComparison(str javaFileContent) {
	return findFirst(javaFileContent, ".size() \> 0") != -1 ||
		   findFirst(javaFileContent, ".size() != 0") != -1 ||
		   findFirst(javaFileContent, ".size() == 0") != -1;
}

public void refactorCollectionIsEmpty(loc fileLoc) {
	unit = retrieveCompilationUnitFromLoc(fileLoc);
	
	unit = top-down visit(unit) {
		case (MethodDeclaration) `<MethodDeclaration mdl>`: {
			modified = false;
			mdl = bottom-up-break visit(mdl) {
				case (Expression) `<EqualityExpression equalityExpression>`: {
					Expression refactoredExp = parse(#Expression, "<equalityExpression>");
					equalityExpression = visit(equalityExpression) {
						case (EqualityExpression) `<ExpressionName beforeFunc>.size() == 0`: {
							if (isBeforeFuncReferencingACollection(beforeFunc, mdl, unit)) {
								modified = true;
								refactoredExp = parse(#Expression, "<beforeFunc>.isEmpty()");
							}
						}
						case (EqualityExpression) `<ExpressionName beforeFunc>.size() != 0`: {
							if (isBeforeFuncReferencingACollection(beforeFunc, mdl, unit)) {
								modified = true;
								refactoredExp = parse(#Expression, "!<beforeFunc>.isEmpty()");
							}
						}
						case (RelationalExpression) `<ExpressionName beforeFunc>.size() \> 0`: {
							if (isBeforeFuncReferencingACollection(beforeFunc, mdl, unit)) {
								modified = true;
								refactoredExp = parse(#Expression, "!<beforeFunc>.isEmpty()");
							}
						}
					}
					if (modified) {
						insert refactoredExp;
					}
				}
			}
			if (modified) {
				shouldRewrite = true;
				insert mdl;
			}
		}
	}
	
	if (shouldRewrite) {
		writeFile(fileLoc, unit);
	}
}

private bool isBeforeFuncReferencingACollection(ExpressionName beforeFunc, MethodDeclaration mdl, CompilationUnit unit) {
	visit (mdl) {
		case (MethodDeclaration) `<MethodModifier* mds> <MethodHeader methodHeader> <MethodBody mBody>`: {
			try {
				set[MethodVar] vars = findLocalVariables(methodHeader, mBody) + findClassFields(unit);
				MethodVar var = findByName(vars, "<beforeFunc>");
				return isCollection(var);
			} catch EmptySet(): {
				return false;
			}
		}
	}
	return false;
}