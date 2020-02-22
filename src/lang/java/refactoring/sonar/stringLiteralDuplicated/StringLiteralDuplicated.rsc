module lang::java::refactoring::sonar::stringLiteralDuplicated::StringLiteralDuplicated

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import List;
import Map;
import Set;
import Location;

import lang::java::refactoring::sonar::stringLiteralDuplicated::StringValueToConstantName;

private str DEFAULT_IDENTATION = "    ";

private int SONAR_MINIMUM_DUPLICATED_COUNT = 3;

// facilitate review, can be modified later
private int MAXIMUM_CONSTANTS_TO_CONSIDER = 999;

// Sonar considers minimum length of 5 + 2 (quotes)
private int SONAR_MINIMUM_LITERAL_LENGTH = 7;

private map[str, int] countByStringLiterals = ();

private map[str, set[BlockStatement]] stmtsByStringLiterals = ();
private map[str, set[FieldDeclaration]] fieldsByStringLiterals = ();

private set[BlockStatement] stmtsToBeRefactored = {};
private set[FieldDeclaration] fieldsToBeRefactored = {};

private map[str, str] constantByStrLiteral = ();

private map[BlockStatement, BlockStatement] refactoredByOriginalStmts = ();
private map[FieldDeclaration, FieldDeclaration] refactoredByOriginalFields = ();

private list[FieldDeclaration] alreadyDefinedConstants = [];

private bool shouldWriteLog = false;

private loc logPath; 

private str detailedLogFileName = "STRING_LITERAL_DUPLICATED_DETAILED.txt";
private str countLogFileName = "STRING_LITERAL_DUPLICATED_COUNT.txt";

private str unitStr = "";

public void stringLiteralDuplicated(list[loc] locs) {
	shouldWriteLog = false;
	doStringLiteralDuplicated(locs);
}

private void doStringLiteralDuplicated(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			doTransformStringLiteralDuplicated(fileLoc);
		} catch: {
			println("Exception file: " + fileLoc.file);
			continue;
		}	
	}
}

public void stringLiteralDuplicated(list[loc] locs, loc logPathArg) {
	shouldWriteLog = true;
	logPath = logPathArg;
	doStringLiteralDuplicated(locs);
}

public void transformStringLiteralDuplicated(loc fileLoc) {
	shouldWriteLog = false;
	doTransformStringLiteralDuplicated(fileLoc);	
}

private void doTransformStringLiteralDuplicated(loc fileLoc) {
	unit = retrieveCompilationUnitFromLoc(fileLoc);
	refactorForEachClassBody(fileLoc, unit);
}

public void transformStringLiteralDuplicated(loc fileLoc, loc logPathArg) {
	shouldWriteLog = true;
	logPath = logPathArg;
	doTransformStringLiteralDuplicated(fileLoc);
}

