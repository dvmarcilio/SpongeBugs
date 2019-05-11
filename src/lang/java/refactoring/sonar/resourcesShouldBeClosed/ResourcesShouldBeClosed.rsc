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
import lang::java::m3::M3Util;
import lang::java::analysis::RascalJavaInterface;

public void resourcesShouldAllBeClosed(str projectDir) {
	projectDirLoc = |file:///| + projectDir;
	locs = listAllJavaFiles(projectDirLoc);
	initDB(projectDir);
	
	resourcesShouldAllBeClosed(locs);
}

private void resourcesShouldAllBeClosed(list[loc] locs) {
	for(fileLoc <- locs) {
		//try {
			if (shouldContinueWithASTAnalysis(fileLoc)) {
				shouldRewrite = false;
				println(fileLoc.file);
				println(isRelated("FileInputStream", "Closeable"));
			}
		//} catch: {
		//	println("Exception file: " + fileLoc.file);
		//	continue;
		//}	
	}
}

private bool shouldContinueWithASTAnalysis(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	return findFirst(javaFileContent, "IOException") != 1;
}