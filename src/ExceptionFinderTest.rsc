module ExceptionFinderTest

import lang::java::m3::M3Util;
import IO;
import ExceptionFinder;

private loc zipFile = |jar:///D:/exception-hierarchy.zip!|;
private list[loc] javaClassesLocations = listAllJavaFiles(zipFile);

private set[str] checkedExceptions = findCheckedExceptions(javaClassesLocations);

public test bool shouldReturnExceptionClass() {
	return "Exception" in checkedExceptions;
}

public test bool shouldReturnLevelTwoHierarchyClasses() {
	return "AException" in checkedExceptions && "BException" in checkedExceptions &&
	 	"CException" in checkedExceptions && "ZException" in checkedExceptions;
}

public test bool shouldReturnLevelThreeHierarchyClasses() {
	return "DException" in checkedExceptions && "FException" in checkedExceptions &&
		"IException" in checkedExceptions;
}

public test bool shouldReturnLevelFourHierarchyClasses() {
	return "LException" in checkedExceptions && "EException" in checkedExceptions &&
		"JException" in checkedExceptions && "HException" in checkedExceptions; 
}

public test bool shouldReturnLevelFiveHierarchyClasses() {
	return "GException" in checkedExceptions && "KException" in checkedExceptions &&
		"NException" in checkedExceptions;
}

public test bool shouldReturnLevelSixHierarchyClasses() {
	return "MException" in checkedExceptions;
}

public test bool shouldNotReturnUncheckedExceptions() {
	return "RuntimeException" notin checkedExceptions && 
		"UncheckedLevelFourRuntimeException" notin checkedExceptions &&
		"UncheckedLevelThreeRuntimeException" notin checkedExceptions &&
		"UncheckedLevelTwoRuntimeException" notin checkedExceptions;
}

public test bool shouldReturnAbstractCheckedException() {
	return "AbstractCheckedException" in checkedExceptions;
}