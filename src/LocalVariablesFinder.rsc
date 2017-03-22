module LocalVariablesFinder

import Set;
import lang::java::\syntax::Java18;
import String;
import ParseTree;
import IO;

// syntax LocalVariableDeclarationStatement = LocalVariableDeclaration ";"+ ;
// syntax LocalVariableDeclaration = VariableModifier* UnannType VariableDeclaratorList ;
// syntax VariableDeclaratorList = variableDeclaratorList: {VariableDeclarator ","}+ ; 
// syntax VariableDeclarator = variableDeclarator: VariableDeclaratorId ("=" VariableInitializer)? ;

public tuple[set[str] finals, set[str] nonFinals] findLocalVariables(MethodBody methodBody) {
	set[str] finals = {};
	set[str] nonFinals = {};
	visit(methodBody) {
		case (EnhancedForStatement) `for ( final <UnannType _> <VariableDeclaratorId varId> : <Expression _> ) <Statement stmt>`:
			 finals += trim(unparse(varId));
		case (LocalVariableDeclaration) `final <UnannType _> <VariableDeclaratorList vdl>`: {
			visit(vdl) {
				case (VariableDeclaratorId) `<Identifier varId> <Dims? _>`:
					finals += trim(unparse(varId));
			}
		}
		// finding all variables declared, including ones in loop declaration
		case VariableDeclaratorId varId: nonFinals += trim(unparse(varId));	
	}
	// nonFinals must not have finals
	nonFinals -= finals;
	return <finals, nonFinals>;
}