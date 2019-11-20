module lang::java::refactoring::sonar::stringLiteralLHSEquality::StringLiteralLHSEquality

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import Set;
import lang::java::util::MethodDeclarationUtils;
import lang::java::util::CompilationUnitUtils;

private bool shouldWriteLog = false;

private loc logPath;

private str countLogFileName = "STRING_LITERAL_LHS_EQUALITY_COUNT.txt";

private int timesReplaced = 0;

public void refactorAllStringLiteralLHSEquality(list[loc] locs) {
	shouldWriteLog = false;
	doRefactorAllStringLiteralLHSEquality(locs);
}

public void refactorAllStringLiteralLHSEquality(list[loc] locs, loc logPathArg) {
	shouldWriteLog = true;
	logPath = logPathArg;
	doRefactorAllStringLiteralLHSEquality(locs);
}

private void doRefactorAllStringLiteralLHSEquality(list[loc] locs) {
	for (fileLoc <- locs) {
		try {
			if (shouldContinueWithASTAnalysis(fileLoc)) {
				doRefactorFileStringLiteralLHSEquality(fileLoc);
			}
		} catch: {
			println("Exception file (StringLiteralLHSEquality): " + fileLoc.file);
			continue;
		}
	}
}

private bool shouldContinueWithASTAnalysis(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	return findFirst(javaFileContent, ".equals(\"") != -1 || findFirst(javaFileContent, ".equalsIgnoreCase(\"") != -1;
}

public void refactorFileStringLiteralLHSEquality(loc fileLoc) {
	shouldWriteLog = false;
	doRefactorFileStringLiteralLHSEquality(fileLoc);
}

public void refactorFileStringLiteralLHSEquality(loc fileLoc, loc logPathArg) {
	shouldWriteLog = true;
	logPath = logPathArg;
	doRefactorFileStringLiteralLHSEquality(fileLoc);
}

