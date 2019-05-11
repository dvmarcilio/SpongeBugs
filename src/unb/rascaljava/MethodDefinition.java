package unb.rascaljava;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MethodDefinition {
	private String name;
	private String returnType;
	private List<ClassDefinition> thrownExceptions = new ArrayList<>();
	private Map<String, String> args = new HashMap<>();
	
	public MethodDefinition(String name, String returnType, Map<String, String> args, List<ClassDefinition> exceptions) {
		this.name = name;
		this.returnType = returnType;
		this.args = args;
		this.thrownExceptions = exceptions;
	}
	
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public String getReturnType() {
		return returnType;
	}
	public void setReturnType(String returnType) {
		this.returnType = returnType;
	}
	public Map<String, String> getArgs() {
		return args;
	}
	public void setArgs(Map<String, String> args) {
		this.args = args;
	}

	public List<ClassDefinition> getThrownExceptions() {
		return thrownExceptions;
	}

	public void setThrownExceptions(List<ClassDefinition> thrownExceptions) {
		this.thrownExceptions = thrownExceptions;
	}
	
	
	
}
