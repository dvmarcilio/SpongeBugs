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
			
			mdl = visit(mdl) {
				case (TryWithResourcesStatement) `<TryWithResourcesStatement _>`: {
					continue;
				}
				case (MethodInvocation) `<ExpressionName beforeFunc>.<TypeArguments? _>close()`: {
					localVars = findVars(mdl);
					varName = "<beforeFunc>";
					println(fileLoc.file);
					println(varName);
					if ("<beforeFunc>" in retrieveNonParametersNames(localVars)) {
						MethodVar var = findByName(localVars, varName);
						if (isVarInstantiatedAsTypeToIgnore(mdl, varName)) {
							println("var instantiated as type to ignore");
						} else if (var.varType in resources) {
							println("varType calling close in resources");
						}
					}				
					println();
					
				}
				case (MethodInvocation) `<Primary beforeFunc>.<TypeArguments? _>close()`: {
					println("primary");
				}
			}
			
		}
	}
		
}

private set[MethodVar] findVars(MethodDeclaration mdl) {
	visit (mdl) {
		case (MethodDeclaration) `<MethodModifier* mds> <MethodHeader methodHeader> <MethodBody mBody>`: {
			return findLocalVariables(methodHeader, mBody);
		}
	}
	return {};
}

public bool isVarInstantiatedAsTypeToIgnore(MethodDeclaration mdl, str varName) {
	visit(mdl) {
		case (VariableDeclarator) `<VariableDeclaratorId varId> = new <TypeArguments? _> <ClassOrInterfaceTypeToInstantiate typeInstantiated> (<ArgumentList? _>)`: {
			return trim("<varId>") == varName && "<typeInstantiated>" in typesWhichCloseHasNoEffect;
		}
	}
	return false;
}