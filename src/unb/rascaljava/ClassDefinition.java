package unb.rascaljava;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class ClassDefinition {
	
	private Integer id;
	private String qualifiedName;
	
	private List<ClassDefinition> superClasses = new ArrayList<>();
	private List<String> annotations = new ArrayList<>();
	private boolean isClass;
	
	private List<MethodDefinition> methods = new ArrayList<>();
	private List<FieldDefinition> fields = new ArrayList<>();
	
	public ClassDefinition() {
	}
	
	public ClassDefinition(String qualifiedName) {
		this.qualifiedName = qualifiedName;
	}
	
	@Override
	public String toString() {
		return qualifiedName;
	}
	
	public void addMethodDefinition(String name, String returnType, Map<String, String> args, List<ClassDefinition> exceptions) {
		methods.add(new MethodDefinition(name, returnType, args, exceptions));
	}
	
	public void addFieldDefinition(String name, String type) {
		fields.add(new FieldDefinition(name, type));
	}
	
	public String getQualifiedName() {
		return qualifiedName;
	}

	public void setQualifiedName(String qualifiedName) {
		this.qualifiedName = qualifiedName;
	}

	public List<ClassDefinition> getSuperClasses() {
		return superClasses;
	}

	public void setSuperClasses(List<ClassDefinition> superClasses) {
		this.superClasses = superClasses;
	}
	
	public void addSuperclass(ClassDefinition superClass) {
		this.superClasses.add(superClass);
	}

	public List<MethodDefinition> getMethods() {
		return methods;
	}

	public void setMethods(List<MethodDefinition> methods) {
		this.methods = methods;
	}

	public List<FieldDefinition> getFields() {
		return fields;
	}

	public void setFields(List<FieldDefinition> fields) {
		this.fields = fields;
	}
	
	public List<String> getAnnotations() {
		return annotations;
	}

	public void setAnnotations(List<String> annotations) {
		this.annotations = annotations;
	}

	public boolean isClass() {
		return isClass;
	}

	public void setClass(boolean isClass) {
		this.isClass = isClass;
	}

	public Integer getId() {
		return id;
	}

	public void setId(Integer id) {
		this.id = id;
	}
}