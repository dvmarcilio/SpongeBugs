module lang::java::refactoring::sonar::stringLiteralDuplicated::StringLiteralDuplicated

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import Map;
import Set;

// XXX when defining the constant, need to check already defined constants.
// can´t give the same name

private int SONAR_MINIMUM_DUPLICATED_COUNT = 3;

// Sonar considers minimum length of 5 + 2 (quotes)
private int SONAR_MINIMUM_LITERAL_LENGTH = 7;

private map[str, int] countByStringLiterals = ();
private map[str, set[StatementWithoutTrailingSubstatement]] stmtsByStringLiterals = ();

public void stringLiteral(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	unit = parse(#CompilationUnit, javaFileContent);
	populateMapsWithStringsOfInterestThatOccurEqualOrGreaterThanMinimum(unit);
}

private void populateMapsWithStringsOfInterestThatOccurEqualOrGreaterThanMinimum(unit) {
	populateMapsWithStringsOfInterestCount(unit);
	filterMapsWithOnlyOccurrencesEqualOrGreaterThanMinimum();
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
}