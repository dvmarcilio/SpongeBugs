module lang::java::refactoring::sonar::mapEntrySetInsteadOfKeySet::MapEntrySetInsteadOfKeySet

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import Set;
import lang::java::util::CompilationUnitUtils;
import lang::java::refactoring::forloop::MethodVar;
import lang::java::refactoring::forloop::LocalVariablesFinder;
import lang::java::refactoring::forloop::ClassFieldsFinder;
import lang::java::util::CompilationUnitUtils;

private data Var = newVar(str name, str varType, str generics);

private map[str, Var] fieldsByName = ();

private bool shouldRewrite = false;

private set[str] mapTypes = {"Map", "HashMap", "LinkedHashMap", "TreeMap", "EnumMap", "ConcurrentHashMap",
 	"ConcurrentMap", "SortedMap", "NavigableMap"};

private data MapExp = mapExp(bool isMapReference, str name, Expression exp);

private str ENTRY_NAME = "entry";

private bool KEEP_KEY_AS_A_LOOP_VARIABLE = true;

private bool isUtilWildCardImportPresent = false;
private bool isMapEntryExplicitImportPresent = false;
private bool isMapWildCardImportPresent = false;

public void refactorAllEntrySetInsteadOfKeySet(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			if (shouldContinueWithASTAnalysis(fileLoc)) {
				refactorFileEntrySetInsteadOfKeySet(fileLoc);
			}
		} catch Ambiguity: {
			println("Ambiguity file (MapEntrySetInsteadOfKeySet): " + fileLoc.file);
			continue;
		} catch: {
			println("Exception file (MapEntrySetInsteadOfKeySet): " + fileLoc.file);
			continue;
		}
	}
}

private bool shouldContinueWithASTAnalysis(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	return findFirst(javaFileContent, "java.util.") != -1 &&
		findFirst(javaFileContent, ".keySet()") != 1 &&
		findFirst(javaFileContent, ".get(") != 1;
}

private void resetImportPresenceBools() {
	isUtilWildCardImportPresent = false;
	isMapEntryExplicitImportPresent = false;
	isMapWildCardImportPresent = false;
}

