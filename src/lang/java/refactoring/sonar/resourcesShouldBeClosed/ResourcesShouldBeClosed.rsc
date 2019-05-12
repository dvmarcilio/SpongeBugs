module lang::java::refactoring::sonar::resourcesShouldBeClosed::ResourcesShouldBeClosed

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import Set;
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

private data VarsInstantiatedWithinBlock = varsInstantiatedWithinBlock(str name, str varType, bool isResourceOfInterest, LocalVariableDeclaration initStatement);

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
			candidateResourcesWithinBlock = {};
			
			mdl = top-down-break visit(mdl) {
				case (TryWithResourcesStatement) `<TryWithResourcesStatement _>`: {
					continue;
				}
				case (TryStatement) `try <Block tryBlock> <Catches catches>`: {
					tryBlock = visit(tryBlock) {
						case (Block) `<Block block>`: {
							varsWithinBlock = findVarsInstantiatedWithinBlock(block);
							if (!isEmpty(varsWithinBlock)) {
								closesToRemove = collectClosesToRemoveForResources(block, varsWithinBlock);
								Block tryBlockRefactored = tryBlock;
								
								resourcesWithinBlock = { var | VarsInstantiatedWithinBlock var <- varsWithinBlock, var.isResourceOfInterest };
								for (resourceWithinBlock <- resourcesWithinBlock) {
									tryBlockRefactored = parse(#Block, replaceFirst("<tryBlockRefactored>", "<resourceWithinBlock.initStatement>;", ""));
								}
								
								for (closeToRemove <- closesToRemove) {
									tryBlockRefactored = parse(#Block, replaceFirst("<tryBlockRefactored>", closeToRemove, ""));
								}
								println("<tryBlockRefactored>");
							}
							
						}
					
						//case (CatchClause) `catch (<CatchFormalParameter _>) <Block catchBlock>`: {
						//	println("*** CATCH ***\n");
						//	println("<catchBlock>");
						//	println();
						//}
						
						//case (MethodInvocation) `<ExpressionName beforeFunc>.<TypeArguments? _>close()`: {
						//	localVars = findVars(mdl);
						//	varName = "<beforeFunc>";
						//	println(fileLoc.file);
						//	println(varName);
						//	if ("<beforeFunc>" in retrieveNonParametersNames(localVars)) {
						//		MethodVar var = findByName(localVars, varName);
						//		if (varIsCandidate(mdl, varName, var)) {
						//			println("candidate for refactoring");
						//		}
						//	}				
						//	println();
						//	
						//}
						//case (MethodInvocation) `<Primary beforeFunc>.<TypeArguments? _>close()`: {
						//	println("primary");
						//}
					
					}
				}
			}
			
		}
	}
		
}

private set[VarsInstantiatedWithinBlock] findVarsInstantiatedWithinBlock(Block block) {
	set[VarsInstantiatedWithinBlock] varsWithinBlock = {};
	visit (block) {
		case (LocalVariableDeclaration) `<LocalVariableDeclaration lVDecl>`: {
			visit(lVDecl) {	
				case (LocalVariableDeclaration) `<VariableModifier* varMod> <UnannType varType> <VariableDeclaratorList vdl>`: {
					visit(vdl) {
						case (VariableDeclarator) `<VariableDeclaratorId varId> = new <TypeArguments? _> <ClassOrInterfaceTypeToInstantiate typeInstantiated> (<ArgumentList? _>)`: {
							if (trim("<varType>") in resources && trim("<typeInstantiated>") notin typesWhichCloseHasNoEffect) {
								varsWithinBlock += varsInstantiatedWithinBlock(trim("<varId>"), trim("<varType>"), true, lVDecl);
							} else {
								varsWithinBlock += varsInstantiatedWithinBlock(trim("<varId>"), trim("<varType>"), false, lVDecl);
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

private list[str] collectClosesToRemoveForResources(Block block, set[VarsInstantiatedWithinBlock] vars) {
	resourcesNamesWithinBlock = { var.name | VarsInstantiatedWithinBlock var <- vars, var.isResourceOfInterest };
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