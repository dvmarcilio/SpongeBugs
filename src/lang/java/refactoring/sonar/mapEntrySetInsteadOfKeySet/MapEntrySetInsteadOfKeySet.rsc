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

private set[str] mapTypes = {"Map", "HashMap", "LinkedHashMap", "TreeMap"};

private data MapExp = mapExp(bool isMapReference, str name, Expression exp);

private str ENTRY_NAME = "entry";

public void refactorAllEntrySetInsteadOfKeySet(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			if (shouldContinueWithASTAnalysis(fileLoc)) {
				shouldRewrite = false;
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

public void refactorFileEntrySetInsteadOfKeySet(loc fileLoc) {
	unit = retrieveCompilationUnitFromLoc(fileLoc);
	findFields(unit);
	
	unit = top-down-break visit(unit) {
		case (MethodDeclaration) `<MethodDeclaration mdl>`: {
			modified = false;
			mdl = visit(mdl) {
				case (EnhancedForStatement) `<EnhancedForStatement enhancedForStmt>`: {
					enhancedForStmt = visit(enhancedForStmt) {
						case (EnhancedForStatement) `for ( <VariableModifier* vm> <UnannType ut> <VariableDeclaratorId iteratedVarName>: <Expression exp> ) <Statement loopBody>`: {
							map[str, Var] localVarsByName = findVarsInstantiatedInMethod(mdl);
							possibleMapExp = isExpressionCallingKeySetOnAMapInstance(exp, localVarsByName);
							if (possibleMapExp.isMapReference) {
									set[MethodInvocation] mapGetCalls = callsToMapGet(loopBody, possibleMapExp, iteratedVarName);
								if (size(mapGetCalls) > 0) {
									modified = true;
									mapVar = expVar(possibleMapExp.exp, localVarsByName);
									
									loopBody = refactorLoopBody(loopBody, possibleMapExp, mapVar , mapGetCalls, iteratedVarName);
									
									ut = parse(#UnannType, "Entry<mapVar.generics>");
									iteratedVarName = parse(#VariableDeclaratorId, ENTRY_NAME);
									exp = parse(#Expression, "<possibleMapExp.exp>.entrySet()");
									
									// Ugly, but works to add a space after VariableModifier, if it's the case
									if (isEmpty("<vm>")) {
									insert (EnhancedForStatement) `for (<VariableModifier* vm><UnannType ut> <VariableDeclaratorId iteratedVarName> : <Expression exp>) <Statement loopBody>`;					
									} else {
										insert (EnhancedForStatement) `for (<VariableModifier* vm> <UnannType ut> <VariableDeclaratorId iteratedVarName> : <Expression exp>) <Statement loopBody>`;														
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

private set[MethodInvocation] callsToMapGet(Statement loopBody, MapExp mapExp, VariableDeclaratorId iteratedVarName) {
	set[MethodInvocation] mapGetCalls = {};
	visit(loopBody) {
		case (MethodInvocation) `<MethodInvocation mi>`: {
			visit(mi) {
				case (MethodInvocation) `<ExpressionName beforeFunc>.get(<ArgumentList? args>)`: {
					if ("<beforeFunc>" == "<mapExp.exp>" && trim("<args>") == trim("<iteratedVarName>")) {
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

private Statement refactorLoopBody(Statement loopBody, MapExp mapExp, Var var,
		set[MethodInvocation] mapGetCalls, VariableDeclaratorId iteratedVarName) {
	loopBody = replaceGetCalls(loopBody, mapGetCalls);
	loopBody = visit(loopBody) {
		case (Expression) `<ExpressionName expName>`: {
			if(trim("<expName>") == trim("<iteratedVarName>"))
				insert parse(#Expression, "<ENTRY_NAME>.getKey()");
		}
		case (UnaryExpression) `<UnaryExpression expName>`: {
			if(trim("<expName>") == trim("<iteratedVarName>"))
				insert parse(#UnaryExpression, "<ENTRY_NAME>.getKey()");
		}
	}
	return loopBody;
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

private CompilationUnit addNeededImports(CompilationUnit unit) {
	importDecls = retrieveImportDeclarations(unit);
	entryImport = "import java.util.Map.Entry;";
	unitStr = unparse(unit);
	if (!isAnyImportPresent(importDecls, "java.util.*", "java.util.Map.*", "java.util.Map.Entry")) {
		//unit = addImport(unit, importDecls, "java.util.Map.Entry");
		mapImport = "import java.util.Map;";
		unitStr = replaceFirst(unitStr, mapImport, "<mapImport>\n<entryImport>");
	}
	return parse(#CompilationUnit, unitStr);
}
