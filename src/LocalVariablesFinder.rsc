module LocalVariablesFinder

import Set;
import lang::java::\syntax::Java18;
import String;
import ParseTree;
import IO;
import MethodVar;

// syntax LocalVariableDeclarationStatement = LocalVariableDeclaration ";"+ ;
// syntax LocalVariableDeclaration = VariableModifier* UnannType VariableDeclaratorList ;
// syntax VariableDeclaratorList = variableDeclaratorList: {VariableDeclarator ","}+ ; 
// syntax VariableDeclarator = variableDeclarator: VariableDeclaratorId ("=" VariableInitializer)? ;

public set[MethodVar] findLocalVariables(MethodBody methodBody) {
	set[MethodVar] methodVars = {};
	visit(methodBody) {

		case (EnhancedForStatement) `for (<VariableModifier* varMod> <UnannType varType> <VariableDeclaratorId varId> : <Expression _> ) <Statement _>`:
			 methodVars += createMethodVar(figureIfIsFinal(varMod), varId, varType);
		
		case (LocalVariableDeclaration) `<VariableModifier* varMod> <UnannType varType> <VariableDeclaratorList vdl>`: {
			visit(vdl) {
				case (VariableDeclaratorId) `<Identifier varId> <Dims? _>`:
					methodVars += createMethodVar(figureIfIsFinal(varMod), varId, varType);
			}
		}
		
		case(CatchFormalParameter) `<VariableModifier* varMod> <CatchType varType> <VariableDeclaratorId varId>`:
			methodVars += createMethodVar(figureIfIsFinal(varMod), varId, varType);	
		
	}
	return methodVars;
}

private MethodVar createMethodVar(bool isFinal, VariableDeclaratorId varId, UnannType varType) {
	name = trim(unparse(varId));
	varTypeStr = trim(unparse(varType));
	return methodVar(isFinal, name, varTypeStr, true);
}

private MethodVar createMethodVar(bool isFinal, Identifier varId, UnannType varType) {
	name = trim(unparse(varId));
	varTypeStr = trim(unparse(varType));
	return methodVar(isFinal, name, varTypeStr, true);
}

private MethodVar createMethodVar(bool isFinal, VariableDeclaratorId varId, CatchType varType) {
	name = trim(unparse(varId));
	varTypeStr = trim(unparse(varType));
	return methodVar(isFinal, name, varTypeStr, true);
}

private bool figureIfIsFinal(VariableModifier* varMod) {
	if ("<varMod>" := "final")
		return true;
	return false;
}