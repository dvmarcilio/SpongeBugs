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
				refactorForEachClassBody(fileLoc);
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

private void refactorForEachClassBody(loc fileLoc) {
	unit = retrieveCompilationUnitFromLoc(fileLoc);
	for(classBody <- retrieveClassBodies(unit)) {
		resetState();
		doRefactorForEachClassBody(fileLoc, unit, classBody);
		unit = retrieveCompilationUnitFromLoc(fileLoc);		
	}	
}

private CompilationUnit retrieveCompilationUnitFromLoc(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	return parse(#CompilationUnit, javaFileContent);
}

private list[ClassBody] retrieveClassBodies(CompilationUnit unit) {
	list[ClassBody] classBodies = [];
	top-down-break visit(unit) {
		case (ClassBody) `<ClassBody classBody>`: { 
			classBodies += classBody;
		}
	}
	return classBodies;
}

private void doRefactorForEachClassBody(loc fileLoc, CompilationUnit unit, ClassBody classBody) {
	loadConstantByStrLiteral(unit);
	
	refactoredClassBody = top-down-break visit(classBody) {
		case (BlockStatement) `<BlockStatement stmt>`: {
			modified = false;
			stmtRefactored = stmt;
			top-down-break visit(stmt) {
				case (StringLiteral) `<StringLiteral strLiteral>`: {
					strLiteralAsStr = "<strLiteral>";
					if (strLiteralAsStr in constantByStrLiteral) {
						modified = true;
						stmtRefactoredStr = replaceAll("<stmt>", strLiteralAsStr, constantByStrLiteral[strLiteralAsStr]);
						stmtRefactored = parse(#BlockStatement, stmtRefactoredStr); 
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
		unit = top-down-break visit(unit) {
			case (ClassBody) `<ClassBody possibleClassBodyToRefactor>`: {
				if(possibleClassBodyToRefactor == classBody)
					insert refactoredClassBody;
			}
		}
		writeFile(fileLoc, unit);
	}
}

private void resetState() {
	shouldRewrite = false;
	constantByStrLiteral = ();
	definedConstants = [];
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