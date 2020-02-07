module lang::java::refactoring::sonar::stringIndexOfSingleQuoteChar::StringIndexOfSingleQuoteChar

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import lang::java::util::CompilationUnitUtils;
import lang::java::refactoring::forloop::LocalVariablesFinder;
import lang::java::refactoring::forloop::MethodVar;
import lang::java::refactoring::sonar::LogUtils;
import lang::java::util::MethodDeclarationUtils;

private bool shouldWriteLog = false;

private loc logPath;

private str detailedLogFileName = "STRING_INDEX_OF_SINGLE_QUOTE_DETAILED.txt";
private str countLogFileName = "STRING_INDEX_OF_SINGLE_QUOTE_COUNT.txt";

private map[str, int] timesReplacedByScope = ();

// The arguments that we parse contain the quotes already, thats why all escaped chars
// in the set start and end with \"
// each \ coming from Java should be two \\ in our rascal string
private set[str] escapedChars = {"\"\\t\"", "\"\\b\"", "\"\\n\"", "\"\\r\"", "\"\\f\"", "\"\'\"", "\"\"\"", "\"\\\\\""};

public void stringIndexOfSingleQuoteChar(list[loc] locs) {
	shouldWriteLog = false;
	doStringIndexOfSingleQuoteChar(locs);
}

private void doStringIndexOfSingleQuoteChar(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			if (shouldContinueWithASTAnalysis(fileLoc)) {
				doRefactorStringIndexOfSingleQuoteChar(fileLoc);
			}
		} catch: {
			println("Exception file: " + fileLoc.file);
			continue;
		}
	}
}

public void stringIndexOfSingleQuoteChar(list[loc] locs, loc logPathArg) {
	shouldWriteLog = true;
	logPath = logPathArg;
	doStringIndexOfSingleQuoteChar(locs);
}


private bool shouldContinueWithASTAnalysis(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	return findFirst(javaFileContent, ".lastIndexOf(\"") != -1 || findFirst(javaFileContent, ".indexOf(\"") != -1;
}


public void refactorStringIndexOfSingleQuoteChar(loc fileLoc) {
	shouldWriteLog = false;
	doRefactorStringIndexOfSingleQuoteChar(fileLoc);
}

public void refactorStringIndexOfSingleQuoteChar(loc fileLoc, loc logPathArg) {
	shouldWriteLog = true;
	logPath = logPathArg;
	doRefactorStringIndexOfSingleQuoteChar(fileLoc);
}


private void doRefactorStringIndexOfSingleQuoteChar(loc fileLoc) {
	unit = retrieveCompilationUnitFromLoc(fileLoc);
	
	shouldRewrite = false;
	timesReplacedByScope = ();
	
	unit = top-down visit(unit) {
		case (MethodDeclaration) `<MethodDeclaration mdl>`: {
			modified = false;
			methodSignature = retrieveMethodSignature(mdl);
			
			mdl = bottom-up-break visit(mdl) {
				case (MethodInvocation) `<Primary varName>.<TypeArguments? ts>indexOf(<ArgumentList? args>)`: {
					if (isArgOfInterest("<args>") && isVarOfInterest(mdl, "<varName>")) {
						modified = true;
						countModificationForLog(methodSignature);
						argAsChar = parseSingleCharStringToCharAsArgumentList("<args>");
						insert (MethodInvocation) `<Primary varName>.<TypeArguments? ts>indexOf(<ArgumentList argAsChar>)`;
					}
				}
				case (MethodInvocation) `<Primary varName>.<TypeArguments? ts>lastIndexOf(<ArgumentList? args>)`: {
					if (isArgOfInterest("<args>") && isVarOfInterest(mdl, "<varName>")) {
						modified = true;
						countModificationForLog(methodSignature);
						argAsChar = parseSingleCharStringToCharAsArgumentList("<args>");
						insert (MethodInvocation) `<Primary varName>.<TypeArguments? ts>lastIndexOf(<ArgumentList argAsChar>)`;
					}
				}
				case (MethodInvocation) `<ExpressionName varName>.<TypeArguments? ts>indexOf(<ArgumentList? args>)`: {
					if (isArgOfInterest("<args>") && isVarOfInterest(mdl, "<varName>")) {
						modified = true;
						countModificationForLog(methodSignature);
						argAsChar = parseSingleCharStringToCharAsArgumentList("<args>");
						insert (MethodInvocation) `<ExpressionName varName>.<TypeArguments? ts>indexOf(<ArgumentList argAsChar>)`;
					}
				}
				case (MethodInvocation) `<ExpressionName varName>.<TypeArguments? ts>lastIndexOf(<ArgumentList? args>)`: {
					if (isArgOfInterest("<args>") && isVarOfInterest(mdl, "<varName>")) {
						modified = true;
						countModificationForLog(methodSignature);
						argAsChar = parseSingleCharStringToCharAsArgumentList("<args>");
						insert (MethodInvocation) `<ExpressionName varName>.<TypeArguments? ts>lastIndexOf(<ArgumentList argAsChar>)`;
					}
				}
			}
			if (modified) {
				shouldRewrite = true;
				insert (MethodDeclaration) `<MethodDeclaration mdl>`;
			}
		}
	}
	
	
	if (shouldRewrite) {
		writeFile(fileLoc, unit);
		doWriteLog(fileLoc);
	}
}

private bool isArgOfInterest(str arg) {
	return isEscapedChar(arg) || isAStringWithSizeOne(arg);
}

private bool isEscapedChar(str arg) {
	return arg in escapedChars;
}

private bool isAStringWithSizeOne(str arg) {
	arg = trim(arg);
	return size(arg) == 3 && isCharAtIndexEqualsToDoubleQuote(arg, 0) && isCharAtIndexEqualsToDoubleQuote(arg, 2);
}

private bool isCharAtIndexEqualsToDoubleQuote(str arg, int index) {
	return stringChar(charAt(arg, index)) == "\"";
}

private bool isVarOfInterest(MethodDeclaration mdl, str varNameOrChainOfInvocation) {
	visit (mdl) {
		case (MethodDeclaration) `<MethodModifier* mds> <MethodHeader methodHeader> <MethodBody mBody>`: {
			set[MethodVar] localVars = findLocalVariables(methodHeader, mBody);
			return isVarInTheChainAString(localVars, varNameOrChainOfInvocation);
		}
	}
	return false;
}

private bool isVarInTheChainAString(set[MethodVar] localVars, str varNameOrChainOfInvocation) {
	if (findFirst(varNameOrChainOfInvocation, ".") == -1) {
		try {
			MethodVar var = findByName(localVars, varNameOrChainOfInvocation);
			return isString(var);
		} catch :
			return false;
	}
	
	return false;
}

private ArgumentList parseSingleCharStringToCharAsArgumentList(str singleCharString) {
	replaced = replaceFirst(singleCharString, "\"", "\'");
	replaced = replaceLast(replaced, "\"", "\'");
	return parse(#ArgumentList, replaced);
}

private void countModificationForLog(str scope) {
	if (scope in timesReplacedByScope) {
		timesReplacedByScope[scope] += 1;
	} else { 
		timesReplacedByScope[scope] = 1;
	}
}

private void doWriteLog(loc fileLoc) {
	if (shouldWriteLog)
		writeLog(fileLoc, logPath, detailedLogFileName, countLogFileName, timesReplacedByScope);
}