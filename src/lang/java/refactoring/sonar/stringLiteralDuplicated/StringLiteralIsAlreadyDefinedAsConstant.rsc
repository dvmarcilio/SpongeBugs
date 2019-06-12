module lang::java::refactoring::sonar::stringLiteralDuplicated::StringLiteralIsAlreadyDefinedAsConstant

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import List;
import Map;
import Set;

private map[str, str] constantByStrLiteral = ();

private bool shouldRewrite = false;

public void allStringLiteralsAlreadyDefinedAsConstant(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			if (shouldContinueWithASTAnalysis(fileLoc)) {
				resetState();
				refactorStringLiteralIsAlreadyDefinedAsConstant(fileLoc);
			}
		} catch: {
			println("Exception file (StringLiteralIsAlreadyDefinedAsConstant): <fileLoc.file>");
			continue;
		}
	}
}

private bool shouldContinueWithASTAnalysis(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	return findFirst(javaFileContent, "private static final String") != -1;
}

private void resetState() {
	shouldRewrite = false;
	constantByStrLiteral = ();
	definedConstants = [];
}

public void refactorStringLiteralIsAlreadyDefinedAsConstant(loc fileLoc) {
	unit = retrieveCompilationUnitFromLoc(fileLoc);
	loadConstantByStrLiteral(unit);
	
	unit = top-down-break visit(unit) {
		case (StatementWithoutTrailingSubstatement) `<StatementWithoutTrailingSubstatement stmt>`: {
			modified = false;
			stmtRefactored = stmt;
			top-down-break visit(stmt) {
				case (StringLiteral) `<StringLiteral strLiteral>`: {
					strLiteralAsStr = "<strLiteral>";
					if (strLiteralAsStr in constantByStrLiteral) {
						modified = true;
						stmtRefactoredStr = replaceFirst("<stmt>", strLiteralAsStr, constantByStrLiteral[strLiteralAsStr]);
						stmtRefactored = parse(#StatementWithoutTrailingSubstatement, stmtRefactoredStr); 
					}
				}
			}
			if (modified) {
				shouldRewrite = true;
				insert stmtRefactored;
			}
		}
	}
	
	if (shouldRewrite) {
		writeFile(fileLoc, unit);
	}
}

private CompilationUnit retrieveCompilationUnitFromLoc(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	return parse(#CompilationUnit, javaFileContent);
}

private void loadConstantByStrLiteral(CompilationUnit unit) {
	top-down visit(unit) {
		case (FieldDeclaration) `<FieldDeclaration flDecl>`: {
			top-down-break visit (flDecl) {
				case (FieldDeclaration) `<FieldModifier* varMod> String <VariableDeclaratorList vdl>;`: {
					constantName = "";
					strLiteral = "";
					if (contains("<varMod>", "static") && contains("<varMod>", "final")) {
						visit(vdl) {
							case (VariableDeclaratorId) `<Identifier varId> <Dims? dims>`: {
								constantName = "<varId>";
							}
							case (StringLiteral) `<StringLiteral stringLiteral>`: {
								strLiteral = "<stringLiteral>";
							}
						}
					}
					if (!isEmpty(constantName) && !isEmpty(strLiteral)) {
						constantByStrLiteral[strLiteral] = constantName;
					}
				}
			}
		}
	}
}