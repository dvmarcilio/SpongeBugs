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

private data RefactorData = refactorData(str method, str newType);

private str listMethod = "Collections.unmodifiableList";
private str setMethod = "Collections.unmodifiableSet";
private str treeSetMethod = "Collections.unmodifiableSortedSet";

private map[str, RefactorData] typeToRefactorData = (
	"List": refactorData(listMethod, "ArrayList"),
	"ArrayList": refactorData(listMethod, "ArrayList"),
	"LinkedList": refactorData(listMethod, "LinkedList"),
	"Set": refactorData(setMethod, "HashSet"),
	"HashSet": refactorData(setMethod, "HashSet"),
	"TreeSet": refactorData(treeSetMethod, "TreeSet")
);

private bool refactoredGetters = false;

private str importForGetters = "java.util.Collections";

private set[str] usedTypesForSetters = {};

private map[str, str] importForSetterType = (
	"ArrayList": "java.util.ArrayList",
	"LinkedList": "java.util.LinkedList",
	"HashSet": "java.util.HashSet",
	"TreeSet": "java.util.TreeSet"
);

public void refactorMutableGettersAndSettersViolationsForEachLoc(list[loc] locs) {
	for(fileLoc <- locs) {
		try {
			refactorMutableGettersAndSettersViolations(fileLoc);
		} catch:
			continue;
	}
}

public void refactorMutableGettersAndSettersViolations(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	unit = parse(#CompilationUnit, javaFileContent);
	refactoredUnit = refactorMutableUsageMembersViolations(unit);
	writeFile(fileLoc, refactoredUnit);	
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
				assignedFieldType = stripGenericTypeParameterFromType(getFieldType(assignedFieldName, instanceVars));
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

private str getFieldType(str fieldName, set[Variable] instanceVars) {
	Variable field = findVarByName(instanceVars, fieldName);
	return field.varType;
}

public CompilationUnit refactorMutableUsageMembersViolations(CompilationUnit unit) {
	instanceVars = retrieveMutableInstanceVars(unit);
	violationsGaS = findGettersAndSettersMutableMembersViolations(unit, instanceVars);
	
	unit = refactorMethod(unit, violationsGaS.getters, instanceVars, refactorGetter);
	unit = refactorMethod(unit, violationsGaS.setters, instanceVars, refactorSetter);	
	
	return unit; 
}

private MethodDeclaration refactorGetter(MethodDeclaration mdl, set[Variable] instanceVars) {
	MethodDeclaration refactoredMdl = visit(mdl) {
		case (ReturnStatement) `return <Expression fieldName>;`: {
			
			Expression refactoredReturnExpression = visit(fieldName) {
				case Expression exp: {
					returnedFieldType = stripGenericTypeParameterFromType(getFieldType("<fieldName>", instanceVars));
					rData = typeToRefactorData[returnedFieldType];
					method = rData.method;
					insert(parse(#Expression, "<method>(<fieldName>)"));
				}				
			};
		
			insert((ReturnStatement) `return <Expression refactoredReturnExpression>;`); 
		}	
	};
	return refactoredMdl;
}

private MethodDeclaration refactorSetter(MethodDeclaration mdl, set[Variable] instanceVars) {
	Variable parameter = retrieveMethodParameters(mdl)[0];
	assignedFieldName = retrieveAssignedFieldName(mdl);
	
	MethodDeclaration refactoredMdl = visit(mdl) {
		case (Assignment) `this.<Identifier fieldName> = <Expression rhsAssignment>`: {
			Expression rhsRefactored = visit(rhsAssignment) {
				case Expression rhs: {
					settedFieldType = stripGenericTypeParameterFromType(getFieldType("<fieldName>", instanceVars));
					rData = typeToRefactorData[settedFieldType];
					newType = rData.newType;
					insert(parse(#Expression, "new <newType>\<\>(<fieldName>)"));
				}
			};
			
			insert((Assignment) `this.<Identifier fieldName> = <Expression rhsRefactored>`);	
		}		
	};
	
	return refactoredMdl;
}

private CompilationUnit refactorMethod(CompilationUnit unit, list[MethodDeclaration] methods, set[Variable] instanceVars, refactorFunction) {
	for(method <- methods) {
		unit = visit(unit) {
			case MethodDeclaration mdl: {
				if (mdl == method) {
					refactored = refactorFunction(method, instanceVars);
					insert (MethodDeclaration) `<MethodDeclaration refactored>`;
				}
			}
		};
	}
	return unit;
}