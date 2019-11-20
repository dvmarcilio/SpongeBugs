module lang::java::refactoring::sonar::stringLiteralDuplicated::StringLiteralsAlreadyDefinedAsConstant

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import List;
import Map;
import Set;

// Sonar considers minimum length of 5 + 2 (quotes)
private int SONAR_MINIMUM_LITERAL_LENGTH = 7;

private map[str, str] constantByStrLiteral = ();

private bool shouldRewrite = false;

private bool shouldWriteLog = false;

private loc logPath;

private str detailedLogFileName = "STRING_LITERAL_DUPLICATED_DETAILED_2.txt";
private str countLogFileName = "STRING_LITERAL_DUPLICATED_COUNT_2.txt";

private map[str, int] timesReplacedByConstant = ();

public void allStringLiteralsAlreadyDefinedAsConstant(list[loc] locs) {
	shouldWriteLog = false;
	doAllStringLiteralsAlreadyDefinedAsConstant(locs);
}

private void doAllStringLiteralsAlreadyDefinedAsConstant(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			if (shouldContinueWithASTAnalysis(fileLoc)) {
				refactorForEachClassBody(fileLoc);
			}
		} catch: {
			println("Exception file (StringLiteralsAlreadyDefinedAsConstant): <fileLoc.file>");
			continue;
		}
	}
}

public void allStringLiteralsAlreadyDefinedAsConstant(list[loc] locs, loc logPathArg) {
	shouldWriteLog = true;
	logPath = logPathArg;
	doAllStringLiteralsAlreadyDefinedAsConstant(locs);
}

private bool shouldContinueWithASTAnalysis(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	return findFirst(javaFileContent, "private static final String") != -1;
}

private void refactorForEachClassBody(loc fileLoc) {
	unit = retrieveCompilationUnitFromLoc(fileLoc);
	for(classBody <- retrieveClassBodies(unit)) {
		resetState();
		doRefactorForEachClassBody(fileLoc, unit, classBody);
		unit = retrieveCompilationUnitFromLoc(fileLoc);		
	}	
}

private CompilationUnit retrieveCompilationUnitFromLoc(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	return parse(#CompilationUnit, javaFileContent);
}

private list[ClassBody] retrieveClassBodies(CompilationUnit unit) {
	list[ClassBody] classBodies = [];
	bottom-up-break visit(unit) {
		case (ClassBody) `<ClassBody classBody>`: { 
			classBodies += classBody;
		}
	}
	return classBodies;
}

private void doRefactorForEachClassBody(loc fileLoc, CompilationUnit unit, ClassBody classBody) {
	loadConstantByStrLiteral(unit);
	
	refactoredClassBody = top-down-break visit(classBody) {
		case (BlockStatement) `<BlockStatement stmt>`: {
			modified = false;
			stmtRefactored = stmt;
			top-down-break visit(stmt) {
				case (StringLiteral) `<StringLiteral strLiteral>`: {
					strLiteralAsStr = "<strLiteral>";
					if (strLiteralAsStr in constantByStrLiteral && size(strLiteralAsStr) >= SONAR_MINIMUM_LITERAL_LENGTH) {
						modified = true;
						constant = constantByStrLiteral[strLiteralAsStr];
						stmtRefactoredStr = replaceAll("<stmt>", strLiteralAsStr, constant);
						stmtRefactored = parse(#BlockStatement, stmtRefactoredStr);
						increaseTimesReplacedByConstant(constant);
					}
				}
			}
			if (modified) {
				shouldRewrite = true;
				insert stmtRefactored;
			}
		}
	}
	
	if (shouldRewrite) {
		unit = top-down-break visit(unit) {
			case (ClassBody) `<ClassBody possibleClassBodyToRefactor>`: {
				if(possibleClassBodyToRefactor == classBody)
					insert refactoredClassBody;
			}
		}
		
		writeFile(fileLoc, unit);
		writeLog(fileLoc);
		
	}
}

private void resetState() {
	shouldRewrite = false;
	constantByStrLiteral = ();
	definedConstants = [];
	timesReplacedByConstant = ();
}

private void loadConstantByStrLiteral(CompilationUnit unit) {
	top-down visit(unit) {
		case (FieldDeclaration) `<FieldDeclaration flDecl>`: {
			top-down-break visit (flDecl) {
				case (FieldDeclaration) `<FieldModifier* varMod> String <VariableDeclaratorList vdl>;`: {
					constantName = "";
					strLiteral = "";
					if (contains("<varMod>", "static") && contains("<varMod>", "final")) {
						visit(vdl) {
							case (VariableDeclaratorId) `<Identifier varId> <Dims? dims>`: {
								constantName = "<varId>";
							}
							case (StringLiteral) `<StringLiteral stringLiteral>`: {
								strLiteral = "<stringLiteral>";
							}
						}
					}
					if (!isEmpty(constantName) && !isEmpty(strLiteral)) {
						constantByStrLiteral[strLiteral] = constantName;
					}
				}
			}
		}
	}
}

private void increaseTimesReplacedByConstant(str constant) {
	if (constant in timesReplacedByConstant) {
		timesReplacedByConstant[constant] += 1;	
	} else {
		timesReplacedByConstant[constant] = 1;
	}
}

private void writeLog(loc fileLoc) {
	if (shouldWriteLog)
		doWriteLog(fileLoc);
}

private void doWriteLog(loc fileLoc) {
	if (!exists(logPath))
		mkDirectory(logPath);
	
	detailedLogMap = createDetailedLogMap(fileLoc);	
	detailedFilePath = logPath + detailedLogFileName;
	writeToLogFile(detailedLogMap, detailedFilePath);
	
	writetoCountLogFile(fileLoc);
}

private map[str, list[str]] createDetailedLogMap(loc fileLoc) {
	filePathStr = fileLoc.authority + fileLoc.path;
	map[str, list[str]] logMap = ();
	logMap[filePathStr] = [];
	
	for (constant <- domain(timesReplacedByConstant)) {
		times = timesReplacedByConstant[constant]; 
		logMap[filePathStr] += "Replaced <times> literal(s) for <constant>";
	}
	
	return logMap;
}

private void writeToLogFile(map[str, list[str]] detailedLogMap, loc filePath) {
	mapStr = toString(detailedLogMap);
	if (exists(filePath))
		appendToFile(filePath, "\n" + mapStr);
	else
		writeFile(filePath, mapStr);
}

private void writetoCountLogFile(loc fileLoc) {
	filePathStr = fileLoc.authority + fileLoc.path;
	countFilePath = logPath + countLogFileName;
	
	timesReplaced = 0;
	for (constant <- domain(timesReplacedByConstant)) {
		timesReplaced += timesReplacedByConstant[constant];
	}
	
	filePathStr = fileLoc.authority + fileLoc.path;
	countStr = "<filePathStr>: <timesReplaced>";
	
	writeToLogFile(countStr, countFilePath);
} 

private void writeToLogFile(str countStr, loc fileLoc) {
	if (exists(fileLoc))
		appendToFile(fileLoc, "\n" + countStr);
	else
		writeFile(fileLoc, countStr);
}