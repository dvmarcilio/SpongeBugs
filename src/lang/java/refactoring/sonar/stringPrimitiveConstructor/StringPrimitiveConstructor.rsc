module lang::java::refactoring::sonar::stringPrimitiveConstructor::StringPrimitiveConstructor

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import lang::java::util::CompilationUnitUtils;
import lang::java::analysis::ParseTreeVisualization;
import String;

// TODO: BigInteger, BigDecimal, Byte, Character, Short
private set[str] classesToCheck = {"String", "Long", "Float", "Double", "Integer", "Boolean"};

private data RefactorData = refactorData(str classType, StatementExpression exp, str arg); 

public void refactorStringPrimitiveConstructor(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	unit = parse(#CompilationUnit, javaFileContent);
	
	//visualize(unit);
	
	list[RefactorData] violations = [];
	
	// FIXME: needs to find the entire assignment expression
	// field? local variable?
	// RefactorData.exp probably won't be an AssignmentExpression
	// AssignmentExpression works fine for 'new String()';
	visit(unit) {
		case (ClassInstanceCreationExpression) `<UnqualifiedClassInstanceCreationExpression instantiationExp>`: {
			visit(instantiationExp) {
				case (UnqualifiedClassInstanceCreationExpression) `new <Identifier typeInstantiated><TypeArgumentsOrDiamond? _>(<ArgumentList? arguments>)`: {
					str classType = "<typeInstantiated>";
					str args = "<arguments>";
					if (isViolation(classType, args)) {
						StatementExpression exp = parse(#StatementExpression, "<instantiationExp>");
						violations += refactorData(classType, exp, args);
					}
				}
			}
		}
	}
	
	refactorViolations(unit, violations);
	
	
}

private bool isViolation(str typeInstantiated, str args) {
	println(args);
	if (typeInstantiated in classesToCheck) {
		if (typeInstantiated == "String") {
			return isEmpty(args) || isOnlyOneArgument(args); 
		} else {
			// maybe redundant since wrapper classes only have constructors with one argument
			// code wouldn´t compile at all
			return isOnlyOneArgument(args);
		}
	}
	return false;
}

private bool isOnlyOneArgument(str args) {
	if(!isEmpty(args)) {
		return !contains(args, ",");
	}
	return false;
}

private CompilationUnit refactorViolations(CompilationUnit unit, list[RefactorData] violations) {
	violationsExps = { exp | StatementExpression exp <- [ r.exp | RefactorData r <- violations ]};
	println(["<e>" | e <- violationsExps]);
}

private StatementExpression refactorViolation(RefactorData violation) {
	if(violation.classType == "String") {
		return refactorStringViolation(violation);
	} else {
		// TODO
		return violation.exp;
	}
}

private StatementExpression refactorStringViolation(RefactorData violation) {
	str arg = violation.arg;
	if(isEmpty(arg)) {
		arg = "\"\"";
	}
	leftSide = retrieveAssignmentLeftHandSide("<violation.exp>");
	refactoredInstatiation = "<leftSide> <arg>";
	return parse(#StatementExpression, refactoredInstatiaton);
}

private str retrieveAssignmentLeftHandSide(str exp) {
	indexAfterAssignment = findFirst("=");
	return  substring("<violation.exp>", 0, indexAfterAssignment + 1);
}