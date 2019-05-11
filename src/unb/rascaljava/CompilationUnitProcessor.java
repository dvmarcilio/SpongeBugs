package unb.rascaljava;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import com.github.javaparser.JavaParser;
import com.github.javaparser.ast.CompilationUnit;
import com.github.javaparser.ast.body.ClassOrInterfaceDeclaration;
import com.github.javaparser.resolution.declarations.ResolvedReferenceTypeDeclaration;
import com.github.javaparser.resolution.types.ResolvedReferenceType;
import com.github.javaparser.symbolsolver.resolution.typesolvers.CombinedTypeSolver;

public class CompilationUnitProcessor {

	private DB dbConnection;
	
	private CombinedTypeSolver solver;
	
	public CompilationUnitProcessor(CombinedTypeSolver solver) {
		dbConnection = DB.getInstance();
		this.solver =  solver;
	}

	public void processCompilationUnit(CompilationUnit compilationUnit) {
		try {
			List<ClassOrInterfaceDeclaration> classDefs = compilationUnit.findAll(ClassOrInterfaceDeclaration.class);
			for(ClassOrInterfaceDeclaration def : classDefs) {
				processClass(solver.solveType(getPackage(compilationUnit) + "." + def.getName()));
			}
			
		} catch(RuntimeException e){
//			System.out.println(compilationUnit);
			e.printStackTrace();
		}
		
	}

	
	public ClassDefinition processClass(ResolvedReferenceTypeDeclaration classDec) {
		if(dbConnection.findByQualifiedName(classDec.getQualifiedName()) == null) {
			ClassDefinition classDef = processClassInformation(classDec);
			classDef.setMethods(processMethodsInformation(classDec));
			classDef.setFields(processFieldsInformation(classDec));
			dbConnection.saveToDb(classDef);
			return classDef;
		}
		return null;
	}

	public ClassDefinition processClassInformation(ResolvedReferenceTypeDeclaration clazz) {
		ClassDefinition classDef = new ClassDefinition();
		classDef.setQualifiedName(clazz.getQualifiedName());
		classDef.setClass(clazz.isClass());
		List<ResolvedReferenceType> superClasses = clazz
				.getAncestors()
				.stream()
				.collect(Collectors.toList());
		
		for(ResolvedReferenceType superClass : superClasses) {
			if(superClass != null) {
				ClassDefinition superClassDef = dbConnection.findByQualifiedName(superClass.getQualifiedName());
				if(superClassDef != null) {
					classDef.addSuperclass(superClassDef);
				} else {
					classDef.addSuperclass(processClass(superClass.getTypeDeclaration()));
				}
			}
		}
		
		return classDef;
	}

	public List<MethodDefinition> processMethodsInformation(ResolvedReferenceTypeDeclaration clazz) {
//		clazz.getAllMethods()
//			.stream()
//			.map(m -> {
//				m.typeParametersMap()
//				Map<String, String> args = m.getParameters().stream().collect(Collectors.toMap((p) -> p.getNameAsString(), (p) -> p.getType().toString()));
//			})
//			.collect(Collectors.toList());
//		compilationUnit.findAll(MethodDeclaration.class).forEach((m) -> {
//			classDef.addMethodDefinition(m.getNameAsString(), m.getType().toString(), args, exceptions );
//		});
		return new ArrayList<>();
	}
	
	public List<FieldDefinition> processFieldsInformation(ResolvedReferenceTypeDeclaration clazz) {
		return clazz.getAllFields().stream().map((f) -> new FieldDefinition(f.getName(), f.getType().describe())).collect(Collectors.toList());
	}

	public String getPackage(CompilationUnit compilationUnit) {
		return compilationUnit.getPackageDeclaration().get().getNameAsString();
	}

	public static CompilationUnit getCompilationUnit(File file) {
		try {
			return JavaParser.parse(new FileInputStream(file));
		} catch (Exception e) {
			System.out.println("erro no arquivo: " + file.getPath());
			e.printStackTrace();
			return null;
		}
	}
}
