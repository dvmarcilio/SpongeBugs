module lang::java::refactoring::sonar::stringLiteralDuplicated::StringLiteralDuplicated

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;

public void stringLiteral(loc fileLoc) {
	javaFileContent = readFile(fileLoc);
	unit = parse(#CompilationUnit, javaFileContent);
	top-down-break visit(unit) {
		case StatementExpression stmt: {
			top-down-break visit(stmt) {
				case StringLiteral strLiteral:{
					 println("STRING LITERAL: " + strLiteral);
					 println();
					 println(stmt);
					 println("--------------");
				}
			}
		}
	}
}