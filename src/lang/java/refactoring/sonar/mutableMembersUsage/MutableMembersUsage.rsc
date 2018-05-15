module lang::java::refactoring::sonar::mutableMembersUsage::MutableMembersUsage

import IO;
import lang::java::refactoring::sonar::GettersAndSetters;
import lang::java::refactoring::sonar::mutableMembersUsage::MutableInstanceVariables;
import ParseTree;
import lang::java::util::MethodDeclarationUtils;
import lang::java::\syntax::Java18;
import String;
import List;
import Set;

private int indexAfterPrefix = 3;

public void findMutableGettersAndSettersForEachLoc(list[loc] locs) {
	for(fileLoc <- locs) {
		javaFileContent = readFile(fileLoc);
		try {
			unit = parse(#CompilationUnit, javaFileContent);
			gas = findGettersAndSettersForMutableInstanceVars(unit);
			//if (!emptyGettersAndSetters(gas)) {
			//	println(fileLoc);
			//	println();
			//	printGettersAndSetters(gas);
			//	println("\n*********************\n");
			//}
		} catch:
			continue;
	}
}

public GettersAndSetters findGettersAndSettersForMutableInstanceVars(CompilationUnit unit) {
	gas = retrieveGettersAndSettersFunctional(unit);
	if (emptyGettersAndSetters(gas)) {
		throw "No getters or setters. Analyze next file";	
	}
	
	instanceVars = retrieveMutableInstanceVars(unit);
	return filterGettersAndSettersForMutableInstanceVars(gas, instanceVars);
}

private bool emptyGettersAndSetters(GettersAndSetters gas) {
	return isEmpty(gas.getters) && isEmpty(gas.setters);
}

public GettersAndSetters filterGettersAndSettersForMutableInstanceVars(GettersAndSetters gas, set[InstanceVar] instanceVars) {
	GettersAndSetters gasForMutableVars = newGettersAndSetters([], []);
	
	gasForMutableVars.getters = [ getter | getter <- gas.getters,  isGetterOrSetterForMutableVar(getter, instanceVars)];

	gasForMutableVars.setters = [ setter | setter <- gas.setters,  isGetterOrSetterForMutableVar(setter, instanceVars)];
	
	return gasForMutableVars;
}


private bool isGetterOrSetterForMutableVar(MethodDeclaration mdl, set[InstanceVar] instanceVars) {
	instanceVarsNamesLowerCase = [ toLowerCase(instanceVar.name) | InstanceVar instanceVar <- instanceVars ];
	methodName = retrieveMethodName(mdl);
	varName = substring(methodName, indexAfterPrefix);
	return toLowerCase(varName) in instanceVarsNamesLowerCase;
}