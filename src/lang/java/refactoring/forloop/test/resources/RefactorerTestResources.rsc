module lang::java::refactoring::forloop::\test::resources::RefactorerTestResources

import IO;
import ParseTree;
import lang::java::\syntax::Java18;

public data RefactorableFor = refactorableFor(CompilationUnit unit, MethodHeader header, MethodBody body, MethodBody refactored);

public RefactorableFor innerLoopButNotOuterLoop() {
	classLoc = |project://rascal-Java8//testes/forloop/Refactorer/ServletComponentRegisteringPostProcessor.java|;
	unit = parse(#CompilationUnit, readFile(classLoc));
	header = parse(#MethodHeader, "void scanPackage(\r\n\t\t\tClassPathScanningCandidateComponentProvider componentProvider,\r\n\t\t\tString packageToScan)"); 
	body = parse(#MethodBody, "{\r\n\t\tfor (BeanDefinition candidate : componentProvider\r\n\t\t\t\t.findCandidateComponents(packageToScan)) {\r\n\t\t\tif (candidate instanceof ScannedGenericBeanDefinition) {\r\n\t\t\t\tfor (ServletComponentHandler handler : HANDLERS) {\r\n\t\t\t\t\thandler.handle(((ScannedGenericBeanDefinition) candidate),\r\n\t\t\t\t\t\t\t(BeanDefinitionRegistry) this.applicationContext);\r\n\t\t\t\t}\r\n\t\t\t}\r\n\t\t}\r\n\t}");
	
	refactored = parse(#MethodBody, "{\r\n\t\tfor (BeanDefinition candidate : componentProvider\r\n\t\t\t\t.findCandidateComponents(packageToScan)) {\r\n\t\t\tif (candidate instanceof ScannedGenericBeanDefinition) {\r\n\t\t\t\tHANDLERS.forEach(handler -\> {\nhandler.handle(((ScannedGenericBeanDefinition) candidate),\r\n\t\t\t\t\t\t\t(BeanDefinitionRegistry) this.applicationContext);\n});\r\n\t\t\t}\r\n\t\t}\r\n\t}");
	
	return refactorableFor(unit, header, body, refactored);
}