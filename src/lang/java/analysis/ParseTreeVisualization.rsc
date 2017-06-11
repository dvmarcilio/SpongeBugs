module lang::java::analysis::ParseTreeVisualization

import lang::java::\syntax::Java18;
import ParseTree;
import vis::Figure;
import vis::ParseTree;
import vis::Render;

void visualize(Tree t) {
	render(visParsetree(t));
}

