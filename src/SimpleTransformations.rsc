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




/*
 * Refactor a while loop over an iterator (previous to Java5) 
 * to an enhanced for loop over a collection. Note, this transformation 
 * is very experimental and several side effects might occur. 
 */ 
CompilationUnit refactorToForEach(CompilationUnit unit) = visit(unit) {
   case (Block)`{ <BlockStatement+ bl1> Iterator <Identifier iter> = <Identifier id>.iterator(); while(<Identifier iter>.hasNext()) { <Identifier t> <Identifier var> = (<Identifier t>)<Identifier iter>.next(); <BlockStatement+ bl3> } <BlockStatement+ bl2>}` 
                         => (Block)`{<BlockStatement+ bl1> for(<Identifier t> <Identifier var> : <Identifier id>) { <BlockStatement+ bl3> } <BlockStatement+ bl2>}`
};

    

/**
 * Refactor a compilation unit to use VarArgs. 
 */
CompilationUnit refactorToVarArgs(CompilationUnit unit) =  visit(unit) {
      case (MethodDeclarator)`<Identifier n>(<VariableModifier* mds> <UnannType t> <Identifier arg>[])` => 
        (MethodDeclarator)`<Identifier n>(<VariableModifier* mds> <UnannType t>... <Identifier arg>)`
        
      case (MethodDeclarator)`<Identifier n>(<{FormalParameter ","}+ pmts>, <VariableModifier* mds> <UnannType t> <Identifier arg>[])` => 
        (MethodDeclarator)`<Identifier n>(<{FormalParameter ","}+ pmts>, <VariableModifier* mds> <UnannType t> ... <Identifier arg>)` 
 
      case (MethodDeclarator)`<Identifier n>(<VariableModifier* mds> <UnannPrimitiveType t>[] <Identifier arg>)` => 
        (MethodDeclarator)`<Identifier n>(<VariableModifier* mds> <UnannType t>... <Identifier arg>)`
  
     case (MethodDeclarator)`<Identifier n>(<VariableModifier* mds> <UnannClassOrInterfaceType t>[] <Identifier arg>)` => 
        (MethodDeclarator)`<Identifier n>(<VariableModifier* mds> <UnannType t>... <Identifier arg>)`
  
     case (MethodDeclarator)`<Identifier n>(<{FormalParameter ","}+ pmts2>, <VariableModifier* mds> <UnannPrimitiveType t>[] <Identifier arg>[])` => 
        (MethodDeclarator)`<Identifier n>(<{FormalParameter ","}+ pmts2>, <VariableModifier* mds> <UnannType t> ... <Identifier arg>)` 
 
 
    case (MethodDeclarator)`<Identifier n>(<{FormalParameter ","}+ pmts3>, <VariableModifier* mds> <UnannClassOrInterfaceType t>[] <Identifier arg>[])` => 
        (MethodDeclarator)`<Identifier n>(<{FormalParameter ","}+ pmts3>, <VariableModifier* mds> <UnannType t> ... <Identifier arg>)` 
 

 };
 

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

