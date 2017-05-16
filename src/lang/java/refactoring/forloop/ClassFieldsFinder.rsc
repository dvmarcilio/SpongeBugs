module lang::java::refactoring::forloop::ClassFieldsFinder

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import Set;
import lang::java::refactoring::forloop::MethodVar;

// M3 isn't very helpful here.
// We can't really get type + var name
public set[MethodVar] findClassFields(CompilationUnit unit) {
	return findCurrentClassFields(unit);
}

private set[MethodVar] findCurrentClassFields(CompilationUnit unit) {
	classFields = {};
	
	// syntax FieldDeclaration = fieldDeclaration: FieldModifier* UnannType VariableDeclaratorList ";"+ ;
	
	visit(unit) {
		case (FieldDeclaration) `<FieldModifier* varMod> <UnannType varType> <VariableDeclaratorList vdl>;`: {
			visit(vdl) {
				case (VariableDeclaratorId) `<Identifier varId> <Dims? dims>`: 
					classFields += createEffectiveFinalVar(figureIfIsFinal(varMod), varId, varType, dims);
			
			}
		}
	}
	
	return classFields;
}

private bool figureIfIsFinal(FieldModifier* varMod) {
	return contains("<varMod>", "final");
}

// Class fields are effectively final for the purpose of ForLoopToFunctional
private MethodVar createEffectiveFinalVar(bool isFinal, Identifier varId, UnannType varType, Dims? dims) {
	name = trim(unparse(varId));
	varTypeStr = trim(unparse(varType));
	dimsStr = trim(unparse(dims));
	
	// Standarizing arrays to have varType ==  <UnannType varType>[] 
	if(dimsStr == "[]")
		varTypeStr += "[]";
	
	bool isParameter = false;
	bool isDeclaredWithinLoop = false;
	bool isEffectiveFinal = true;
	return methodVar(isFinal, name, varTypeStr, isParameter, isDeclaredWithinLoop, isEffectiveFinal);
}

// XXX hard
private set[MethodVar] findInheritedFields() {
	return {};
}

// XXX hard
private set[MethodVar] findImportedFields() {
	return {};
}