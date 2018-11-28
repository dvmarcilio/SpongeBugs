module lang::java::refactoring::sonar::stringLiteralDuplicated::StringValueToConstantName

import String;

public str stringValueToConstantName(str strValue) {
	str converted = convertIgnoredCharsToSpace(strValue);
	converted = trimToAtMaxOneSpace(converted);
	converted = replaceSpacesWithUnderline(converted);
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

private str replaceSpacesWithUnderline(str strValue) {
	return replaceAll(strValue, " ", "_");
}