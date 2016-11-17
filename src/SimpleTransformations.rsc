module SimpleTransformations

import lang::java::\syntax::Java18;
import ParseTree; 
import IO;
import Set; 

/**
 * Transform naive if statements. A quite simple transformation based 
 * on the Rascal documentation. 
 */ 
CompilationUnit transformNaiveIfStatement(CompilationUnit unit) = visit(unit) {
       case (Statement) `if (<Expression cond>) { return true; } else { return false; }` =>  
       		(Statement) `return <Expression cond>;`
       case (Statement) `if (<Expression cond>)  return true;  else return false;` =>  
       		(Statement) `return <Expression cond>;`   
};


/**
 * Count the number of class declaration within a compilation unit. 
 * TODO: I'd rather use ConcreteSyntax instead. 
 */
int countClassDeclarations(CompilationUnit unit) {
  int res = 0;
  
  visit(unit) {
    case normalClassDeclaration(_, _, _, _, _, _): { res += 1; }  
  }
  return res; 
}



/**
 * Refactor a compilation unit to use VarArgs. 
 */
CompilationUnit refactorToVarArgs(CompilationUnit unit) =  visit(unit) {
      case (MethodDeclarator)`<Identifier n>(<UnannType t> <Identifier arg>[])` => 
        (MethodDeclarator)`<Identifier n>(<UnannType t>... <Identifier arg>)`
        
      case (MethodDeclarator)`<Identifier n>(<{FormalParameter ","}+ pmts>, <UnannType t> <Identifier arg>[])` => 
        (MethodDeclarator)`<Identifier n>(<{FormalParameter ","}+ pmts>, <UnannType t> ... <Identifier arg>)` 
 };
 

/*
* Refactor an if/else statement to a switch statement
*/
CompilationUnit refactorIfElseStatement(CompilationUnit unit) = top-down-break visit(unit) {
 	case (Statement) `if(<Identifier id>.equals(<StringLiteral lit>)) {<Statement stmt1> } else <Statement stmt2>` => 
 		 (Statement) `switch(<Identifier id>) { case <StringLiteral lit> : { <Statement stmt1> }  <SwitchBlockStatementGroup* stmt3> }` 
 		 when stmt3 := buildSwitchGroups(stmt2, id)
 		 
 	case (Statement) `if(<Identifier id> == <Literal lit>) {<Statement stmt1> } else <Statement stmt2>` => 
 		 (Statement) `switch(<Identifier id>) { case <Literal lit> : { <Statement stmt1> }  <SwitchBlockStatementGroup* stmt3> }` 
 		 when stmt3 := buildSwitchGroups(stmt2, id)
};

SwitchBlockStatementGroups buildSwitchGroups(stmt, id) {
 	switch(stmt) {
	 	/* string.equals("string value") */
	  	case (Statement) `if (<Identifier id>.equals(<StringLiteral lit>)) { <Statement stmt1> } else <Statement stmt2>` : {
	    	stmt3 = buildSwitchGroups(stmt2, id);
	    	return (SwitchBlockStatementGroups) `case <StringLiteral lit> : { <Statement stmt1> break; } <SwitchBlockStatementGroup* stmt3>`;
	  	}
	  	case (Statement) `if (<Identifier id>.equals(<StringLiteral lit>)) <Statement stmt1>` : {
	   		return (SwitchBlockStatementGroups) `case <StringLiteral lit> : { <Statement stmt1> break; }`;
	  	}
	  	
	  	/* literal == literal */ 
	  	case (Statement) `if (<Identifier id> == <Literal lit>) { <Statement stmt1> } else <Statement stmt2>` : {
	    	stmt3 = buildSwitchGroups(stmt2, id);
	    	return (SwitchBlockStatementGroups) `case <Literal lit> : { <Statement stmt1> break; } <SwitchBlockStatementGroup* stmt3>`;
	  	}
	  	case (Statement) `if (<Identifier id> == <Literal lit>) <Statement stmt1>` : {
	   		return (SwitchBlockStatementGroups) `case <Literal lit> : { <Statement stmt1> break; }`;
	  	}
	  	
	  	/* default comparison*/
	  	case (Statement) `<Statement stmt>` : {
	     	return (SwitchBlockStatementGroups) `default : <Statement stmt>` ;
	  	}
  	}
}

// code = parse(#CompilationUnit, |project://rascal-Java8/testes/BasicTest.java|);