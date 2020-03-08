module lang::java::refactoring::sonar::stringEqualsIgnoreCase::StringEqualsIgnoreCase

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import Set;
import lang::java::util::MethodDeclarationUtils;
import lang::java::util::CompilationUnitUtils;

private set[str] methodCallsToCheck = {"toUpperCase", "toLowerCase"};

private bool shouldRewrite = false;

public void refactorAllToEqualsIgnoreCase(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
				shouldRewrite = false;
				refactorFileToEqualsIgnoreCase(fileLoc);
		} catch: {
			println("Exception file: " + fileLoc.file);
			continue;
		}
	}
}

private bool shouldContinueWithASTAnalysis(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	return findFirst(javaFileContent, ".toUpperCase(") != -1 || findFirst(javaFileContent, ".toLowerCase(") != -1 ;
}

public void refactorFileToEqualsIgnoreCase(loc fileLoc) {
	unit = retrieveCompilationUnitFromLoc(fileLoc);
	
	unit = visit(unit) {
		case (MethodDeclaration) `<MethodDeclaration mdl>`: {
			modified = false;
			mdl = visit(mdl) {
				// toCase on variable, Literal at the end
				case (MethodInvocation) `<ExpressionName beforeFunc>.<TypeArguments? ts>toUpperCase().equals(<ArgumentList? args>)`: {
					if (isStringLiteral("<args>") && isEntireUpperCase("<args>")) {
						modified = true;
						mi = parse(#MethodInvocation, "<args>.equalsIgnoreCase(<beforeFunc>)");
						insert mi;
					}
				}
				case (MethodInvocation) `<ExpressionName beforeFunc>.<TypeArguments? ts>toLowerCase().equals(<ArgumentList? args>)`: {
					if (isStringLiteral("<args>") && isEntireLowerCase("<args>")) {
						modified = true;
						mi = parse(#MethodInvocation, "<args>.equalsIgnoreCase(<beforeFunc>)");
						insert mi;
					}
				}
				case (MethodInvocation) `<Primary beforeFunc>.<TypeArguments? ts>toUpperCase().equals(<ArgumentList? args>)`: {
					if (isStringLiteral("<args>") && isEntireUpperCase("<args>")) {
						modified = true;
						mi = parse(#MethodInvocation, "<args>.equalsIgnoreCase(<beforeFunc>)");
						insert mi;
					}
				}
				case (MethodInvocation) `<Primary beforeFunc>.<TypeArguments? ts>toLowerCase().equals(<ArgumentList? args>)`: {
					if (isStringLiteral("<args>") && isEntireLowerCase("<args>")) {
						modified = true;
						mi = parse(#MethodInvocation, "<args>.equalsIgnoreCase(<beforeFunc>)");
						insert mi;
					}
				}
				
				// literal first, toCase after
				case (MethodInvocation) `<StringLiteral strLiteral>.equals(<ArgumentList? args>)`: {
					matchLiteralFirstToCaseAfter = false;
					str beforeFunction = "<args>";
					visit(args) {
						case (MethodInvocation) `<ExpressionName beforeFunc>.<TypeArguments? ts>toLowerCase()`: {
							if (isEntireLowerCase("<args>")) {
								modified = true;
								matchLiteralFirstToCaseAfter = true;
								beforeFunction = "<beforeFunc>";
							}
						}
						case (MethodInvocation) `<ExpressionName beforeFunc>.<TypeArguments? ts>toUpperCase()`: {
							if (isEntireUpperCase("<strLiteral>")) {
								modified = true;
								matchLiteralFirstToCaseAfter = true;
								beforeFunction = "<beforeFunc>";
							}
						}
					}
					if (matchLiteralFirstToCaseAfter) {
						mi = parse(#MethodInvocation, "<strLiteral>.equalsIgnoreCase(<beforeFunction>)");
						insert mi;
					}
				}
				
				// two sides equals
				// str.name().toLowerCase().equals(str2.toLowerCase());
			}
			if (modified) {
				shouldRewrite = true;
				insert (MethodDeclaration) `<MethodDeclaration mdl>`;
			}
		}
		
		case (BlockStatements) `<BlockStatements blockStatements>`: {
			modified = false;
			
			blockStatements = visit(blockStatements) {
				// toCase on variable, Literal at the end
				case (MethodInvocation) `<ExpressionName beforeFunc>.<TypeArguments? ts>toUpperCase().equals(<ArgumentList? args>)`: {
					if (isStringLiteral("<args>") && isEntireUpperCase("<args>")) {
						modified = true;
						mi = parse(#MethodInvocation, "<args>.equalsIgnoreCase(<beforeFunc>)");
						insert mi;
					}
				}
				case (MethodInvocation) `<ExpressionName beforeFunc>.<TypeArguments? ts>toLowerCase().equals(<ArgumentList? args>)`: {
					if (isStringLiteral("<args>") && isEntireLowerCase("<args>")) {
						modified = true;
						mi = parse(#MethodInvocation, "<args>.equalsIgnoreCase(<beforeFunc>)");
						insert mi;
					}
				}
				case (MethodInvocation) `<Primary beforeFunc>.<TypeArguments? ts>toUpperCase().equals(<ArgumentList? args>)`: {
					if (isStringLiteral("<args>") && isEntireUpperCase("<args>")) {
						modified = true;
						mi = parse(#MethodInvocation, "<args>.equalsIgnoreCase(<beforeFunc>)");
						insert mi;
					}
				}
				case (MethodInvocation) `<Primary beforeFunc>.<TypeArguments? ts>toLowerCase().equals(<ArgumentList? args>)`: {
					if (isStringLiteral("<args>") && isEntireLowerCase("<args>")) {
						modified = true;
						mi = parse(#MethodInvocation, "<args>.equalsIgnoreCase(<beforeFunc>)");
						insert mi;
					}
				}
				
				// literal first, toCase after
				case (MethodInvocation) `<StringLiteral strLiteral>.equals(<ArgumentList? args>)`: {
					matchLiteralFirstToCaseAfter = false;
					str beforeFunction = "<args>";
					visit(args) {
						case (MethodInvocation) `<ExpressionName beforeFunc>.<TypeArguments? ts>toLowerCase()`: {
							if (isEntireLowerCase("<args>")) {
								modified = true;
								matchLiteralFirstToCaseAfter = true;
								beforeFunction = "<beforeFunc>";
							}
						}
						case (MethodInvocation) `<ExpressionName beforeFunc>.<TypeArguments? ts>toUpperCase()`: {
							if (isEntireUpperCase("<strLiteral>")) {
								modified = true;
								matchLiteralFirstToCaseAfter = true;
								beforeFunction = "<beforeFunc>";
							}
						}
					}
					if (matchLiteralFirstToCaseAfter) {
						mi = parse(#MethodInvocation, "<strLiteral>.equalsIgnoreCase(<beforeFunction>)");
						insert mi;
					}
				}
			}
			
			if (modified) {
				shouldRewrite = true;
				insert (BlockStatements) `<BlockStatements blockStatements>`;
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

private bool isEntireLowerCase(str strLiteral) {
	return strLiteral == toLowerCase(strLiteral);
}

private bool isEntireUpperCase(str strLiteral) {
	return strLiteral == toUpperCase(strLiteral);
}