module SwitchString

import lang::java::\syntax::Java18;
import ParseTree; 
import IO;
import List;


/*
 * Refactor a sequence of 
 *     if(o.equals("val")) { stmts1 } 
 *     else if (o.equals("val2") { stmts2 } 
 *...  else { stmtsn }
 *
 * into a switch case involving strings:
 *
 * switch(o) {
 *   case val1: { stmts1; break; }
 *   case val2: { stmts2; break; } 
 *   ... 
 *   defaul: { stmtsn } 
 * }  
 */

public tuple[int, CompilationUnit] refactorSwitchString(CompilationUnit unit) { 
  int numberOfOccurences = 0;
  CompilationUnit cu = top-down-break visit(unit) {
  
    case (Statement) `if(<Identifier id>.equals(<StringLiteral lit>)) {<Statement stmt1> } else <Statement stmt2>`: {
      numberOfOccurences += 1;
      if (stmt3 := buildSwitchGroups(stmt2, id))
        insert (Statement) `switch(<Identifier id>) { /*switch-string refactor*/ case <StringLiteral lit> : { <Statement stmt1> }  <SwitchBlockStatementGroup* stmt3> }`;
    }

    case (Statement) `if(<Identifier id> == <StringLiteral lit>) {<Statement stmt1> } else <Statement stmt2>`: {
      numberOfOccurences += 1;
      if (stmt3 := buildSwitchGroups(stmt2, id))
        insert (Statement) `switch(<Identifier id>) { /*switch-string refactor*/ case <StringLiteral lit> : { <Statement stmt1> }  <SwitchBlockStatementGroup* stmt3> }`;
    }
    
  };
  println("RESULTADO" + cu); 
  return <numberOfOccurences, cu>;
}
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
