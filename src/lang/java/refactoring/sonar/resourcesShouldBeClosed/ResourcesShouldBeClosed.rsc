module lang::java::refactoring::sonar::resourcesShouldBeClosed::ResourcesShouldBeClosed

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import Set;
import List;
import lang::java::util::MethodDeclarationUtils;
import lang::java::util::CompilationUnitUtils;
import lang::java::refactoring::forloop::LocalVariablesFinder;
import lang::java::refactoring::forloop::MethodVar;

private set[str] inputStreams = {"InputStream", "InputStreamReader", "ObjectInputStream", "FileInputStream",
	"StringBufferInputStream", "BufferedInputStream"};
private set[str] outputStreams = {"OutputStream", "OutputStreamWriter", "ObjectOutputStream", "FileOutputStream", "BufferedOutputStream"};
private set[str] readers = {"Reader", "FileReader", "BufferedReader"};
private set[str] writers = {"Writer", "FileWriter", "BufferedWriter"};
private set[str] others = {"Scanner"};

private set[str] typesWhichCloseHasNoEffect = {"ByteArrayOutputStream", "ByteArrayInputStream", "CharArrayReader", "CharArrayWriter", "StringReader", "StringWriter"};

private set[str] resources = inputStreams + outputStreams + readers + writers + others;

private bool shouldRewrite = false;

private data VarInstantiatedWithinBlock = varInstantiatedWithinBlock(str name, str varType, bool isResourceOfInterest, LocalVariableDeclaration initStatement);

// Checking only if resources are being closed within finally blocks
public void resourcesShouldAllBeClosed(list[loc] locs) {
	for(fileLoc <- locs) {
		//try {
			if (shouldContinueWithASTAnalysis(fileLoc)) {
				shouldRewrite = false; 
				resourcesShouldBeClosed(fileLoc);
			}
		//} catch: {
		//	println("Exception file: " + fileLoc.file);
		//	continue;
		//}	
	}
}

private bool shouldContinueWithASTAnalysis(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	return findFirst(javaFileContent, "throws IOException") != -1 && findFirst(javaFileContent, "import java.io.") != -1;
}

public void resourcesShouldBeClosed(loc fileLoc) {
	unit = retrieveCompilationUnitFromLoc(fileLoc);
	
	unit = visit(unit) {
		case (MethodDeclaration) `<MethodDeclaration mdl>`: {
			modified = false;
			varsToMoveOutOfTryBlock = {};
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
										
										resourcesWithinBlock = { var | VarInstantiatedWithinBlock var <- varsWithinBlock, var.isResourceOfInterest };
										if(!isEmpty(resourcesWithinBlock)) {
											for (resourceWithinBlock <- resourcesWithinBlock) {
												tryBlockRefactored = parse(#Block, replaceFirst("<tryBlockRefactored>", "<resourceWithinBlock.initStatement>;", ""));
											}
											
											varsToMoveOutOfTryBlock = varsThatNeedToBeOutOfTryBlock(tryBlock, varsWithinBlock);
											for (varToMove <- varsToMoveOutOfTryBlock) {
												tryBlockRefactored = parse(#Block, replaceFirst("<tryBlockRefactored>", "<varToMove.initStatement>;", ""));
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
							
								tryResourceSpecification = "try<resourceSpecification>";
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
				stmtsJustBeforeTry = generateStatementsMovedOutOfBlock(varsToMoveOutOfTryBlock);
				mdlRefactored = insertStmtsJustBeforeTryInMethodDeclaration(stmtsJustBeforeTry, mdl, tryResourceSpecification);
				insert parse(#MethodDeclaration, mdlRefactored);
			}
		}
	}
	
	if (shouldRewrite) {
		writeFile(fileLoc, unit);
	}
		
}

private set[VarInstantiatedWithinBlock] findVarsInstantiatedWithinBlock(Block block) {
	set[VarInstantiatedWithinBlock] varsWithinBlock = {};
	visit (block) {
		case (LocalVariableDeclaration) `<LocalVariableDeclaration lVDecl>`: {
			visit(lVDecl) {	
				case (LocalVariableDeclaration) `<VariableModifier* varMod> <UnannType varType> <VariableDeclaratorList vdl>`: {
					visit(vdl) {
						case (VariableDeclarator) `<VariableDeclaratorId varId> = new <TypeArguments? _> <ClassOrInterfaceTypeToInstantiate typeInstantiated> (<ArgumentList? _>)`: {
							if (trim("<varType>") in resources && trim("<typeInstantiated>") notin typesWhichCloseHasNoEffect) {
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

private set[MethodVar] findVars(MethodDeclaration mdl) {
	visit (mdl) {
		case (MethodDeclaration) `<MethodModifier* mds> <MethodHeader methodHeader> <MethodBody mBody>`: {
			return findLocalVariables(methodHeader, mBody);
		}
	}
	return {};
}

private bool isVarCandidate(MethodDeclaration mdl, MethodVar var) {
	return var.varType in resources && !isVarInstantiatedAsTypeToIgnore(mdl, var.name);
}

private bool isVarInstantiatedAsTypeToIgnore(MethodDeclaration mdl, str varName) {
	visit(mdl) {
		case (VariableDeclarator) `<VariableDeclaratorId varId> = new <TypeArguments? _> <ClassOrInterfaceTypeToInstantiate typeInstantiated> (<ArgumentList? _>)`: {
			return trim("<varId>") == varName && "<typeInstantiated>" in typesWhichCloseHasNoEffect;
		}
	}
	return false;
}

private list[str] collectClosesToRemoveForResources(Block block, set[VarInstantiatedWithinBlock] vars) {
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

private set[VarInstantiatedWithinBlock] varsThatNeedToBeOutOfTryBlock(Block tryBlock, set[VarInstantiatedWithinBlock] varsInstantiatedWithinBlock) {
	set[str] varsNamesToMove = varsNamesThatNeedToBeOutOfTryBlock(tryBlock, varsInstantiatedWithinBlock);
	return { var | VarInstantiatedWithinBlock var <- varsInstantiatedWithinBlock, var.name in varsNamesToMove };
}

// recursively, guess we need to start from bottom up
// the resources need another variable, that may need another variable and so on
// TODO this can be improved continuosly
private set[str] varsNamesThatNeedToBeOutOfTryBlock(Block tryBlock, set[VarInstantiatedWithinBlock] varsInstantiatedWithinBlock) {
	set[str] varsNamesToMove = {};
	
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

private str generateResourceSpecificationForTryWithResources(set[VarInstantiatedWithinBlock] resourcesWithinBlock) {
	initStatements =  [ "<var.initStatement>" | VarInstantiatedWithinBlock var <- resourcesWithinBlock ];
	intercalated = intercalate("; ", initStatements);
	return "(<intercalated>)";
}

private str generateStatementsMovedOutOfBlock(set[VarInstantiatedWithinBlock] varsToMoveOutOfTryBlock) {
	list[str] stmts = [ "<var.initStatement>;\n" | VarInstantiatedWithinBlock var <- varsToMoveOutOfTryBlock ];
	return intercalate("", stmts);	
}

private str insertStmtsJustBeforeTryInMethodDeclaration(str stmts, MethodDeclaration mdl, str tryResourceSpecification) {
	mdlStr = "<mdl>";
	indexOfTry = findFirst(mdlStr, tryResourceSpecification);
	mdlBeforeTryWithResources = substring(mdlStr, 0, indexOfTry);
	mdlFromTryToTheEnd = substring(mdlStr, indexOfTry);
	return mdlBeforeTryWithResources + stmts + mdlFromTryToTheEnd;
}