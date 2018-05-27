module lang::java::analysis::DataStructures

import Set;

public data Variable = variable(str varType, str name);

public Variable findVarByName(set[Variable] variables, str name) {
	return getOneFrom({ var | Variable var <- variables, var.name == name });
}