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
private map[str, FieldDeclaration] fieldDeclarationByStrLiteral = ();
private list[FieldDeclaration] constants = [];

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
	return findFirst(javaFileContent, "static final String") != -1 ||
		findFirst(javaFileContent, "final static String") != -1;
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
	loadConstantMaps(unit);
	
	refactoredClassBody = top-down-break visit(classBody) {
		
		case (FieldDeclaration) `<FieldDeclaration flDecl>`: {
			modified = false;
			flDeclRefactored = flDecl;
			visit(flDecl) {
				case(AdditiveExpression) `<AdditiveExpression concatExp>`: {
					if (isNotUnaryExpression(concatExp)) {
						visit (concatExp) {				
							case (StringLiteral) `<StringLiteral stringLiteral>`: {
								strLiteral = "<stringLiteral>";
								if (isStrLiteralAlreadyDefinedAndOfMinimumSize(strLiteral) && 
										fieldDeclarationByStrLiteral[strLiteral] != flDecl &&
										isNotForwardReference(flDecl, strLiteral)) {
									modified = true;
									constant = constantByStrLiteral[strLiteral];
									flDeclRefactored = parse(#FieldDeclaration, replaceAll("<flDeclRefactored>", strLiteral, constant));
									increaseTimesReplacedByConstant(constant);
								}
							}
						}
					}
				}
			}
			
			if (modified) {
				shouldRewrite = true;
				insert flDeclRefactored;
			}
		}
		
		case (BlockStatement) `<BlockStatement stmt>`: {
			modified = false;
			stmtRefactored = stmt;
			top-down-break visit(stmt) {
				case (StringLiteral) `<StringLiteral stringLiteral>`: {
					strLiteral = "<stringLiteral>";
					if (isStrLiteralAlreadyDefinedAndOfMinimumSize(strLiteral)) {
						modified = true;
						constant = constantByStrLiteral[strLiteral];
						stmtRefactoredStr = replaceAll("<stmt>", strLiteral, constant);
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
	fieldDeclarationByStrLiteral = ();
	constants = [];
	timesReplacedByConstant = ();
}

private void loadConstantMaps(CompilationUnit unit) {
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
					if (shouldConsiderThisConstant(flDecl, constantName, strLiteral)) {
						constantByStrLiteral[strLiteral] = constantName;
						fieldDeclarationByStrLiteral[strLiteral] = flDecl;
						constants += flDecl;
					}
				}
			}
		}
	}
}

private bool shouldConsiderThisConstant(FieldDeclaration flDecl, str constantName, str strLiteral) {
	return !isEmpty(constantName) &&
	 	   !isEmpty(strLiteral) &&
		   isFieldOnlyUsingASingleString(flDecl, constantName, strLiteral) &&
		   // we want to add the first constant, to avoid forward references
		   strLiteral notin fieldDeclarationByStrLiteral;
}

private bool isFieldOnlyUsingASingleString(FieldDeclaration flDecl, str constantName, str strLiteral) {
	return endsWith("<flDecl>", "<constantName> = <strLiteral>;");
}

private void increaseTimesReplacedByConstant(str constant) {
	if (constant in timesReplacedByConstant) {
		timesReplacedByConstant[constant] += 1;	
	} else {
		timesReplacedByConstant[constant] = 1;
	}
}

private bool isStrLiteralAlreadyDefinedAndOfMinimumSize(str strLiteral) {
	return strLiteral in constantByStrLiteral && size(strLiteral) >= SONAR_MINIMUM_LITERAL_LENGTH;
}

private bool isNotForwardReference(FieldDeclaration flDecl, str strLiteral) {
	indexOfCurrConstant = indexOf(constants, flDecl);
	indexOfConstantToUse = indexOf(constants, fieldDeclarationByStrLiteral[strLiteral]);
	
	return indexOfConstantToUse < indexOfCurrConstant;
}

private bool isNotUnaryExpression(AdditiveExpression addExp) {
	try {
		parse(#UnaryExpression, "<addExp>");
		return false;
	} catch:
		return true;
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