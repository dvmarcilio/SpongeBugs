module refactor::forloop::BreakIntoStatements

import IO;
import List;
import String;
import lang::java::\syntax::Java18;
import ParseTree;

data Stmt = stmt(Tree statement, str stmtType);

public list[Stmt] breakIntoStatements(Statement statement) {
	list[Stmt] stmts = [];
	top-down-break visit(statement) {
		case IfThenStatement ifStmt: {
			stmts += stmt(ifStmt, "IfThenStatement");
		}
		case ExpressionStatement expStmt: {
			stmts += stmt(expStmt, "ExpressionStatement");
		}
		case LocalVariableDeclarationStatement lvdlStmt: {
			stmts += stmt(lvdlStmt, "LocalVariableDeclarationStatement");
		} 
		
		case IfThenElseStatement ifElseStmt: throw "Not Refactoring If/Else for now";
		case ForStatement _: throw "Not Refactoring Inner Loops for now";
		case WhileStatement _: throw "Not Refactoring While Loops inside ForStatement for now";
	}
	return stmts;
}

public void printStmtsBrokenInto(list[Stmt] stmts) {
	for (stmt <- stmts) {
		println("type: <stmt.stmtType>");
		println("stmt: <stmt.statement>");
		println();
	}
}