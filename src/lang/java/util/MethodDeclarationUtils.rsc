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