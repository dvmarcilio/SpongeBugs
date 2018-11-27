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

public void stringLiteral(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	unit = parse(#CompilationUnit, javaFileContent);
	populateMapsWithStringsOfInterestThatOccurEqualOrGreaterThanMinimum(unit);
	refactorDuplicatedOccurrencesToUseConstant(fileLoc, unit);
}

private void populateMapsWithStringsOfInterestThatOccurEqualOrGreaterThanMinimum(unit) {
	populateMapsWithStringsOfInterestCount(unit);
	filterMapsWithOnlyOccurrencesEqualOrGreaterThanMinimum();
	populateMapOfStmtsToBeRefactored();
}

private void populateMapsWithStringsOfInterestCount(CompilationUnit unit) {
	top-down-break visit(unit) {
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
	countByStringLiterals = (stringLiteral : countByStringLiterals[stringLiteral]
			| stringLiteral <- countByStringLiterals,
			countByStringLiterals[stringLiteral] >= SONAR_MINIMUM_DUPLICATED_COUNT);
	stringLiteralsToRemove = stmtsByStringLiterals - countByStringLiterals;
	stmtsByStringLiterals = stmtsByStringLiterals - stringLiteralsToRemove;
}

private void populateMapOfStmtsToBeRefactored() {
	stmtsToBeRefactored = { *stmts |
		 set[StatementWithoutTrailingSubstatement] stmts <- range(stmtsByStringLiterals) };
}

private void refactorDuplicatedOccurrencesToUseConstant(loc fileLoc, CompilationUnit unit) {
	if (!isEmpty(countByStringLiterals)) {
		set[str] strLiterals = domain(countByStringLiterals);
		generateConstantNamesForEachStrLiteral(unit, strLiterals);
		populateOriginalAndRefactoredStmts(strLiterals);
		refactorOriginalToRefactoredStmts(fileLoc, unit);
	}
}

// FIXME Right now we can't verify a Constant name that is inherited
// will fail on rare situations when the name of the constant is already defined (by inheritance) in this case
private void generateConstantNamesForEachStrLiteral(CompilationUnit unit, set[str] strLiterals) {
	set[str] alreadyDefinedConstantNames = retrieveThisClassConstantNames(unit);
	for (strLiteral <- strLiterals) {
		constantNameForThisStrLiteral = stringValueToConstantName(strLiteral);
		count = 1;
		while (constantNameForThisStrLiteral in alreadyDefinedConstantNames) {
			count += 1;
			constantNameForThisStrLiteral += "_<count>";
		}
		constantByStrLiteral[strLiteral] = constantNameForThisStrLiteral;
	}
}

private set[str] retrieveThisClassConstantNames(CompilationUnit unit) {
	set[str] constantNames = {};
	top-down visit(unit) {
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

private void populateOriginalAndRefactoredStmts(strLiterals) {
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
				stmtRefactored = parse(#StatementWithoutTrailingSubstatement, stmtReplacedStringLiteralWithConstant);
				refactoredByOriginalStmts[stmtToBeRefactored] = stmtRefactored;		
			}
		}
	}	
}

private void refactorOriginalToRefactoredStmts(loc fileLoc, CompilationUnit unit) {
	unit = addNeededConstants(unit);
	unit = changeStatementsToUseConstants(unit);
	writeFile(fileLoc, unit);
}

// what if CompilationUnit has multiple Class Bodies?
private CompilationUnit addNeededConstants(CompilationUnit unit) {
	unit = top-down-break visit(unit) {
		case (ClassBody) `<ClassBody classBody>`: {
			str classBodyStr = "<classBody>";
			ClassBody classBodyWithConstants = parse(#ClassBody, addConstantsToClassBody(classBodyStr));
			insert (ClassBody) `<ClassBody classBodyWithConstants>`;
		}
	}
	return unit;
}

private str addConstantsToClassBody(str classBodyStr) {
	if (isEmpty(alreadyDefinedConstants)) {
		return addNeededConstantsAtTheBegginingOfClassBody(classBodyStr);
	}
	return addNeededConstantsAfterLastAlreadyDefinedConstant(classBodyStr);
}

private str addNeededConstantsAtTheBegginingOfClassBody(str classBodyStr) {
	return replaceFirst(classBodyStr, "{", "{\n" + generateConstantsToBeAddedAsStr());
}

// unformatted (no indentation)
private str generateConstantsToBeAddedAsStr() {
	list[FieldDeclaration] constantsToBeAdded = createNeededConstants();
	constantsToBeAddedStrs = [ unparse(constantToBeAdded) | FieldDeclaration constantToBeAdded <- constantsToBeAdded ];
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

private str addNeededConstantsAfterLastAlreadyDefinedConstant(str classBodyStr) {
	FieldDeclaration lastConstantAlreadyDefined = last(alreadyDefinedConstants);
	str lastConstantAlreadyDefinedStr = "<lastConstantAlreadyDefined>";
	return replaceFirst(classBodyStr, lastConstantAlreadyDefinedStr, lastConstantAlreadyDefinedStr + "\n" + generateConstantsToBeAddedAsStr());
}

private CompilationUnit changeStatementsToUseConstants(CompilationUnit unit) {
	unit = top-down visit(unit) {
		case (StatementWithoutTrailingSubstatement) `<StatementWithoutTrailingSubstatement stmt>`: {
			if (stmt in refactoredByOriginalStmts) {
				refactored = refactoredByOriginalStmts[stmt];
				insert (StatementWithoutTrailingSubstatement) `<StatementWithoutTrailingSubstatement refactored>`;
			}
		}
	}
	return unit;
}
