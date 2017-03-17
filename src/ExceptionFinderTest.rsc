module ExceptionFinderTest

import lang::java::m3::M3Util;
import IO;
import ExceptionFinder;

private loc zipFile = |jar:///D:/exception-hierarchy.zip!|;
private list[loc] javaClassesLocations = listAllJavaFiles(zipFile);

public test bool shouldReturnExceptionClass() {
	set[str] checkedExceptions = findCheckedExceptions(javaClassesLocations);
	return "Exception" in checkedExceptions;
}

public test bool shouldReturnLevelTwoHierarchyClasses() {
	set[str] checkedExceptions = findCheckedExceptions(javaClassesLocations);
	return "AException" in checkedExceptions && "BException" in checkedExceptions &&
	 	"CException" in checkedExceptions && "ZException" in checkedExceptions;
}

public test bool shouldReturnLevelThreeHierarchyClasses() {
	set[str] checkedExceptions = findCheckedExceptions(javaClassesLocations);
	return "DException" in checkedExceptions && "FException" in checkedExceptions &&
		"IException" in checkedExceptions;
}

public test bool shouldReturnLevelFourHierarchyClasses() {
	set[str] checkedExceptions = findCheckedExceptions(javaClassesLocations);
	return "LException" in checkedExceptions && "EException" in checkedExceptions &&
		"JException" in checkedExceptions && "HException" in checkedExceptions; 
}

public test bool shouldReturnLevelFiveHierarchyClasses() {
	set[str] checkedExceptions = findCheckedExceptions(javaClassesLocations);
	return "GException" in checkedExceptions && "KException" in checkedExceptions &&
		"NException" in checkedExceptions;
}

public test bool shouldReturnLevelSixHierarchyClasses() {
	set[str] checkedExceptions = findCheckedExceptions(javaClassesLocations);
	return "MException" in checkedExceptions;
}

public test bool shouldNotReturnUncheckedExceptions() {
	set[str] checkedExceptions = findCheckedExceptions(javaClassesLocations);
	return "RuntimeException" notin checkedExceptions && 
		"UncheckedLevelFourRuntimeException" notin checkedExceptions &&
		"UncheckedLevelThreeRuntimeException" notin checkedExceptions &&
		"UncheckedLevelTwoRuntimeException" notin checkedExceptions;
}

public test bool shouldReturnAbstractCheckedException() {
	set[str] checkedExceptions = findCheckedExceptions(javaClassesLocations);
	return "AbstractCheckedException" in checkedExceptions;
}

public test bool shouldReturnStaticInnerCheckedExceptions() {
	set[str] checkedExceptions = findCheckedExceptions(javaClassesLocations);
	return "ExceptionClassWithOnlyZeroArgCtor" in checkedExceptions &&
	 	"CustomServiceLocatorException3" in checkedExceptions &&
		"CustomServiceLocatorException2" in checkedExceptions && 
		"DeepNestedStaticException" in checkedExceptions;
}