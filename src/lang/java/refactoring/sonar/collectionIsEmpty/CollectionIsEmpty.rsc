module lang::java::refactoring::sonar::collectionIsEmpty::CollectionIsEmpty

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import lang::java::util::CompilationUnitUtils;
import lang::java::refactoring::forloop::ClassFieldsFinder;
import lang::java::refactoring::forloop::LocalVariablesFinder;
import lang::java::refactoring::forloop::MethodVar;
import lang::java::refactoring::sonar::LogUtils;
import lang::java::util::MethodDeclarationUtils;

private bool shouldWriteLog = false;

private loc logPath;

private str detailedLogFileName = "COLLECTION_IS_EMPTY_DETAILED.txt";
private str countLogFileName = "COLLECTION_IS_EMPTY_COUNT.txt";

private map[str, int] timesReplacedByScope = ();

public void refactorAllToCollectionIsEmpty(list[loc] locs, loc logPathArg) {
	shouldWriteLog = true;
	logPath = logPathArg;
	doRefactorAllToCollectionIsEmpty(locs);
}

public void refactorAllToCollectionIsEmpty(list[loc] locs) {
	shouldWriteLog = false;
	doRefactorAllToCollectionIsEmpty(locs);
}

private void doRefactorAllToCollectionIsEmpty(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			if (shouldContinueWithASTAnalysis(fileLoc)) {
				doRefactorCollectionIsEmpty(fileLoc);
			}
		} catch: {
			println("Exception file (CollectionIsEmpty): " + fileLoc.file);
			continue;
		}	
	}
}

private bool shouldContinueWithASTAnalysis(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	return findFirst(javaFileContent, "import java.util.") != -1 && hasSizeComparison(javaFileContent);
}

private bool hasSizeComparison(str javaFileContent) {
	return findFirst(javaFileContent, ".size() \> 0")  != -1  ||
	 	   findFirst(javaFileContent, ".size() \>= 1") != -1  ||
		   findFirst(javaFileContent, ".size() != 0")  != -1  ||
		   findFirst(javaFileContent, ".size() == 0")  != -1;
}

public void refactorCollectionIsEmpty(loc fileLoc) {
	shouldWriteLog = false;
	doRefactorCollectionIsEmpty(fileLoc);
}

public void refactorCollectionIsEmpty(loc fileLoc, loc logPathArg) {
	shouldWriteLog = true;
	logPath = logPathArg;
	doRefactorCollectionIsEmpty(fileLoc);
}

private void doRefactorCollectionIsEmpty(loc fileLoc) {
	unit = retrieveCompilationUnitFromLoc(fileLoc);
	
	shouldRewrite = false;
	timesReplacedByScope = ();
	
	unit = top-down visit(unit) {
		// we are missing lambda bodies here
		case (MethodDeclaration) `<MethodDeclaration mdl>`: {
			methodSignature = retrieveMethodSignature(mdl);
		
			mdl = visit(mdl) {
				case (EqualityExpression) `<ExpressionName beforeFunc>.size() == 0`: {
					if (isBeforeFuncReferencingACollection(beforeFunc, mdl, unit)) {
						shouldRewrite = true;
						countModificationForLog(methodSignature);
						insert parse(#EqualityExpression, "<beforeFunc>.isEmpty()");
					}
				}
				case (EqualityExpression) `<ExpressionName beforeFunc>.size() != 0`: {
					if (isBeforeFuncReferencingACollection(beforeFunc, mdl, unit)) {
						shouldRewrite = true;
						countModificationForLog(methodSignature);
						insert parse(#EqualityExpression, "!<beforeFunc>.isEmpty()");
					}
				}
				case (RelationalExpression) `<ExpressionName beforeFunc>.size() \> 0`: {
					if (isBeforeFuncReferencingACollection(beforeFunc, mdl, unit)) {
						shouldRewrite = true;
						countModificationForLog(methodSignature);
						insert parse(#RelationalExpression, "!<beforeFunc>.isEmpty()");
					}
				}
				case (RelationalExpression) `<ExpressionName beforeFunc>.size() \>= 1`: {
					if (isBeforeFuncReferencingACollection(beforeFunc, mdl, unit)) {
						shouldRewrite = true;
						countModificationForLog(methodSignature);
						insert parse(#RelationalExpression, "!<beforeFunc>.isEmpty()");
					}
				}
			}
			if (shouldRewrite) {
				insert mdl;
			}
		}
	}
	
	if (shouldRewrite) {
		writeFile(fileLoc, unit);
		doWriteLog(fileLoc);
	}
}

private bool isBeforeFuncReferencingACollection(ExpressionName beforeFunc, MethodDeclaration mdl, CompilationUnit unit) {
	visit (mdl) {
		case (MethodDeclaration) `<MethodModifier* mds> <MethodHeader methodHeader> <MethodBody mBody>`: {
			try {
				set[MethodVar] vars = findLocalVariables(methodHeader, mBody) + findClassFields(unit);
				MethodVar var = findByName(vars, trim("<beforeFunc>"));
				return isCollection(var);
			} catch EmptySet(): {
				return false;
			}
		}
	}
	return false;
}

private void countModificationForLog(str scope) {
	if (scope in timesReplacedByScope) {
		timesReplacedByScope[scope] += 1;
	} else {
		timesReplacedByScope[scope] = 1;
	}
}

private void doWriteLog(loc fileLoc) {
	if (shouldWriteLog)
		writeLog(fileLoc, logPath, detailedLogFileName, countLogFileName, timesReplacedByScope);
}