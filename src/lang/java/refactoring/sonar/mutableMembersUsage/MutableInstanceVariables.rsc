module lang::java::refactoring::sonar::mutableMembersUsage::MutableInstanceVariables

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import List;
import Set;
import lang::java::analysis::DataStructures;

// TODO change when we can check subtype relation realiably
// some of the most used types to get started
private set[str] mutableTypes = {"List", "ArrayList", "LinkedList", "Set", "HashSet", "TreeSet"};

public void findMutableInstanceVariables(list[loc] locs) {
	list[Variable] instanceVars = [];
	for(fileLoc <- locs) {
		javaFileContent = readFile(fileLoc);
		try {
			unit = parse(#CompilationUnit, javaFileContent);
			instanceVars += retrieveMutableInstanceVars(unit);
		} catch:
			continue;
	}
	for (instanceVar <- instanceVars) {
		println(instanceVar.varType + " " + instanceVar.name);
	}
	
}

public set[Variable] retrieveMutableInstanceVars(CompilationUnit unit) {
	set[Variable] instanceVars = {};
	visit(unit) {
		case (FieldDeclaration) `<FieldModifier* varMod> <UnannType varType> <VariableDeclaratorList vdl>;`: {
			if (isInstanceVariable(varMod) && isMutableType(varType)) {
				visit(vdl) {
					case (VariableDeclaratorId) `<Identifier varId> <Dims? dims>`: {
						instanceVars += variable("<varType>", "<varId>");
					}
				}		
			}
		}
	}
	return instanceVars;
}

private bool isInstanceVariable(FieldModifier* varMod) {
	return !contains("<varMod>", "static");
}

// TODO Check if identifier is subtype of known mutable types (Collection, Date, Hashtable)
private bool isMutableType(UnannType varType) {
	visit (varType) {
		case Identifier id: { 
			return "<id>" in mutableTypes;
		} 
	}
	return false;
}

