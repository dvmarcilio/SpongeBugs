module lang::java::refactoring::sonar::mutableMembersUsage::MutableMembersUsage

import IO;
import lang::java::\syntax::Java18;
import lang::java::refactoring::sonar::GettersAndSetters;
import lang::java::refactoring::sonar::mutableMembersUsage::MutableInstanceVariables;
import lang::java::util::MethodDeclarationUtils;
import lang::java::analysis::DataStructures;
import ParseTree;
import String;
import List;
import Set;

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

public GettersAndSetters findGettersAndSettersMutableMembersViolations(CompilationUnit unit, set[Variable] instanceVars) {
	mutableGaS = findGettersAndSettersForMutableInstanceVars(unit, instanceVars);
	violationsGaS = newGettersAndSetters([], []);
	
	violationsGaS.getters = [ getter | getter <- mutableGaS.getters,  isGetterViolation(getter)];
	
	violationsGaS.setters = [ setter | setter <- mutableGaS.setters, isSetterViolation(setter, instanceVars)];
	
	return violationsGaS;
}

public GettersAndSetters findGettersAndSettersForMutableInstanceVars(CompilationUnit unit, set[Variable] instanceVars) {
	gas = retrieveGettersAndSettersFunctional(unit);
	if (emptyGettersAndSetters(gas)) {
		throw "No getters or setters. Analyze next file";	
	}
	
	return filterGettersAndSettersForMutableInstanceVars(gas, instanceVars);
}

private bool emptyGettersAndSetters(GettersAndSetters gas) {
	return isEmpty(gas.getters) && isEmpty(gas.setters);
}

private GettersAndSetters filterGettersAndSettersForMutableInstanceVars(GettersAndSetters gas, set[Variable] instanceVars) {
	GettersAndSetters gasForMutableVars = newGettersAndSetters([], []);
	
	gasForMutableVars.getters = [ getter | getter <- gas.getters,  isGetterOrSetterForMutableVar(getter, instanceVars)];

	gasForMutableVars.setters = [ setter | setter <- gas.setters,  isGetterOrSetterForMutableVar(setter, instanceVars)];
	
	return gasForMutableVars;
}


private bool isGetterOrSetterForMutableVar(MethodDeclaration mdl, set[Variable] instanceVars) {
	instanceVarsNamesLowerCase = [ toLowerCase(instanceVar.name) | Variable instanceVar <- instanceVars ];
	methodName = retrieveMethodName(mdl);
 	int indexAfterPrefix = 3; // prefix is either "set" or "get"
	varName = substring(methodName, indexAfterPrefix);
	return toLowerCase(varName) in instanceVarsNamesLowerCase;
}

private bool isGetterViolation(MethodDeclaration mdl) {
	returnExp = retrieveReturnExpression(mdl);
	top-down-break visit(returnExp) {
		case (MethodInvocation) methodInvocation: {
			return !contains("<methodInvocation>", "Collections.unmodifiable");
		} 
	}
	return true;
}

private bool isSetterViolation(MethodDeclaration mdl, instanceVars) {
	list[Variable] parameters = retrieveMethodParameters(mdl);
	if (size(parameters) != 1) return false;
	
	singleParam = parameters[0];
	assignedFieldName = retrieveAssignedFieldName(mdl);
	assignmentRightHandSide = retrieveAssignmentRightHandSideFromSetter(mdl);
	
	if (isAssignmentInstantiation(assignmentRightHandSide)) {
		visit(assignmentRightHandSide) {
			case (UnqualifiedClassInstanceCreationExpression) `new <Identifier typeInstantiated><TypeArgumentsOrDiamond? _>(<Expression constructorArg>)`: {
				assignedFieldType = stripGenericTypeParameterFromType(getAssignedFieldType(assignedFieldName, instanceVars));
				isCorrectTypeInstantiated = contains("<typeInstantiated>", assignedFieldType);
				isArgumentCopied = constructorArg == singleParam.name;
				
				return isCorrectTypeInstantiated && isArgumentCopied;
			}
		}
	}	
	return true;
}

private bool isAssignmentInstantiation(Expression assignment) {
	return startsWith("<assignment>", "new");
}

private str stripGenericTypeParameterFromType(str varType) {
	indexOfAngleBracket = findFirst(varType, "\<");
	if (indexOfAngleBracket != -1)
		return substring(varType, 0, indexOfAngleBracket);
	else
		return varType;	
}

private str getAssignedFieldType(str fieldName, set[Variable] instanceVars) {
	Variable assignedField = findVarByName(instanceVars, fieldName);
	return assignedField.varType;
}

public void refactorMutableUsageMembersViolations(CompilationUnit unit) {
	instanceVars = retrieveMutableInstanceVars(unit);
	violationsGaS = findGettersAndSettersMutableMembersViolations(unit, instanceVars);
	
}