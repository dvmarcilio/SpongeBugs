module lang::java::refactoring::sonar::stringLiteralDuplicated::StringValueToConstantName

import String;
import List;

public str stringValueToConstantName(str strValue) {
	if (isPossibleCamelCase(strValue)) {
		return toUpperCase(separateWithUnderscorePossibleCamelCase(strValue));
	}

	str converted = convertIgnoredCharsToSpace(strValue);
	converted = trimToAtMaxOneSpace(converted);
	converted = replaceSpacesWithUnderscore(converted);
	converted = addUnderscoreIfStartsWithNumber(converted);
	return toUpperCase(converted);
}

private bool isPossibleCamelCase(str strValue) {
	strValueWithoutSpaces = replaceAll(strValue, "\"", "");
	return !startsWithUnderScore(strValueWithoutSpaces) && isOnlyLetters(strValueWithoutSpaces) && findFirst(strValueWithoutSpaces, " ") == -1;
}

private bool isOnlyLetters(str strValue) {
	return rexpMatch(strValue, "[a-zA-z]+");
}

private bool startsWithUnderScore(str strValue) {
	return findFirst(strValue, "_") == 0;
}

private str separateWithUnderscorePossibleCamelCase(str strValue) {
	strValueWithoutSpaces = replaceAll(strValue, "\"", "");
	list[str] matches = [];
	for (/<match:(^[a-z]+|[A-Z][a-z]+|[A-Z]+(?=[A-Z][a-z]|$))>/ := strValueWithoutSpaces) {
		matches += match;
	}
	return intercalate("_", matches);
}

private str convertIgnoredCharsToSpace(str strValue) {
	str converted = strValue;
	for(/<match:[^(\w|\s)]>/ := converted) {
		converted = replaceAll(converted, match, " ");
	}
	return converted;
}

private str trimToAtMaxOneSpace(str strValue) {
	str trimmed = trim(strValue);
	while(findFirst(trimmed, "  ") >= 0) {
		trimmed = replaceAll(trimmed, "  ", " ");
	}
	return trimmed;
}

private str replaceSpacesWithUnderscore(str strValue) {
	return replaceAll(strValue, " ", "_");
}

private str addUnderscoreIfStartsWithNumber(str strValue) {
	str firstCharacter = stringChar(charAt(strValue, 0));
	if (rexpMatch(firstCharacter, "\\d")) {
		return "_" + strValue;
	}
	return strValue;
}