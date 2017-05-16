module lang::java::refactoring::forloop::BreakIntoStatements

import IO;
import List;
import String;
import lang::java::\syntax::Java18;
import ParseTree;

data Stmt = stmtBrokenInto(Tree statement, str stmtType);

public list[str] breakIntoStatementsAsStringList(str stmt) {
	stmts = breakIntoStatements(stmt);
	return [ "<stmt.statement>" | Stmt stmt <- stmts ];
}

public list[str] breakIntoStatementsAsStringList(Block block) {
	stmts = breakIntoStatements(block);
	return [ "<stmt.statement>" | Stmt stmt <- stmts ];
}

public list[Stmt] breakIntoStatements(str stmt) {
	if(isBlock(stmt))
		return breakIntoStatements(parse(#Block, stmt));
	return breakIntoStatements(parse(#Statement, stmt));
}

public bool isBlock(str stmt) {
	try {
		parse(#Block, stmt);
		return true;
	} catch: return false;
}

public list[Stmt] breakIntoStatements(Block block) {
	list [Stmt] stmts = [];
	top-down-break visit(block) {
		case Statement stmt:
			stmts += breakIntoStatements(stmt);
		case LocalVariableDeclarationStatement lvdlStmt:
			stmts += stmtBrokenInto(lvdlStmt, "LocalVariableDeclarationStatement");
	}
	return stmts;
}

public list[Stmt] breakIntoStatements(Statement statement) {
	list[Stmt] stmts = [];
	top-down-break visit(statement) {
		case IfThenStatement ifStmt: {
			stmts += stmtBrokenInto(ifStmt, "IfThenStatement");
		}
		case ExpressionStatement expStmt: {
			stmts += stmtBrokenInto(expStmt, "ExpressionStatement");
		}
		case LocalVariableDeclarationStatement lvdlStmt: {
			stmts += stmtBrokenInto(lvdlStmt, "LocalVariableDeclarationStatement");
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