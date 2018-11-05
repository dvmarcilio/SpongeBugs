module lang::java::refactoring::sonar::stringLiteralDuplicated::\test::StringValueAsConstantNameTest

import lang::java::refactoring::sonar::stringLiteralDuplicated::StringValueAsConstantName;

public test bool shouldSnakeCaseCapitalizedSimpleString() {
	return stringValueAsConstantName("value") == "VALUE";
}

public test bool shouldNotBreakNumber() {
	return stringValueAsConstantName("value1") == "VALUE1";
}

public test bool shouldTrimString() {
	return stringValueAsConstantName(" and ") == "AND";
}

public test bool shouldTrimString2() {
	return stringValueAsConstantName("Method ") == "METHOD";
}

public test bool shouldAddUnderScoreInInnerSpaces() {
	return stringValueAsConstantName("Cannot set property ") == "CANNOT_SET_PROPERTY";
}

public test bool shouldIgnoreSemiCollonsAtTheEnd() {
	return stringValueAsConstantName("Arrays not equal: ") == "ARRAYS_NOT_EQUAL";
}

public test bool shouldIgnoreAtChar() {
	return stringValueAsConstantName("Java @Annotation class for ") == "JAVA_ANNOTATION_CLASS_FOR";
}

public test bool shouldIgnoreSingleQuote() {
	return stringValueAsConstantName("\' not found") == "NOT_FOUND";
}

public test bool shouldIgnoreDotAtTheEnd() {
	return stringValueAsConstantName("\' not found.") == "NOT_FOUND";
}

public test bool capitalizedStringShouldBeTheSame() {
	return stringValueAsConstantName("DEBUG") == "DEBUG";
}

public test bool shouldNotBreakNumberAndReplaceDotWithSpace() {
	return stringValueAsConstantName("log4testng.rootLogger") == "LOG_4_TESTNG_ROOTLOGGER";
}