private void doRefactorFileStringLiteralLHSEquality(loc fileLoc) {
	unit = retrieveCompilationUnitFromLoc(fileLoc);
	
	shouldRewrite = false;
	timesReplaced = 0;
	
	unit = top-down visit(unit) {
		case (Expression) `<Expression exp>`: {
			modified = false;
			exp = visit(exp) {
				case (Expression) `<EqualityExpression exp1> == null || <ExpressionName beforeFunc>.equals(<ArgumentList? args>)`: {
					if ("<exp1>" == "<beforeFunc>" && isStringLiteral("<args>")) {
						continue;
					}
				}
				case (Expression) `<EqualityExpression exp1> == null || <Primary beforeFunc>.equals(<ArgumentList? args>)`: {
					if ("<exp1>" == "<beforeFunc>" && isStringLiteral("<args>")) {
						continue;
					}
				}
				case (Expression) `<EqualityExpression exp1> != null && <ExpressionName beforeFunc>.<TypeArguments? ts>equals(<ArgumentList? args>)`: {
					if ("<exp1>" == "<beforeFunc>" && isStringLiteral("<args>")) {
						modified = true;
						expRefactored = parse(#Expression, "<args>.equals(<beforeFunc>)");
						timesReplaced += 1;
						insert expRefactored;						
					}
				}
				case (Expression) `<EqualityExpression exp1> != null && <Primary beforeFunc>.<TypeArguments? ts>equals(<ArgumentList? args>)`: {
					if ("<exp1>" == "<beforeFunc>" && isStringLiteral("<args>")) {
						modified = true;
						expRefactored = parse(#Expression, "<args>.equals(<beforeFunc>)");
						timesReplaced += 1;
						insert expRefactored;						
					}
				}
				
				case (Expression) `<EqualityExpression exp1> != null && !<ExpressionName beforeFunc>.<TypeArguments? ts>equals(<ArgumentList? args>)`: {
					if ("<exp1>" == "<beforeFunc>" && isStringLiteral("<args>")) {
						modified = true;
						expRefactored = parse(#Expression, "!<args>.equals(<beforeFunc>)");
						timesReplaced += 1;
						insert expRefactored;						
					}
				}
				case (Expression) `<EqualityExpression exp1> != null && !<Primary beforeFunc>.<TypeArguments? ts>equals(<ArgumentList? args>)`: {
					if ("<exp1>" == "<beforeFunc>" && isStringLiteral("<args>")) {
						modified = true;
						expRefactored = parse(#Expression, "!<args>.equals(<beforeFunc>)");
						timesReplaced += 1;
						insert expRefactored;						
					}
				}
				
				// equalsIgnoreCase
				case (Expression) `<EqualityExpression exp1> != null && <ExpressionName beforeFunc>.<TypeArguments? ts>equalsIgnoreCase(<ArgumentList? args>)`: {
					if ("<exp1>" == "<beforeFunc>" && isStringLiteral("<args>")) {
						modified = true;
						expRefactored = parse(#Expression, "<args>.equalsIgnoreCase(<beforeFunc>)");
						timesReplaced += 1;
						insert expRefactored;						
					}
				}
				case (Expression) `<EqualityExpression exp1> != null && <Primary beforeFunc>.<TypeArguments? ts>equalsIgnoreCase(<ArgumentList? args>)`: {
					if ("<exp1>" == "<beforeFunc>" && isStringLiteral("<args>")) {
						modified = true;
						expRefactored = parse(#Expression, "<args>.equalsIgnoreCase(<beforeFunc>)");
						timesReplaced += 1;
						insert expRefactored;						
					}
				}
				
				case (Expression) `<EqualityExpression exp1> != null && !<ExpressionName beforeFunc>.<TypeArguments? ts>equalsIgnoreCase(<ArgumentList? args>)`: {
					if ("<exp1>" == "<beforeFunc>" && isStringLiteral("<args>")) {
						modified = true;
						expRefactored = parse(#Expression, "!<args>.equalsIgnoreCase(<beforeFunc>)");
						timesReplaced += 1;
						insert expRefactored;						
					}
				}
				case (Expression) `<EqualityExpression exp1> != null && !<Primary beforeFunc>.<TypeArguments? ts>equalsIgnoreCase(<ArgumentList? args>)`: {
					if ("<exp1>" == "<beforeFunc>" && isStringLiteral("<args>")) {
						modified = true;
						expRefactored = parse(#Expression, "!<args>.equalsIgnoreCase(<beforeFunc>)");
						timesReplaced += 1;
						insert expRefactored;						
					}
				}
			}
			
			if (modified) {
				shouldRewrite = true;
				insert (Expression) `<Expression exp>`;
			}
		}
		
		case (MethodInvocation) `<ExpressionName beforeFunc>.<TypeArguments? ts>equals(<ArgumentList? args>)`: {
			if (isStringLiteral("<args>")) {
				shouldRewrite = true;
				mi = parse(#MethodInvocation, "<args>.equals(<beforeFunc>)");
				timesReplaced += 1;
				insert mi;
			}
		}
		case (MethodInvocation) `<Primary beforeFunc>.<TypeArguments? ts>equals(<ArgumentList? args>)`: {
			if (isStringLiteral("<args>")) {
				shouldRewrite = true;
				mi = parse(#MethodInvocation, "<args>.equals(<beforeFunc>)");
				timesReplaced += 1;
				insert mi;
			}
		}
		case (MethodInvocation) `<ExpressionName beforeFunc>.<TypeArguments? ts>equalsIgnoreCase(<ArgumentList? args>)`: {
			if (isStringLiteral("<args>")) {
				shouldRewrite = true;
				mi = parse(#MethodInvocation, "<args>.equalsIgnoreCase(<beforeFunc>)");
				timesReplaced += 1;
				insert mi;
			}
		}
		case (MethodInvocation) `<Primary beforeFunc>.<TypeArguments? ts>equalsIgnoreCase(<ArgumentList? args>)`: {
			if (isStringLiteral("<args>")) {
				shouldRewrite = true;
				mi = parse(#MethodInvocation, "<args>.equalsIgnoreCase(<beforeFunc>)");
				timesReplaced += 1;
				insert mi;
			}
		}
			
	}
	
	if (shouldRewrite) {
		writeFile(fileLoc, unit);
		doWriteLog(fileLoc);
	}
}

private bool isStringLiteral(str args) {
	try {
		parse(#StringLiteral, args);
		return true;	
	} catch: {
		return false;
	}
}

private void doWriteLog(loc fileLoc) {
	if (shouldWriteLog)
		writeToCountLogFile(fileLoc);
}

private void writeToCountLogFile(loc fileLoc) {
	filePathStr = fileLoc.authority + fileLoc.path;
	countFilePath = logPath + countLogFileName;
	
	countStr = "<filePathStr>: <timesReplaced>";
	
	writeToLogFile(countStr, countFilePath);
}

private void writeToLogFile(str countStr, loc fileLoc) {
	if (exists(fileLoc))
		appendToFile(fileLoc, "\n" + countStr);
	else
		writeFile(fileLoc, countStr);
}
