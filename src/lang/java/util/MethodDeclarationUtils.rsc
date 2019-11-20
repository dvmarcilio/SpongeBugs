module lang::java::util::MethodDeclarationUtils

import ParseTree;
import lang::java::\syntax::Java18;
import lang::java::analysis::DataStructures;

public str retrieveMethodName(MethodDeclaration mdl) {
	visit(mdl) {
		case MethodDeclarator mDeclarator: {
			visit(mDeclarator) {
				case Identifier methodName: 
					return "<methodName>";
			}
		}
	}
	throw "No method name could be found";
}

public Expression retrieveReturnExpression(MethodDeclaration mdl) {
	visit(mdl) {	
		case (ReturnStatement) `return <Expression returnExp>;`: {
			return returnExp;
		}			
	}
	throw "No ReturnStatement could be found";
}

public str retrieveReturnExpressionAsStr(MethodDeclaration mdl) {
	return unparse(retrieveReturnExpression(mdl));
}

public Assignment retrieveSetterAssignment(MethodDeclaration mdl) {
	visit(mdl) {
		case Assignment assignment:
			return assignment;
	}
	throw "No assignment found in setter method";
}

public str retrieveAssignedFieldName(MethodDeclaration mdl) {
	visit(mdl) {
		case (Assignment) `this.<Identifier fieldName> = <Expression _>`: return "<fieldName>";
	}
	throw "No assignment found in setter method";
}

public Expression retrieveAssignmentRightHandSideFromSetter(MethodDeclaration mdl) {
	return retrieveRightHandSideFromSetterAssignment(retrieveSetterAssignment(mdl));
}

public Expression retrieveRightHandSideFromSetterAssignment(Assignment assignment) {
	visit(assignment) {
		case (Assignment) `this.<Identifier _> = <Expression rightHandSideAssignment>`:
			return rightHandSideAssignment;
	}
}

public list[Variable] retrieveMethodParameters(MethodDeclaration mdl) {
	list[Variable] parameters = [];
	visit(mdl) {
		case (FormalParameter) `<VariableModifier* varMod> <UnannType varType> <VariableDeclaratorId varId>`:
			parameters += variable("<varType>", "<varId>");
	}
	return parameters;
}

public str retrieveMethodReturnTypeAsStr(MethodDeclaration mdl) {
	return unparse(retrieveResultFromMethod(mdl));
}

public Result retrieveResultFromMethod(MethodDeclaration mdl) {
	visit(mdl) {
		case (Result) `<Result result>`: return result;
	}
}

public str retrieveMethodSignature(MethodDeclaration mdl) {
	visit(mdl) {
		case (MethodDeclarator) `<MethodDeclarator mDecl>`: {
			return "<mDecl>";
		}
	}
	throw "No MethodDeclarator found in MethodDeclaration";
}
