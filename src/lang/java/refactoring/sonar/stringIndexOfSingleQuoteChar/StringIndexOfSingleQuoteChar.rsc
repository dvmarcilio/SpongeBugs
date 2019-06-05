module lang::java::refactoring::sonar::stringIndexOfSingleQuoteChar::StringIndexOfSingleQuoteChar

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import lang::java::util::CompilationUnitUtils;
import lang::java::refactoring::forloop::LocalVariablesFinder;
import lang::java::refactoring::forloop::MethodVar;

private bool shouldRewrite = false;

public void stringIndexOfSingleQuoteChar(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			if (shouldContinueWithASTAnalysis(fileLoc)) {
				shouldRewrite = false;
				refactorStringIndexOfSingleQuoteChar(fileLoc);
			}
		} catch: {
			println("Exception file: " + fileLoc.file);
			continue;
		}	
	}
}


private bool shouldContinueWithASTAnalysis(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	return findFirst(javaFileContent, ".lastIndexOf(\"") != -1 || findFirst(javaFileContent, ".indexOf(\"") != -1;
}

public void refactorStringIndexOfSingleQuoteChar(loc fileLoc) {
	unit = retrieveCompilationUnitFromLoc(fileLoc);
	
	unit = top-down visit(unit) {
		case (MethodDeclaration) `<MethodDeclaration mdl>`: {
			modified = false;
			mdl = bottom-up-break visit(mdl) {
				case (MethodInvocation) `<Primary varName>.<TypeArguments? ts>indexOf(<ArgumentList? args>)`: {
					if (isArgOfInterest("<args>") && isVarOfInterest(mdl, "<varName>")) {
						modified = true;
						argAsChar = parseSingleCharStringToCharAsArgumentList("<args>");
						insert (MethodInvocation) `<Primary varName>.<TypeArguments? ts>indexOf(<ArgumentList argAsChar>)`;
					}
				}
				case (MethodInvocation) `<Primary varName>.<TypeArguments? ts>lastIndexOf(<ArgumentList? args>)`: {
					if (isArgOfInterest("<args>") && isVarOfInterest(mdl, "<varName>")) {
						modified = true;
						argAsChar = parseSingleCharStringToCharAsArgumentList("<args>");
						insert (MethodInvocation) `<Primary varName>.<TypeArguments? ts>lastIndexOf(<ArgumentList argAsChar>)`;
					}
				}
				case (MethodInvocation) `<ExpressionName varName>.<TypeArguments? ts>indexOf(<ArgumentList? args>)`: {
					if (isArgOfInterest("<args>") && isVarOfInterest(mdl, "<varName>")) {
						modified = true;
						argAsChar = parseSingleCharStringToCharAsArgumentList("<args>");
						insert (MethodInvocation) `<ExpressionName varName>.<TypeArguments? ts>indexOf(<ArgumentList argAsChar>)`;
					}
				}
				case (MethodInvocation) `<ExpressionName varName>.<TypeArguments? ts>lastIndexOf(<ArgumentList? args>)`: {
					if (isArgOfInterest("<args>") && isVarOfInterest(mdl, "<varName>")) {
						modified = true;
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
	}
}

private bool isMethodNameOfInterest(str methodName) {
	return methodName == "lastIndexOf" || methodName == "indexOf";
}

private bool isArgOfInterest(str arg) {
	return findFirst(arg, ",") == -1 && findFirst(arg, "\"") != -1 && size(arg) == 3;
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
	
	// TODO we are not resolving method invocation chain yet. 
	// example: file.getResource().getName().indexOf("2") >= 0
	
	//list[str] varNamesInChain = split(".", varNameOrChainOfInvocation);
	//set[str] localVarNames = retrieveAllNames(localVars);
	//for (varNameInChain <- varNamesInChain) {
	//	if (varNameInChain in localVarNames) {
	//		println(varNameInChain);
	//		MethodVar var = findByName(localVars, varNameInChain);
	//		if (isString(var))
	//			return true;
	//	}
	//}
}

private ArgumentList parseSingleCharStringToCharAsArgumentList(str singleCharString) {
	replaced = replaceAll(singleCharString, "\"", "\'");
	return parse(#ArgumentList, replaced);
}