private CompilationUnit retrieveCompilationUnitFromLoc(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	return parse(#CompilationUnit, javaFileContent);
}

private void refactorForEachClassBody(loc fileLoc, CompilationUnit unit) { 
	for(classBody <- retrieveClassBodies(unit)) {
		unitStr = "<unit>";
		doRefactorForEachClassBody(fileLoc, unit, classBody);
		unit = retrieveCompilationUnitFromLoc(fileLoc);
	}	
}

private list[ClassBody] retrieveClassBodies(CompilationUnit unit) {
	list[ClassBody] classBodies = [];
	top-down-break visit(unit) {
		case (ClassBody) `<ClassBody classBody>`: { 
			classBodies += classBody;
		}
	}
	return classBodies;
}

private void doRefactorForEachClassBody(loc fileLoc, CompilationUnit unit, ClassBody classBody) {
	resetFieldsToInitialState();
	populateMapsWithStringsOfInterestThatOccurEqualOrGreaterThanMinimum(classBody);
	refactorDuplicatedOccurrencesToUseConstant(fileLoc, unit, classBody);
}

private void resetFieldsToInitialState() {
	countByStringLiterals = ();
	stmtsByStringLiterals = ();
	fieldsByStringLiterals = ();
	
	stmtsToBeRefactored = {};
	fieldsToBeRefactored = {};
	
	constantByStrLiteral = ();
	refactoredByOriginalStmts = ();
	refactoredByOriginalFields = ();
	
	alreadyDefinedConstants = [];
}

private void populateMapsWithStringsOfInterestThatOccurEqualOrGreaterThanMinimum(ClassBody classBody) {
	populateMapsWithStringsOfInterestCount(classBody);
	filterMapsWithOnlyOccurrencesEqualOrGreaterThanMinimum();
	populateMapOfStmtsToBeRefactored();
}

private void populateMapsWithStringsOfInterestCount(ClassBody classBody) {
	top-down-break visit(classBody) {
		case (BlockStatement) `<BlockStatement stmt>`: {
			top-down-break visit(stmt) {
				case (StringLiteral) `<StringLiteral strLiteral>`: {
					strLiteralAsStr = "<strLiteral>";
					if (size(strLiteralAsStr) >= SONAR_MINIMUM_LITERAL_LENGTH) {
						increaseStringLiteralCount(strLiteralAsStr);
						addStmtToStringLiteralsStmts(strLiteralAsStr, stmt);
					}
				}


			}
		}

		case (FieldDeclaration) `<FieldDeclaration flDecl>`: {
			top-down-break visit(flDecl) {
				case(AdditiveExpression) `<AdditiveExpression concatExp>`: {
					if (isNotUnaryExpression(concatExp)) {
						visit (concatExp) {
							case (StringLiteral) `<StringLiteral strLiteral>`: {
								strLiteralAsStr = "<strLiteral>";
								if (size(strLiteralAsStr) >= SONAR_MINIMUM_LITERAL_LENGTH) {
									increaseStringLiteralCount(strLiteralAsStr);
									addFieldToStringLiteralsFields(strLiteralAsStr, flDecl);
								}
							}
						}
					}
				}
				case (ArgumentList) `<ArgumentList argList>`: {
					top-down-break visit(argList) {
						case (StringLiteral) `<StringLiteral strLiteral>`: {
							strLiteralAsStr = "<strLiteral>";
							if (size(strLiteralAsStr) >= SONAR_MINIMUM_LITERAL_LENGTH) {
								increaseStringLiteralCount(strLiteralAsStr);
								addFieldToStringLiteralsFields(strLiteralAsStr, flDecl);
							}
						}
					}
				}
			}
		}
		
	}
}

private void increaseStringLiteralCount(str strLiteral) {
	if (strLiteral in countByStringLiterals) {
		countByStringLiterals[strLiteral] += 1;
	} else {
		countByStringLiterals[strLiteral] = 1;
	}
}

private void addStmtToStringLiteralsStmts(str strLiteral, BlockStatement stmt) {
	if (strLiteral in stmtsByStringLiterals) {
		stmtsByStringLiterals[strLiteral] += {stmt};
	} else {
		stmtsByStringLiterals[strLiteral] = {stmt};
	}
}

private void addFieldToStringLiteralsFields(str strLiteral, FieldDeclaration field) {
	if (strLiteral in fieldsByStringLiterals) {
		fieldsByStringLiterals[strLiteral] += {field};
	} else {
		fieldsByStringLiterals[strLiteral] = {field};
	}
}

private void filterMapsWithOnlyOccurrencesEqualOrGreaterThanMinimum() {
	countByStringLiterals = (stringLiteral : countByStringLiterals[stringLiteral] | 
			stringLiteral <- countByStringLiterals,
			countByStringLiterals[stringLiteral] >= SONAR_MINIMUM_DUPLICATED_COUNT);
			
	stringLiteralsToRemove = stmtsByStringLiterals - countByStringLiterals;
	stmtsByStringLiterals = stmtsByStringLiterals - stringLiteralsToRemove;
	
	fieldsByStringLiteralsToRemove = fieldsByStringLiterals - countByStringLiterals;
	fieldsByStringLiterals = fieldsByStringLiterals - fieldsByStringLiteralsToRemove;
}

private void populateMapOfStmtsToBeRefactored() {
	stmtsToBeRefactored = { *stmts |
		 set[BlockStatement] stmts <- range(stmtsByStringLiterals) };
	
	fieldsToBeRefactored = { *fields |
		 set[FieldDeclaration] fields <- range(fieldsByStringLiterals) };
}

private void refactorDuplicatedOccurrencesToUseConstant(loc fileLoc, CompilationUnit unit, ClassBody classBody) {
	if (!isEmpty(countByStringLiterals)) {
		set[str] strLiterals = domain(countByStringLiterals);
		generateConstantNamesForEachStrLiteral(classBody, strLiterals);
		populateOriginalAndRefactoredStmts(strLiterals);
		refactorOriginalToRefactoredStmts(fileLoc, unit, classBody);
	}
}

private void generateConstantNamesForEachStrLiteral(ClassBody classBody, set[str] strLiterals) {
	set[str] alreadyDefinedConstantsNamesAndGenerated = retrieveThisClassConstantNames(classBody);
	classHasExtendsStr = findFirst(unitStr, "extends") != -1;
	for (strLiteral <- strLiterals) {
		constantNameForThisStrLiteral = stringValueToConstantName(strLiteral);
		count = 1;
		while (constantNameForThisStrLiteral in alreadyDefinedConstantsNamesAndGenerated
				|| unitHasPotentialConstantName(classHasExtendsStr, constantNameForThisStrLiteral)) {
			count += 1;
			constantNameForThisStrLiteral += "_<count>";
		}
		constantByStrLiteral[strLiteral] = constantNameForThisStrLiteral;
		alreadyDefinedConstantsNamesAndGenerated += constantNameForThisStrLiteral;
	}
}

private bool unitHasPotentialConstantName(bool classHasExtendsStr, str constantNameForThisStrLiteral) {
	return classHasExtendsStr && findFirst(unitStr, constantNameForThisStrLiteral) != -1;
}

private set[str] retrieveThisClassConstantNames(ClassBody classBody) {
	set[str] constantNames = {};
	top-down visit(classBody) {
		case (FieldDeclaration) `<FieldDeclaration flDecl>`: {
			top-down-break visit (flDecl) {
				case (FieldDeclaration) `<FieldModifier* varMod> <UnannType _> <VariableDeclaratorList vdl>;`: {
					if (contains("<varMod>", "static") && contains("<varMod>", "final")) {
						// saving FieldDeclarations for further adding new constants
						alreadyDefinedConstants += flDecl;
						visit(vdl) {
							case (VariableDeclaratorId) `<Identifier varId> <Dims? dims>`: {
								constantNames += "<varId>";
							}
						}
					}
				}
			}
		}
	}
	return constantNames;
}

private void populateOriginalAndRefactoredStmts(set[str] strLiterals) {
	// for each stmt(n), try to replace all string literals(m)
	// O(n * m) - disregarding cost of replaceAll() and etc
	for(stmtToBeRefactored <- stmtsToBeRefactored) {
		for(strLiteral <- strLiterals) {
			str stmtToBeRefactoredStr = "<stmtToBeRefactored>";
			
			if (stmtToBeRefactored in domain(refactoredByOriginalStmts)) {
				stmtToBeRefactoredStr = unparse(refactoredByOriginalStmts[stmtToBeRefactored]);
			}
			
			if (findFirst(stmtToBeRefactoredStr, strLiteral) != -1) {
				str constantName = constantByStrLiteral["<strLiteral>"];
				str stmtReplacedStringLiteralWithConstant = replaceAll(stmtToBeRefactoredStr, strLiteral, constantName);
				//str stmtWithConstantAndOneLessNonNls = removeNonNlsCommentsForEclipse(stmtReplacedStringLiteralWithConstant);
				stmtRefactored = parse(#BlockStatement, stmtReplacedStringLiteralWithConstant);
				refactoredByOriginalStmts[stmtToBeRefactored] = stmtRefactored;		
			}
		}
	}
	
	for(fieldToBeRefactored <- fieldsToBeRefactored) {
		for(strLiteral <- strLiterals) {
			str fieldToBeRefactoredStr = "<fieldToBeRefactored>";
			
			if (fieldToBeRefactored in domain(refactoredByOriginalFields)) {
				fieldToBeRefactoredStr = unparse(refactoredByOriginalFields[fieldToBeRefactored]);
			}
			
			if (findFirst(fieldToBeRefactoredStr, strLiteral) != -1) {
				str constantName = constantByStrLiteral["<strLiteral>"];
				str fieldReplacedStringLiteralWithConstant = replaceAll(fieldToBeRefactoredStr, strLiteral, constantName);
				//str stmtWithConstantAndOneLessNonNls = removeNonNlsCommentsForEclipse(stmtReplacedStringLiteralWithConstant);
				fieldRefactored = parse(#FieldDeclaration, fieldReplacedStringLiteralWithConstant);
				refactoredByOriginalFields[fieldToBeRefactored] = fieldRefactored;
			}
		}
	}
	
	
}

private str removeNonNlsCommentsForEclipse(str stmtReplaced) {
	indexLastNonNls = findLast(stmtReplaced, "//$NON-NLS-");
	if (indexLastNonNls != -1) {
		println("found NON-NLS");
		println(substring(stmtReplaced, 0, indexLastNonNls - 1));
		return substring(stmtReplaced, 0, indexLastNonNls - 1);
	}
	return stmtReplaced;
}

private void refactorOriginalToRefactoredStmts(loc fileLoc, CompilationUnit unit, ClassBody classBody) {
	ClassBody classBodyRefactored = addNeededConstants(classBody);
	classBodyRefactored = changeStatementsToUseConstants(classBodyRefactored);
	
	unit = visit(unit) {
		case (ClassBody) `<ClassBody clb>`: {
			if (clb == classBody) {
				insert (ClassBody) `<ClassBody classBodyRefactored>`;
			}
		}
	}
	
	writeFile(fileLoc, unit);
	writeLog(fileLoc);
}

private ClassBody addNeededConstants(ClassBody classBody) {
	return parse(#ClassBody, addNeededConstantsAtTheBegginingOfClassBody("<classBody>"));
}

// Always adding constants at the beggining of the class to make it easier
private str addNeededConstantsAtTheBegginingOfClassBody(str classBodyStr) {
	return replaceFirst(classBodyStr, "{", "{\n" + generateConstantsToBeAddedAsStr());
}

// unformatted (no indentation)
private str generateConstantsToBeAddedAsStr() {
	list[FieldDeclaration] constantsToBeAdded = createNeededConstants();
	constantsToBeAddedStrs = [ unparse(constantToBeAdded) | FieldDeclaration constantToBeAdded <- constantsToBeAdded ];
	// only for eclipse
	//constantsToBeAddedStrs = [ const + " //$NON-NLS-1$" | str const <- constantsToBeAddedStrs ];
	constantsToBeAddedStrs = [ DEFAULT_IDENTATION + const | str const <- constantsToBeAddedStrs ];
	
	count = size(constantsToBeAddedStrs);
	if (count > MAXIMUM_CONSTANTS_TO_CONSIDER)
		throw "Not fixing because <count> constants were transformed. (maximum <MAXIMUM_CONSTANTS_TO_CONSIDER>)";
	
	return "\n" + intercalate("\n", constantsToBeAddedStrs) + "\n";
}

private list[FieldDeclaration] createNeededConstants() {
	set[str] constantValuesToBeCreated = domain(constantByStrLiteral);
	list[FieldDeclaration] constantsToBeAdded = [];
	for (constantValueToBeAdded <- constantValuesToBeCreated) {
		// making sure we are creating syntatically correct constants
		constantsToBeAdded += parse(#FieldDeclaration, 
			"private static final String <constantByStrLiteral[constantValueToBeAdded]> = <constantValueToBeAdded>;");
	}
	return constantsToBeAdded;
}

private ClassBody changeStatementsToUseConstants(ClassBody classBody) {
	classBody = top-down visit(classBody) {
		case (BlockStatement) `<BlockStatement stmt>`: {
			if (stmt in refactoredByOriginalStmts) {
				refactored = refactoredByOriginalStmts[stmt];
				insert (BlockStatement) `<BlockStatement refactored>`;
			}
		}
		
		case (FieldDeclaration) `<FieldDeclaration flDecl>`: {
			if (flDecl in refactoredByOriginalFields) {
				refactored = refactoredByOriginalFields[flDecl];
				insert (FieldDeclaration) `<FieldDeclaration refactored>`;
			}
		}
	}
	return classBody;
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
	
	filePathStr = fileLoc.authority + fileLoc.path;
	countFilePath = logPath + countLogFileName;
	countLogStr = "<filePathStr>: <size(range(constantByStrLiteral))>";
	writeToLogFile(countLogStr, countFilePath);

}

private map[str, list[str]] createDetailedLogMap(loc fileLoc) {
	filePathStr = fileLoc.authority + fileLoc.path;
	map[str, list[str]] logMap = ();
	logMap[filePathStr] = [];
	
	for (constantCreated <- range(constantByStrLiteral)) {
		logMap[filePathStr] += "Created constant <constantCreated>";
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

private void writeToLogFile(str countStr, loc filePath) {
	if (exists(filePath))
		appendToFile(filePath, "\n" + countStr);
	else
		writeFile(filePath, countStr);
}