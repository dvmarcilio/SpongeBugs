module lang::java::refactoring::sonar::mutableMembersUsage::\test::MutableMembersUsageTest

import List;
import Set;
import IO;
import lang::java::refactoring::sonar::GettersAndSetters;
import lang::java::refactoring::sonar::mutableMembersUsage::\test::MutableMembersUsageTestResources;
import lang::java::refactoring::sonar::mutableMembersUsage::MutableMembersUsage;

GettersAndSetters gasSimpleViolations = findGettersAndSettersForMutableInstanceVars(simpleViolationsUnit());

public test bool shouldFindAllGettersForMutableInstanceVars() {
	return size(gasSimpleViolations.getters) == 5;
}

public test bool shouldFindAllSettersForMutableInstanceVars() {
	return size(gasSimpleViolations.setters) == 5;
}

public test bool shouldFindListViolations() {
	return false;
}

public test bool shouldFindSetViolations() {
	return false;
}



