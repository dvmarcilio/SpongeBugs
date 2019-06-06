module lang::java::refactoring::sonar::stringLiteralDuplicated::\test::StringValueToConstantNameTest

import lang::java::refactoring::sonar::stringLiteralDuplicated::StringValueToConstantName;
import IO;

public test bool shouldSnakeCaseCapitalizedSimpleString() {
	return stringValueToConstantName("value") == "VALUE";
}

public test bool shouldNotBreakNumber() {
	return stringValueToConstantName("value1") == "VALUE1";
}

public test bool shouldTrimString() {
	return stringValueToConstantName(" and ") == "AND";
}

public test bool shouldTrimString2() {
	return stringValueToConstantName("Method ") == "METHOD";
}

public test bool shouldTrimMultipleSpacesInBetween() {
	return stringValueToConstantName("   Spaces      in     Between    ") == "SPACES_IN_BETWEEN";
}

public test bool shouldAddUnderScoreInInnerSpaces() {
	return stringValueToConstantName("Cannot set property ") == "CANNOT_SET_PROPERTY";
}

public test bool shouldIgnoreColonAtTheEnd() {
	return stringValueToConstantName("Arrays not equal: ") == "ARRAYS_NOT_EQUAL";
}

public test bool shouldIgnoreAtChar() {
	return stringValueToConstantName("Java @Annotation class for ") == "JAVA_ANNOTATION_CLASS_FOR";
}

public test bool shouldIgnoreSingleQuote() {
	return stringValueToConstantName("\' not found") == "NOT_FOUND";
}

public test bool shouldIgnoreDotAtTheEnd() {
	return stringValueToConstantName("\' not found.") == "NOT_FOUND";
}

public test bool capitalizedStringShouldBeTheSame() {
	return stringValueToConstantName("DEBUG") == "DEBUG";
}

public test bool shouldNotBreakNumberAndIgnoreDot() {
	return stringValueToConstantName("log4testng.rootLogger") == "LOG4TESTNG_ROOTLOGGER";
}

public test bool specialChars() {
	return stringValueToConstantName("\</th\>\</tr\>") == "TH_TR";
}

public test bool specialChars2() {
	return stringValueToConstantName("\</td\>\</tr\>") == "TD_TR";
}

public test bool specialChars3() {
	return stringValueToConstantName("\</tr\>\</th") == "TR_TH";
}

public test bool shouldAddUnderscoreToNumbers() {
	return stringValueToConstantName("12345") == "_12345";
}

public test bool shouldAddUnderscoreToStringStartingWithNumbers() {
	return stringValueToConstantName("1 - First") == "_1_FIRST";
}

public test bool shouldNotStartWithSpecialCharacter1() {
	return stringValueToConstantName("*ATTENTION*") == "ATTENTION";
}

public test bool shouldNotStartWithSpecialCharacter2() {
	return stringValueToConstantName("-NOTE-") == "NOTE";
}

public test bool shouldNotStartWithSpecialCharacter3() {
	return stringValueToConstantName("!OBS!") == "OBS";
}

public test bool removeInitialUnderscore() {
	return stringValueToConstantName("_START") == "_START";
}

public test bool removeInitialCurrencyChar() {
	return stringValueToConstantName("$VAR") == "VAR";
}

public test bool camelCase1() {
	return stringValueToConstantName("camelValue") == "CAMEL_VALUE";
}

public test bool camelCase2() {
	return stringValueToConstantName("TitleValue") == "TITLE_VALUE";
}

public test bool camelCase3() {
	return stringValueToConstantName("eclipseRCPExt") == "ECLIPSE_RCP_EXT";
}