public void refactorFileEntrySetInsteadOfKeySet(loc fileLoc) {
	shouldRewrite = false;
	resetImportPresenceBools();

	unit = retrieveCompilationUnitFromLoc(fileLoc);
	findFields(unit);
	
	unit = top-down-break visit(unit) {
		// what about static initializers?
	
		case (MethodDeclaration) `<MethodDeclaration mdl>`: {
			modified = false;
			mdl = visit(mdl) {
				case (EnhancedForStatement) `<EnhancedForStatement enhancedForStmt>`: {
					enhancedForStmt = visit(enhancedForStmt) {
						case (EnhancedForStatement) `for ( <VariableModifier* vm> <UnannType iteratedVarType> <VariableDeclaratorId iteratedVarName>: <Expression exp> ) <Statement loopBody>`: {
							map[str, Var] localVarsByName = findVarsInstantiatedInMethod(mdl);
							possibleMapExp = isExpressionCallingKeySetOnAMapInstance(exp, localVarsByName);
							if (possibleMapExp.isMapReference) {
								set[MethodInvocation] mapGetCalls = callsToMapGet(loopBody, possibleMapExp, iteratedVarName);
								if (size(mapGetCalls) > 0) {
									modified = true;
									mapVar = expVar(possibleMapExp.exp, localVarsByName);
									
									loopBody = refactorLoopBody(loopBody, mapGetCalls, "<iteratedVarType>", iteratedVarName);
									
									mapEntryReference = getMapEntryQualifiedReference(unit);
									refactoredIteratedVarType = parse(#UnannType, "<mapEntryReference><mapVar.generics>");
									refactoredIteratedVarName = parse(#VariableDeclaratorId, ENTRY_NAME);
									refactoredExp = parse(#Expression, "<possibleMapExp.exp>.entrySet()");
									
									// Ugly, but works to add a space after VariableModifier, if it's the case
									if (isEmpty("<vm>")) {
										insert (EnhancedForStatement) `for (<VariableModifier* vm><UnannType refactoredIteratedVarType> <VariableDeclaratorId refactoredIteratedVarName> : <Expression refactoredExp>) <Statement loopBody>`;					
									} else {
										insert (EnhancedForStatement) `for (<VariableModifier* vm> <UnannType refactoredIteratedVarType> <VariableDeclaratorId refactoredIteratedVarName> : <Expression refactoredExp>) <Statement loopBody>`;														
									}
							
								}
							}
						}
					}
					if (modified) {
						insert enhancedForStmt;
					}
				}
			}
			if (modified) {
				shouldRewrite = true;
				insert mdl;
			}
		}
	}
	
	if (shouldRewrite) {
		unit = addNeededImports(unit);
		writeFile(fileLoc, unit);
	} 
}

private void findFields(CompilationUnit unit) {
	set[MethodVar] fields = findClassFields(unit);
	for (field <- fields) {
		fieldsByName[field.name] = newVar(field.name, varTypeWithoutGenerics(field.varType), extractGenericsFromVarType(field.varType));
	}
}

private str varTypeWithoutGenerics(str varType) {
	indexOfOpeningGenerics = findFirst(varType, "\<");
	if (indexOfOpeningGenerics != -1) {
		return substring(varType, 0, indexOfOpeningGenerics);
	}
	return varType;
}

private str extractGenericsFromVarType(str varType) {
	indexOfOpeningGenerics = findFirst(varType, "\<");
	if (indexOfOpeningGenerics != -1) {
		return substring(varType, indexOfOpeningGenerics);
	}
	return "";
}

private map[str, Var] findVarsInstantiatedInMethod(MethodDeclaration mdl) {
	map[str, Var] varsInMethod = ();
	set[MethodVar] vars = findlocalVars(mdl);
	for (var <- vars) {
		varsInMethod[var.name] = newVar(var.name, varTypeWithoutGenerics(var.varType), extractGenericsFromVarType(var.varType));
	}
	return varsInMethod;
}

// What to do with: for (MMenuElement menuElement : new HashSet<>(modelToContribution.keySet())) 
private MapExp isExpressionCallingKeySetOnAMapInstance(Expression exp, map[str, Var] localVarsByName) {
	visit(exp) {
		case (MethodInvocation) `<ExpressionName beforeFunc>.keySet()`: {
			return generateMapExp(beforeFunc, localVarsByName);
		}
		case (MethodInvocation) `<Primary beforeFunc>.keySet()`: {
			return generateMapExp(beforeFunc, localVarsByName);
		}	
	}
	return mapExp(false, "", exp);
}

private MapExp generateMapExp(Tree beforeFunc, map[str, Var] localVarsByName) {
	if (isBeforeFuncAMapInstance("<beforeFunc>", localVarsByName)) {
		return mapExp(true, "<beforeFunc>", parse(#Expression, "<beforeFunc>"));
	} else {
		return mapExp(false, "", parse(#Expression, "<beforeFunc>"));
	}
}

private bool isBeforeFuncAMapInstance(str beforeFunc, map[str, Var] localVarsByName) {
	if (beforeFunc in localVarsByName) {
		return localVarsByName[beforeFunc].varType in mapTypes;
	}
	if (beforeFunc in fieldsByName) {
		return fieldsByName[beforeFunc].varType in mapTypes;
	}
	return false;
}

private set[MethodInvocation] callsToMapGet(Statement loopBody, MapExp mapExpr, VariableDeclaratorId iteratedVarName) {
	set[MethodInvocation] mapGetCalls = {};
	visit(loopBody) {
		case (MethodInvocation) `<MethodInvocation mi>`: {
			visit(mi) {
				case (MethodInvocation) `<ExpressionName beforeFunc>.get(<ArgumentList? args>)`: {
					if ("<beforeFunc>" == "<mapExpr.exp>" && trim("<args>") == trim("<iteratedVarName>")) {
						mapGetCalls += mi;
					}
				}
			}
		}
	}
	return mapGetCalls;
}

private Var expVar(Expression exp, map[str, Var] localVarsByName) {
	expStr = "<exp>";
	if (expStr in localVarsByName)
		return localVarsByName[expStr];
	if (expStr in fieldsByName)
		return fieldsByName[expStr];
	throw "Exp should be either a field or a local var";
}

private Statement refactorLoopBody(Statement loopBody, set[MethodInvocation] mapGetCalls, 
		str iteratedVarType, VariableDeclaratorId iteratedVarName) {
	loopBody = replaceGetCalls(loopBody, mapGetCalls);
	
	iteratedVarNameStr = trim("<iteratedVarName>");
	
	if (shouldKeepKeyAsLoopVar(loopBody, iteratedVarNameStr)) {
		loopBodyStr = "<loopBody>";
		keyAsVar = "<iteratedVarType><iteratedVarName>= <ENTRY_NAME>.getKey();";
		loopBodyStr = replaceFirst(loopBodyStr, "{", "{\n<keyAsVar>");
		return parse(#Statement, loopBodyStr);;
	} else {
		return refactorLoopBodyWithoutKeepingKeyAsLoopVar(loopBody, iteratedVarNameStr);
	}
	
	
}

private bool shouldKeepKeyAsLoopVar(Statement loopBody, str iteratedVarNameStr) {
	return KEEP_KEY_AS_A_LOOP_VARIABLE && 
		size(iteratedVarNameStr) >= 3 && 
		iteratedVarNameStr != "key" && 
		loopBodyReferencesKey(loopBody, iteratedVarNameStr);
}

private bool loopBodyReferencesKey(Statement loopBody, str iteratedVarNameStr) {
	visit (loopBody) {
		case (Identifier) `<Identifier id>`: {
			if (trim("<id>") == iteratedVarNameStr)
				return true;
		}
	}
	return false;
}

private Statement replaceGetCalls(Statement loopBody, set[MethodInvocation] mapGetCalls) {
	loopBody = visit(loopBody) {
		case (MethodInvocation) `<MethodInvocation mi>`: {
			if (mi in mapGetCalls) {
				insert parse(#MethodInvocation, "<ENTRY_NAME>.getValue()");
			}
		}
	}
	return loopBody;
}

private Statement refactorLoopBodyWithoutKeepingKeyAsLoopVar(Statement loopBody, str iteratedVarNameStr) {
	loopBody = visit(loopBody) {
		case (Expression) `<ExpressionName expName>`: {
			if (trim("<expName>") == iteratedVarNameStr)
				insert parse(#Expression, "<ENTRY_NAME>.getKey()");
		}
		case (UnaryExpression) `<UnaryExpression expName>`: {
			if (trim("<expName>") == iteratedVarNameStr) {
				insert parse(#UnaryExpression, "<ENTRY_NAME>.getKey()");
			} else {
				expNameStr = "<expName>";
				if (containsIteratedVarNameInRightSituation(iteratedVarNameStr, expNameStr)) {
					try {
						expRefactoredStr = replaceFirst(expNameStr, iteratedVarNameStr, "<ENTRY_NAME>.getKey()");
						expRefactored = parse(#UnaryExpression, expRefactoredStr);
						insert expRefactored;
					} catch: continue;
				}
			}
		}
	}
	return loopBody;
}

private bool containsIteratedVarNameInRightSituation(str iteratedVarNameStr, str expNameStr) {
	return findFirst(expNameStr, "<iteratedVarNameStr>.") != -1 ||
		endsWith(expNameStr, iteratedVarNameStr) ||
		containsIteratedVarNameAtLeast3Chars(iteratedVarNameStr, expNameStr);
}

// does not cover all cases
private bool containsIteratedVarNameAtLeast3Chars(str iteratedVarNameStr, str expNameStr) {
	if (size(iteratedVarNameStr) >= 3) {
		return findFirst(expNameStr, iteratedVarNameStr) != 1;
	}
	return false;
}

private str getMapEntryQualifiedReference(CompilationUnit unit) {
	computeImportsPresence(unit);
	if (isUtilWildCardImportPresent && !isMapWildCardImportPresent && !isMapEntryExplicitImportPresent) {
		return "Map.Entry";
	} else {
		return "Entry";
	}
}

private void computeImportsPresence(CompilationUnit unit) {
	unitStr = "<unit>";
	if (findFirst(unitStr, "import java.util.*;") != -1) {
		isUtilWildCardImportPresent = true;
	}
	if (findFirst(unitStr, "import java.util.Map.*;") != -1) {
		isMapWildCardImportPresent = true;
	}
	if (findFirst(unitStr, "import java.util.Map.Entry;") != -1) {
		isMapEntryExplicitImportPresent = true;
	}
}

private CompilationUnit addNeededImports(CompilationUnit unit) {
	importDecls = retrieveImportDeclarations(unit);
	entryImport = "import java.util.Map.Entry;";
	unitStr = unparse(unit);
	if (needsToAddMapEntryImport()) {
		if (findFirst(unitStr, "import java.util.Map;") != -1) {
			mapImport = "import java.util.Map;";
			unitStr = replaceFirst(unitStr, mapImport, "<mapImport>\n<entryImport>");
		}
		else {
			unitStr = unparse(addImport(unit, importDecls, "java.util.Map.Entry"));
		}
	}
	return parse(#CompilationUnit, unitStr);
}

private bool needsToAddMapEntryImport() {
	return !isUtilWildCardImportPresent && !isMapWildCardImportPresent && !isMapEntryExplicitImportPresent;
}
