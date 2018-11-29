module lang::java::refactoring::sonar::stringLiteralDuplicated::StringValueToConstantName

import String;

public str stringValueToConstantName(str strValue) {
	str converted = convertIgnoredCharsToSpace(strValue);
	converted = trimToAtMaxOneSpace(converted);
	converted = replaceSpacesWithUnderscore(converted);
	converted = addUnderscoreIfStartsWithNumber(converted);
	return toUpperCase(converted);
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