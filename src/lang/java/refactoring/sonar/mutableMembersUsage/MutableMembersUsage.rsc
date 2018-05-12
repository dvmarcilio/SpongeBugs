module lang::java::refactoring::sonar::mutableMembersUsage::MutableMembersUsage

import IO;
import lang::java::\syntax::Java18;
import ParseTree;
import String;
import Set;

// TODO change when we can check subtype relation realiably
// some of the most used types to get started
private set[str] mutableTypes = {"List", "ArrayList", "LinkedList", "Set", "HashSet", "Map", "HashMap", "Date"};

public data InstanceVar = newInstanceVar(str name, str varType);

public void findMutableInstanceVariables(list[loc] locs) {
	for(fileLoc <- locs) {
		javaFileContent = readFile(fileLoc);
		try {
			unit = parse(#CompilationUnit, javaFileContent);
			instanceVars = retrieveMutableInstanceVars(unit);
		} catch:
			continue;
	}
	
	
}

public tuple[int occurrences, str fullyQualifiedClass] refactor(CompilationUnit unit) {
	mutableInstanceVars = retrieveMutableInstanceVars(unit);
	
}

public list[InstanceVar] retrieveMutableInstanceVars(CompilationUnit unit) {
	list[InstanceVar] instanceVars = [];
	visit(unit) {
		case (FieldDeclaration) `<FieldModifier* varMod> <UnannType varType> <VariableDeclaratorList vdl>;`: {
			if (isInstanceVariable(varMod) && isMutableType(varType)) {
				println("both conditions true");
				visit(vdl) {
					case (VariableDeclaratorId) `<Identifier varId> <Dims? dims>`: {
						instanceVars += newInstanceVar(varId, varType);
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

