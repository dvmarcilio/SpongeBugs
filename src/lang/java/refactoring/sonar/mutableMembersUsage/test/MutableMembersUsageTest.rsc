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

GettersAndSetters allGaS = findGettersAndSettersForMutableInstanceVars(simpleViolationsUnit());
set[str] gettersNames = { retrieveMethodName(getter) | MethodDeclaration getter <- allGaS.getters };
set[str] settersNames = { retrieveMethodName(setter) | MethodDeclaration setter <- allGaS.setters };

GettersAndSetters violationsGaS = findGettersAndSettersMutableMembersViolations(simpleViolationsUnit());
set[str] violationsGettersNames = { retrieveMethodName(getter) | MethodDeclaration getter <- violationsGaS.getters };
set[str] violationsSettersNames = { retrieveMethodName(setter) | MethodDeclaration setter <- violationsGaS.setters };

public test bool shouldFindAllGettersForMutableInstanceVars() {
	return size(allGaS.getters) == 5 &&
		"getStrs" in gettersNames && 
		"getInts" in gettersNames &&
		"getDate" in gettersNames &&
		"getStrsNonViolation" in gettersNames && 
		"getIntsNonViolation" in gettersNames;
}

public test bool shouldFindAllSettersForMutableInstanceVars() {
	return size(allGaS.setters) == 5 &&
		"setStrs" in settersNames && 
		"setInts" in settersNames &&
		"setDate" in settersNames &&
		"setStrsNonViolation" in settersNames && 
		"setIntsNonViolation" in settersNames;
}

public test bool shouldFindAllGettersViolations() {
	return size(violationsGaS.getters) == 3;
}

public test bool shouldFindAllSettersViolations() {
	return size(violationsGaS.setters) == 3;
}

public test bool shouldFindGetterListViolation() {
	return "getStrs" in violationsGettersNames;
}

public test bool shouldFindSetterListViolation() {
	return "setStrs" in violationsSettersNames;
}

public test bool shouldFindGetterSetViolation() {
	return "getInts" in violationsGettersNames;
}

public test bool shouldFindSetterSetViolation() {
	return "setInts" in violationsSettersNames;
}

public test bool shouldFindGetterDateViolation() {
	return "getDate" in violationsGettersNames;
}

public test bool shouldFindSetterDateViolation() {
	return "setDate" in violationsSettersNames;
}