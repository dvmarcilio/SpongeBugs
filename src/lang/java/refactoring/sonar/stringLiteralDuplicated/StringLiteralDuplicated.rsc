module lang::java::refactoring::sonar::stringLiteralDuplicated::StringLiteralDuplicated

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import Map;
import Set;

import lang::java::refactoring::sonar::stringLiteralDuplicated::StringValueToConstantName;

private int SONAR_MINIMUM_DUPLICATED_COUNT = 3;

// Sonar considers minimum length of 5 + 2 (quotes)
private int SONAR_MINIMUM_LITERAL_LENGTH = 7;

private map[str, int] countByStringLiterals = ();

private map[str, set[StatementWithoutTrailingSubstatement]] stmtsByStringLiterals = ();

private set[StatementWithoutTrailingSubstatement] stmtsToBeRefactored = {};

private map[str, str] constantByStrLiteral = ();

private map[StatementWithoutTrailingSubstatement, StatementWithoutTrailingSubstatement] refactoredByOriginalStmts = ();

private list[FieldDeclaration] alreadyDefinedConstants = [];

public void stringLiteralDuplicated(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			transformStringLiteralDuplicated(fileLoc);
		} catch: {
			println("Exception file: " + fileLoc.file);
			continue;
		}	
	}
}

public void transformStringLiteralDuplicated(loc fileLoc) {
	unit = retrieveCompilationUnitFromLoc(fileLoc);
	refactorForEachClassBody(fileLoc, unit);
}

private CompilationUnit retrieveCompilationUnitFromLoc(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	return parse(#CompilationUnit, javaFileContent);
}

private void refactorForEachClassBody(loc fileLoc, CompilationUnit unit) { 
	for(classBody <- retrieveClassBodies(unit)) {
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
	stmtsToBeRefactored = {};
	constantByStrLiteral = ();
	refactoredByOriginalStmts = ();
	alreadyDefinedConstants = [];
}

private void populateMapsWithStringsOfInterestThatOccurEqualOrGreaterThanMinimum(ClassBody classBody) {
	populateMapsWithStringsOfInterestCount(classBody);
	filterMapsWithOnlyOccurrencesEqualOrGreaterThanMinimum();
	populateMapOfStmtsToBeRefactored();
}

private void populateMapsWithStringsOfInterestCount(ClassBody classBody) {
	top-down-break visit(classBody) {
		case (StatementWithoutTrailingSubstatement) `<StatementWithoutTrailingSubstatement stmt>`: {
			top-down-break visit(stmt) {
				case (StringLiteral) `<StringLiteral strLiteral>`: {
					strLiteralAsStr = "<strLiteral>";
					if (size(strLiteralAsStr) > SONAR_MINIMUM_LITERAL_LENGTH) {
						increaseStringLiteralCount(strLiteralAsStr);
						addStmtToStringLiteralsStmts(strLiteralAsStr, stmt);
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

private void addStmtToStringLiteralsStmts(str strLiteral, StatementWithoutTrailingSubstatement stmt) {
	if (strLiteral in stmtsByStringLiterals) {
		stmtsByStringLiterals[strLiteral] += {stmt};
	} else {
		stmtsByStringLiterals[strLiteral] = {stmt};
	}
}

private void filterMapsWithOnlyOccurrencesEqualOrGreaterThanMinimum() {
	countByStringLiterals = (stringLiteral : countByStringLiterals[stringLiteral] | 
			stringLiteral <- countByStringLiterals,
			countByStringLiterals[stringLiteral] >= SONAR_MINIMUM_DUPLICATED_COUNT);
			
	stringLiteralsToRemove = stmtsByStringLiterals - countByStringLiterals;
	stmtsByStringLiterals = stmtsByStringLiterals - stringLiteralsToRemove;
}

private void populateMapOfStmtsToBeRefactored() {
	stmtsToBeRefactored = { *stmts |
		 set[StatementWithoutTrailingSubstatement] stmts <- range(stmtsByStringLiterals) };
}

private void refactorDuplicatedOccurrencesToUseConstant(loc fileLoc, CompilationUnit unit, ClassBody classBody) {
	if (!isEmpty(countByStringLiterals)) {
		set[str] strLiterals = domain(countByStringLiterals);
		generateConstantNamesForEachStrLiteral(classBody, strLiterals);
		populateOriginalAndRefactoredStmts(strLiterals);
		refactorOriginalToRefactoredStmts(fileLoc, unit, classBody);
	}
}

// FIXME Right now we can't verify a Constant name that is inherited
// will fail on rare situations when the name of the constant is already defined (by inheritance) in this case
private void generateConstantNamesForEachStrLiteral(ClassBody classBody, set[str] strLiterals) {
	set[str] alreadyDefinedConstantsNamesAndGenerated = retrieveThisClassConstantNames(classBody);
	for (strLiteral <- strLiterals) {
		constantNameForThisStrLiteral = stringValueToConstantName(strLiteral);
		count = 1;
		while (constantNameForThisStrLiteral in alreadyDefinedConstantsNamesAndGenerated) {
			count += 1;
			constantNameForThisStrLiteral += "_<count>";
		}
		constantByStrLiteral[strLiteral] = constantNameForThisStrLiteral;
		alreadyDefinedConstantsNamesAndGenerated += constantNameForThisStrLiteral;
	}
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
				stmtRefactored = parse(#StatementWithoutTrailingSubstatement, stmtReplacedStringLiteralWithConstant);
				refactoredByOriginalStmts[stmtToBeRefactored] = stmtRefactored;		
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
	return "\n" + intercalate("\n", constantsToBeAddedStrs);
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
		case (StatementWithoutTrailingSubstatement) `<StatementWithoutTrailingSubstatement stmt>`: {
			if (stmt in refactoredByOriginalStmts) {
				refactored = refactoredByOriginalStmts[stmt];
				insert (StatementWithoutTrailingSubstatement) `<StatementWithoutTrailingSubstatement refactored>`;
			}
		}
	}
	return classBody;
}
