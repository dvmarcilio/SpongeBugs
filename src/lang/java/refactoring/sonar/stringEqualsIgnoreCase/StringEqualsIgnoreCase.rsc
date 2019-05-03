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
			if (shouldContinueWithASTAnalysis(fileLoc)) {
				shouldRewrite = false;
				refactorFileToEqualsIgnoreCase(fileLoc);
			}
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
				case (MethodInvocation) `<ExpressionName varName>.<TypeArguments? ts>toUpperCase().equals(<ArgumentList? args>)`: {
					if (isStringLiteral("<args>") && isEntireUpperCase("<args>")) {
						modified = true;
						insert (MethodInvocation) `<ExpressionName varName>.<TypeArguments? ts>equalsIgnoreCase(<ArgumentList? args>)`;
					}
				}
				case (MethodInvocation) `<ExpressionName varName>.<TypeArguments? ts>toLowerCase().equals(<ArgumentList? args>)`: {
					if (isStringLiteral("<args>") && isEntireLowerCase("<args>")) {
						modified = true;
						insert (MethodInvocation) `<ExpressionName varName>.<TypeArguments? ts>equalsIgnoreCase(<ArgumentList? args>)`;
					}
				}
				case (MethodInvocation) `<Primary varName>.<TypeArguments? ts>toUpperCase().equals(<ArgumentList? args>)`: {
					if (isStringLiteral("<args>") && isEntireUpperCase("<args>")) {
						modified = true;
						insert (MethodInvocation) `<ExpressionName varName>.<TypeArguments? ts>equalsIgnoreCase(<ArgumentList? args>)`;
					}
				}
				case (MethodInvocation) `<Primary varName>.<TypeArguments? ts>toLowerCase().equals(<ArgumentList? args>)`: {
					if (isStringLiteral("<args>") && isEntireLowerCase("<args>")) {
						modified = true;
						insert (MethodInvocation) `<ExpressionName varName>.<TypeArguments? ts>equalsIgnoreCase(<ArgumentList? args>)`;
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