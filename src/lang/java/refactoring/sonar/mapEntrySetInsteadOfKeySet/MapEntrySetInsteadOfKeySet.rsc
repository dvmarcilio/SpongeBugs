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

private data Var = newVar(str name, str varType);

private map[str, Var] fieldsByName = ();

private bool shouldRewrite = false;

private set[str] mapTypes = {"Map", "HashMap", "LinkedHashMap", "TreeMap"};

public void refactorAllEntrySetInsteadOfKeySet(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			if (shouldContinueWithASTAnalysis(fileLoc)) {
				shouldRewrite = false;
				refactorFileEntrySetInsteadOfKeySet(fileLoc);
			}
		} catch: {
			println("Exception file: " + fileLoc.file);
			continue;
		}
	}
}

private bool shouldContinueWithASTAnalysis(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	return findFirst(javaFileContent, ".keySet()") != 1;
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
						case (EnhancedForStatement) `for ( <VariableModifier* _> <UnannType _> <VariableDeclaratorId iteratedVarName>: <Expression exp> ) <Statement loopBody>`: {
							map[str, Var] localVarsByName = findVarsInstantiatedInMethod(mdl);
							if (isExpressionCallingKeySetOnAMapInstance(exp, localVarsByName)) {
								println("enhancedFor interating on keySet()");
								println(fileLoc.file);
								println();
							}
						}
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
		writeFile(fileLoc, unit);
	} 
}

private void findFields(CompilationUnit unit) {
	set[MethodVar] fields = findClassFields(unit);
	for (field <- fields) {
		fieldsByName[field.name] = newVar(field.name, varTypeWithoutGenerics(field.varType));
	}
}

private str varTypeWithoutGenerics(str varType) {
	indexOfOpeningGenerics = findFirst(varType, "\<");
	if (indexOfOpeningGenerics != -1) {
		return substring(varType, 0, indexOfOpeningGenerics);
	}
	return varType;
}

private map[str, Var] findVarsInstantiatedInMethod(MethodDeclaration mdl) {
	map[str, Var] varsInMethod = ();
	set[MethodVar] vars = findlocalVars(mdl);
	for (var <- vars) {
		varsInMethod[var.name] = newVar(var.name, varTypeWithoutGenerics(var.varType));
	}
	return varsInMethod;
}

// What to do with: for (MMenuElement menuElement : new HashSet<>(modelToContribution.keySet())) 
private bool isExpressionCallingKeySetOnAMapInstance(Expression exp, map[str, Var] localVarsByName) {
	visit(exp) {
		case (MethodInvocation) `<ExpressionName beforeFunc>.keySet()`: {
			return isBeforeFuncAMapInstance("<beforeFunc>", localVarsByName);
		}
		case (MethodInvocation) `<Primary beforeFunc>.keySet()`: {
			return isBeforeFuncAMapInstance("<beforeFunc>", localVarsByName);
		}	
	}
	return false;
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
