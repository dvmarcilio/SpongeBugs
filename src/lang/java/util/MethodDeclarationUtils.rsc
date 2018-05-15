module lang::java::util::MethodDeclarationUtils

import ParseTree;
import lang::java::\syntax::Java18;

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