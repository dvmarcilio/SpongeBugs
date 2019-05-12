module lang::java::refactoring::sonar::resourcesShouldBeClosed::ResourcesShouldBeClosed

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import Set;
import List;
import Map;
import lang::java::util::MethodDeclarationUtils;
import lang::java::util::CompilationUnitUtils;

private set[str] inputStreams = {"InputStream", "InputStreamReader", "ObjectInputStream", "FileInputStream",
	"StringBufferInputStream", "BufferedInputStream", "DataInputStream"};
private set[str] outputStreams = {"OutputStream", "OutputStreamWriter", "ObjectOutputStream", "FileOutputStream",
 	"BufferedOutputStream", "DataOutputStream"};
private set[str] readers = {"Reader", "FileReader", "BufferedReader"};
private set[str] writers = {"Writer", "FileWriter", "BufferedWriter"};
private set[str] others = {"Scanner"};

private set[str] typesWhichCloseHasNoEffect = {"ByteArrayOutputStream", "ByteArrayInputStream", "CharArrayReader", "CharArrayWriter", "StringReader", "StringWriter"};

private set[str] resourcesToConsider = inputStreams + outputStreams + readers + writers + others;

private bool shouldRewrite = false;

private data VarInstantiatedWithinBlock = varInstantiatedWithinBlock(str name, str varType, bool isResourceOfInterest, LocalVariableDeclaration initStatement);

public void resourcesShouldAllBeClosed(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			if (shouldContinueWithASTAnalysis(fileLoc)) {
				shouldRewrite = false; 
				resourcesShouldBeClosed(fileLoc);
			}
		} catch: {
			println("Exception file: " + fileLoc.file);
			continue;
		}	
	}
}

private bool shouldContinueWithASTAnalysis(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	return findFirst(javaFileContent, "import java.io.") != -1 || findFirst(javaFileContent, "import java.util.Scanner;") != -1;
}

