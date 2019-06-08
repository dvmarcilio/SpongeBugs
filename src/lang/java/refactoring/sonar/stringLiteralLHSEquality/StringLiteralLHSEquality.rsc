module lang::java::refactoring::sonar::stringLiteralLHSEquality::StringLiteralLHSEquality

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import Set;
import lang::java::util::MethodDeclarationUtils;
import lang::java::util::CompilationUnitUtils;

private bool shouldRewrite = false;

public void refactorAllStringLiteralLHSEquality(list[loc] locs) {
	for (fileLoc <- locs) {
		try {
			if (shouldContinueWithASTAnalysis(fileLoc)) {
				shouldRewrite = false;
				refactorFileStringLiteralLHSEquality(fileLoc);
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
	unit = retrieveCompilationUnitFromLoc(fileLoc);
	unit = visit(unit) {
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
						insert expRefactored;						
					}
				}
				case (Expression) `<EqualityExpression exp1> != null && <Primary beforeFunc>.<TypeArguments? ts>equals(<ArgumentList? args>)`: {
					if ("<exp1>" == "<beforeFunc>" && isStringLiteral("<args>")) {
						modified = true;
						expRefactored = parse(#Expression, "<args>.equals(<beforeFunc>)");
						insert expRefactored;						
					}
				}
				
				case (Expression) `<EqualityExpression exp1> != null && !<ExpressionName beforeFunc>.<TypeArguments? ts>equals(<ArgumentList? args>)`: {
					if ("<exp1>" == "<beforeFunc>" && isStringLiteral("<args>")) {
						modified = true;
						expRefactored = parse(#Expression, "!<args>.equals(<beforeFunc>)");
						insert expRefactored;						
					}
				}
				case (Expression) `<EqualityExpression exp1> != null && !<Primary beforeFunc>.<TypeArguments? ts>equals(<ArgumentList? args>)`: {
					if ("<exp1>" == "<beforeFunc>" && isStringLiteral("<args>")) {
						modified = true;
						expRefactored = parse(#Expression, "!<args>.equals(<beforeFunc>)");
						insert expRefactored;						
					}
				}
				
				// equalsIgnoreCase
				case (Expression) `<EqualityExpression exp1> != null && <ExpressionName beforeFunc>.<TypeArguments? ts>equalsIgnoreCase(<ArgumentList? args>)`: {
					if ("<exp1>" == "<beforeFunc>" && isStringLiteral("<args>")) {
						modified = true;
						expRefactored = parse(#Expression, "<args>.equalsIgnoreCase(<beforeFunc>)");
						insert expRefactored;						
					}
				}
				case (Expression) `<EqualityExpression exp1> != null && <Primary beforeFunc>.<TypeArguments? ts>equalsIgnoreCase(<ArgumentList? args>)`: {
					if ("<exp1>" == "<beforeFunc>" && isStringLiteral("<args>")) {
						modified = true;
						expRefactored = parse(#Expression, "<args>.equalsIgnoreCase(<beforeFunc>)");
						insert expRefactored;						
					}
				}
				
				case (Expression) `<EqualityExpression exp1> != null && !<ExpressionName beforeFunc>.<TypeArguments? ts>equalsIgnoreCase(<ArgumentList? args>)`: {
					if ("<exp1>" == "<beforeFunc>" && isStringLiteral("<args>")) {
						modified = true;
						expRefactored = parse(#Expression, "!<args>.equalsIgnoreCase(<beforeFunc>)");
						insert expRefactored;						
					}
				}
				case (Expression) `<EqualityExpression exp1> != null && !<Primary beforeFunc>.<TypeArguments? ts>equalsIgnoreCase(<ArgumentList? args>)`: {
					if ("<exp1>" == "<beforeFunc>" && isStringLiteral("<args>")) {
						modified = true;
						expRefactored = parse(#Expression, "!<args>.equalsIgnoreCase(<beforeFunc>)");
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
						insert mi;
					}
				}
				case (MethodInvocation) `<Primary beforeFunc>.<TypeArguments? ts>equals(<ArgumentList? args>)`: {
					if (isStringLiteral("<args>")) {
						shouldRewrite = true;
						mi = parse(#MethodInvocation, "<args>.equals(<beforeFunc>)");
						insert mi;
					}
				}
				case (MethodInvocation) `<ExpressionName beforeFunc>.<TypeArguments? ts>equalsIgnoreCase(<ArgumentList? args>)`: {
					if (isStringLiteral("<args>")) {
						shouldRewrite = true;
						mi = parse(#MethodInvocation, "<args>.equalsIgnoreCase(<beforeFunc>)");
						insert mi;
					}
				}
				case (MethodInvocation) `<Primary beforeFunc>.<TypeArguments? ts>equalsIgnoreCase(<ArgumentList? args>)`: {
					if (isStringLiteral("<args>")) {
						shouldRewrite = true;
						mi = parse(#MethodInvocation, "<args>.equalsIgnoreCase(<beforeFunc>)");
						insert mi;
					}
				}
			
	}
	
	if (shouldRewrite) {
		writeFile(fileLoc, unit);
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