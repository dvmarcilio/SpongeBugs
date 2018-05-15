module lang::java::refactoring::sonar::mutableMembersUsage::\test::MutableMembersUsageTest

import lang::java::\syntax::Java18;
import lang::java::util::MethodDeclarationUtils;
import List;
import Set;
import IO;
import lang::java::refactoring::sonar::GettersAndSetters;
import lang::java::refactoring::sonar::mutableMembersUsage::\test::MutableMembersUsageTestResources;
import lang::java::refactoring::sonar::mutableMembersUsage::MutableMembersUsage;
import lang::java::util::MethodDeclarationUtils;

GettersAndSetters gasSimpleViolations = findGettersAndSettersForMutableInstanceVars(simpleViolationsUnit());
set[str] gettersNames = { retrieveMethodName(getter) | MethodDeclaration getter <- gasSimpleViolations.getters };
set[str] settersNames = { retrieveMethodName(setter) | MethodDeclaration setter <- gasSimpleViolations.setters };

public test bool shouldFindAllGettersForMutableInstanceVars() {
	return size(gasSimpleViolations.getters) == 5 &&
		"getStrs" in gettersNames && 
		"getInts" in gettersNames &&
		"getDate" in gettersNames &&
		"getStrsNonViolation" in gettersNames && 
		"getIntsNonViolation" in gettersNames;
}

public test bool shouldFindAllSettersForMutableInstanceVars() {
	return size(gasSimpleViolations.setters) == 5 &&
		"setStrs" in settersNames && 
		"setInts" in settersNames &&
		"setDate" in settersNames &&
		"setStrsNonViolation" in settersNames && 
		"setIntsNonViolation" in settersNames;;
}

public test bool shouldFindListViolations() {
	return false;
}

public test bool shouldFindSetViolations() {
	return false;
}