public void resourcesShouldBeClosed(loc fileLoc) {
	unit = retrieveCompilationUnitFromLoc(fileLoc);
	
	unit = visit(unit) {
		case (MethodDeclaration) `<MethodDeclaration mdl>`: {
			modified = false;
			varsToMoveOutOfTryBlock = [];
			map[str, list[Statement]] stmtsReferingModifyingVarsToMoveOut = ();
			tryResourceSpecification = "";
			
			mdl = top-down-break visit(mdl) {
				case (TryWithResourcesStatement) `<TryWithResourcesStatement _>`: {
					continue;
				}
				case (TryStatement) `<TryStatement tryStmt>`: {
					tryStmt = visit(tryStmt) {
						case (TryStatement) `try <Block tryBlock> <Catches catches>`: {
							resourceSpecification = "";
							
							tryBlock = visit(tryBlock) {
								case (Block) `<Block block>`: {
									
									varsWithinBlock = findVarsInstantiatedWithinBlock(block);
									
									if (!isEmpty(varsWithinBlock)) {
										closesToRemove = collectClosesToRemoveForResources(block, varsWithinBlock);
										Block tryBlockRefactored = tryBlock;
										
										resourcesWithinBlock = [ var | VarInstantiatedWithinBlock var <- varsWithinBlock, var.isResourceOfInterest ];
										if(!isEmpty(resourcesWithinBlock)) {
											for (resourceWithinBlock <- resourcesWithinBlock) {
												tryBlockRefactored = parse(#Block, replaceFirst("<tryBlockRefactored>", "<resourceWithinBlock.initStatement>;", ""));
											}
											
											varsToMoveOutOfTryBlock = varsThatNeedToBeOutOfTryBlock(tryBlock, varsWithinBlock);
											stmtsReferingCurrentBlockBetweenVarAndResource = stmtsReferingVarBetweenVarAndResource(
												varsToMoveOutOfTryBlock, resourcesWithinBlock, tryBlock
											);
											stmtsReferingModifyingVarsToMoveOut += stmtsReferingCurrentBlockBetweenVarAndResource;
											
											for (varToMove <- varsToMoveOutOfTryBlock) {
												tryBlockRefactored = parse(#Block, replaceFirst("<tryBlockRefactored>", "<varToMove.initStatement>;", ""));
											}
											
											for (varNameToMove <- domain(stmtsReferingModifyingVarsToMoveOut)) {
												for (stmt <- stmtsReferingModifyingVarsToMoveOut[varNameToMove]) {
													tryBlockRefactored = parse(#Block, replaceFirst("<tryBlockRefactored>", "<stmt>", ""));
												}
											}
											
											for (closeToRemove <- closesToRemove) {
												tryBlockRefactored = parse(#Block, replaceFirst("<tryBlockRefactored>", closeToRemove, ""));
											}
											
											modified = true;
											
											resourceSpecification = generateResourceSpecificationForTryWithResources(resourcesWithinBlock);
											
											insert tryBlockRefactored;
										}
									}
								}				
							}
							
							if (modified) {
								tryStmt = parse(#TryStatement, "try <tryBlock> <catches>");								
							
								tryResourceSpecification = "try <resourceSpecification>";
								tryStmtWithResources = parse(#TryStatement, replaceFirst("<tryStmt>", "try", tryResourceSpecification));
								insert tryStmtWithResources;
							}
						}
					}
					
					if(modified) {
						insert tryStmt;
					}
				}
			}
			
			if (modified) {
				shouldRewrite = true;
				stmtsJustBeforeTry = generateStatementsMovedOutOfBlock(varsToMoveOutOfTryBlock, stmtsReferingModifyingVarsToMoveOut);
				mdlRefactored = insertStmtsJustBeforeTryInMethodDeclaration(stmtsJustBeforeTry, mdl, tryResourceSpecification);
				insert parse(#MethodDeclaration, mdlRefactored);
			}
		}
	}
	
	if (shouldRewrite) {
		writeFile(fileLoc, unit);
	}
		
}

private list[VarInstantiatedWithinBlock] findVarsInstantiatedWithinBlock(Block block) {
	list[VarInstantiatedWithinBlock] varsWithinBlock = [];
	visit (block) {
		case (LocalVariableDeclaration) `<LocalVariableDeclaration lVDecl>`: {
			visit(lVDecl) {	
				case (LocalVariableDeclaration) `<VariableModifier* varMod> <UnannType varType> <VariableDeclaratorList vdl>`: {
					visit(vdl) {
						case (VariableDeclarator) `<VariableDeclaratorId varId> = new <TypeArguments? _> <ClassOrInterfaceTypeToInstantiate typeInstantiated> (<ArgumentList? _>)`: {
							if (trim("<varType>") in resourcesToConsider && trim("<typeInstantiated>") notin typesWhichCloseHasNoEffect) {
								varsWithinBlock += varInstantiatedWithinBlock(trim("<varId>"), trim("<varType>"), true, lVDecl);
							} else {
								varsWithinBlock += varInstantiatedWithinBlock(trim("<varId>"), trim("<varType>"), false, lVDecl);
							}
						}
					}
				}
			}
		}
	}
	
	return varsWithinBlock;
}

private bool isVarInstantiatedAsTypeToIgnore(MethodDeclaration mdl, str varName) {
	visit(mdl) {
		case (VariableDeclarator) `<VariableDeclaratorId varId> = new <TypeArguments? _> <ClassOrInterfaceTypeToInstantiate typeInstantiated> (<ArgumentList? _>)`: {
			return trim("<varId>") == varName && "<typeInstantiated>" in typesWhichCloseHasNoEffect;
		}
	}
	return false;
}

private list[str] collectClosesToRemoveForResources(Block block, list[VarInstantiatedWithinBlock] vars) {
	resourcesNamesWithinBlock = { var.name | VarInstantiatedWithinBlock var <- vars, var.isResourceOfInterest };
	return collectClosesToRemove(block, resourcesNamesWithinBlock);

}

private list[str] collectClosesToRemove(Block block, set[str] varNames) {
	list[str] closesToRemove = [];
	visit(block) {
		case(ExpressionStatement) `<ExpressionStatement exp>`: {
			visit(exp) {
				case (MethodInvocation) `<ExpressionName beforeFunc>.<TypeArguments? _>close()`: {
					if (trim("<beforeFunc>") in varNames)
						closesToRemove += "<exp>";
				}
			}
		}
	}
	return closesToRemove;
}

private list[VarInstantiatedWithinBlock] varsThatNeedToBeOutOfTryBlock(Block tryBlock, list[VarInstantiatedWithinBlock] varsInstantiatedWithinBlock) {
	list[str] varsNamesToMove = varsNamesThatNeedToBeOutOfTryBlock(tryBlock, varsInstantiatedWithinBlock);
	return [ var | VarInstantiatedWithinBlock var <- varsInstantiatedWithinBlock, var.name in varsNamesToMove ];
}

// recursively, guess we need to start from bottom up
// the resources need another variable, that may need another variable and so on
// TODO this can be improved continuosly
private list[str] varsNamesThatNeedToBeOutOfTryBlock(Block tryBlock, list[VarInstantiatedWithinBlock] varsInstantiatedWithinBlock) {
	list[str] varsNamesToMove = [];
	
	varsNamesWithinBlock = { var.name | VarInstantiatedWithinBlock var <- varsInstantiatedWithinBlock, !var.isResourceOfInterest };
	resourcesWithinBlock = { var | VarInstantiatedWithinBlock var <- varsInstantiatedWithinBlock, var.isResourceOfInterest };
	
	for (resourceWithinBlock <- resourcesWithinBlock) {
		visit (resourceWithinBlock.initStatement) {
			case (ArgumentList) `<ArgumentList args>`: {
				for (arg <- split(",", "<args>")) {
					if (trim(arg) in varsNamesWithinBlock) {
						varsNamesToMove += trim(arg);
					}
				}
			}
		}
	}
	return varsNamesToMove;
}

private str generateResourceSpecificationForTryWithResources(list[VarInstantiatedWithinBlock] resourcesWithinBlock) {
	initStatements =  [ "<var.initStatement>" | VarInstantiatedWithinBlock var <- resourcesWithinBlock ];
	intercalated = intercalate("; ", initStatements);
	return "(<intercalated>)";
}

// O(m*n) is it the best way?
private map[str, list[Statement]] stmtsReferingVarBetweenVarAndResource(list[VarInstantiatedWithinBlock] vars,
	list[VarInstantiatedWithinBlock] resourcesWithinBlock, Block tryBlock) {
	
	map[str, list[Statement]] stmts = ();
	for (var <- vars) {
		for (resource <- resourcesWithinBlock) {
			stmts += doStmtsReferingVarBetweenVarAndResource(var, resource, tryBlock);
		}
	}
	return stmts;
}

private map[str, list[Statement]] doStmtsReferingVarBetweenVarAndResource(VarInstantiatedWithinBlock var, VarInstantiatedWithinBlock resource, Block tryBlock) {
	assert(!var.isResourceOfInterest);
	assert(resource.isResourceOfInterest);
	
	blockStr = "<tryBlock>";
	endIndexOfVar = findFirst(blockStr, "<var.initStatement>") + size("<var.initStatement>") + 1;
	indexOfResource = findFirst(blockStr, "<resource.initStatement>") - 1;
	
	if (indexOfResource < endIndexOfVar)
		return ();
		
	blockInBetween = substring(blockStr, endIndexOfVar, indexOfResource);
	stmtsInBetween = split(";", blockInBetween);
	
	if (!isEmpty(stmtsInBetween)) {
		map[str, list[Statement]] stmts = ();
		for (stmt <- stmtsInBetween) {
			stmt = trim(stmt);
			if (isStatementRelatedToVar(stmt, var.name)) {
				if (var.name in stmts) {
					stmts[var.name] += [parse(#Statement, "<stmt>;")];
				} else {
					stmts[var.name] = [parse(#Statement, "<stmt>;")];
				}
			} 
		}
		return stmts;
	}
	return ();
}

private bool isStatementRelatedToVar(str stmt, str varName) {
	try {
		assignment = parse(#Assignment, stmt);
		visit(assignment) {
			case (Assignment) `<LeftHandSide lhs> = <Expression exp>`: {
				if (findFirst("<lhs>", varName) != 1)
					return true;
			}
		}
	} catch: "";
	
	try {
		mi = parse(#MethodInvocation, stmt);
		visit(mi) {
			case (MethodInvocation) `<ExpressionName beforeFunc>.<TypeArguments? ts> <Identifier id> (<ArgumentList? args>)`: {
				possibleChainBefore = split(".", "<beforeFunc>");
				for (idInChain <- possibleChainBefore) {
					if (idInChain == varName)
						return true;
				}
				
				possibleChainArgs = split(".", "<args>");
				for (idInChain <- possibleChainArgs) {
					if (idInChain == varName)
						return true;
				}
			}
			case (MethodInvocation) `<Primary beforeFunc>.<TypeArguments? ts> <Identifier id> (<ArgumentList? args>)`: {
				possibleChainBefore = split(".", "<beforeFunc>");
				for (idInChain <- possibleChainBefore) {
					if (idInChain == varName)
						return true;
				}
				
				possibleChainArgs = split(".", "<args>");
				for (idInChain <- possibleChainArgs) {
					if (idInChain == varName)
						return true;
				}
			}
		}
	} catch: "";
	
	
	return false;
}

private str generateStatementsMovedOutOfBlock(list[VarInstantiatedWithinBlock] varsToMoveOutOfTryBlock,
	map[str, list[Statement]] stmtsReferingModifyingVarsToMoveOut) {
	
	list[str] stmts = [];
	
	for (var <- varsToMoveOutOfTryBlock) {
		stmts += "<var.initStatement>;\n";
		if (var.name in stmtsReferingModifyingVarsToMoveOut) {
			stmts += [ "<stmt>\n" | Statement stmt <- stmtsReferingModifyingVarsToMoveOut[var.name] ];
		}
	}
	
	return intercalate("", stmts);	
}

private str insertStmtsJustBeforeTryInMethodDeclaration(str stmts, MethodDeclaration mdl, str tryResourceSpecification) {
	
	mdlStr = "<mdl>";
	indexOfTry = findFirst(mdlStr, tryResourceSpecification);
	mdlBeforeTryWithResources = substring(mdlStr, 0, indexOfTry);
	mdlFromTryToTheEnd = substring(mdlStr, indexOfTry);
	return mdlBeforeTryWithResources + stmts + mdlFromTryToTheEnd;
}