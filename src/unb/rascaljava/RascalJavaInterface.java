package unb.rascaljava;

import java.io.File;
import java.io.IOException;
import java.sql.Timestamp;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import com.github.javaparser.ast.CompilationUnit;
import com.github.javaparser.symbolsolver.resolution.typesolvers.CombinedTypeSolver;
import com.github.javaparser.symbolsolver.resolution.typesolvers.JarTypeSolver;
import com.github.javaparser.symbolsolver.resolution.typesolvers.JavaParserTypeSolver;
import com.github.javaparser.symbolsolver.resolution.typesolvers.ReflectionTypeSolver;

import io.usethesource.vallang.IString;
import io.usethesource.vallang.IValue;
import io.usethesource.vallang.IValueFactory;

 interface Teste {
	public String ao() throws Exception;
}

public class RascalJavaInterface {
	public IValue initDB(IString projectPath) {
    	return vf.integer(initDB(projectPath.getValue()));
    }
	
	
	private final IValueFactory vf;
	private CompilationUnitProcessor processor;
	private CombinedTypeSolver solver;

    public RascalJavaInterface(IValueFactory vf) {
       this.vf = vf;
    }
    
    
    
    public Integer initDB(String projectPath) {
    	DB.getInstance().setup();
    	populateDb(projectPath);
    	return DB.getInstance().countInserted();
    }
    
    public void populateDb(String projectPath) {
		initTypeSolver(projectPath);
		processor = new CompilationUnitProcessor(solver);
		List<File> result = IOUtil.findAllFiles(projectPath, "java");
		List<CompilationUnit> compiledFiles = result.stream().map(CompilationUnitProcessor::getCompilationUnit).collect(Collectors.toList());
		compiledFiles.forEach((cUnit) -> processor.processCompilationUnit(cUnit));
    }
    
	public CombinedTypeSolver initTypeSolver(String projectPath) {
		solver = new CombinedTypeSolver();
		solver.add(new JavaParserTypeSolver(new File(projectPath)));
		solver.add(new ReflectionTypeSolver());
		String rootPath = copyProjectJars(projectPath);
		if(rootPath != null) {
			List<File> jars = IOUtil.findAllFiles(rootPath + "/dependencies", "jar");
			jars.forEach((jar) -> {
				try {
					solver.add(new JarTypeSolver(jar.getAbsolutePath()));
				} catch (IOException e) {
					e.printStackTrace();
				}
			});	
		}
		return solver;
	}

	public String copyProjectJars(String projectPath) {
		System.out.println("Starting JARs download. at " + new Timestamp(System.currentTimeMillis()));
    	try {
    		File pomFolder = findPomFolder(projectPath, 4);
    		if(pomFolder != null) {
    			ProcessBuilder pb = new ProcessBuilder("/usr/local/bin/mvn","dependency:copy-dependencies", "-DoutputDirectory=dependencies", "-DoverWriteSnapshots=true", "-DoverWriteReleases=false");
        		pb.directory(pomFolder);
        		Process pr = pb.start();
    			pr.waitFor();
    			System.out.println("JARs downloaded successfully at "  + new Timestamp(System.currentTimeMillis()));
    			return pomFolder.getAbsolutePath();
    		}
		} catch (Exception e) {
			e.printStackTrace();
		}
    	return null;
	}
	
	public File findPomFolder(String projectPath, int levelsToSearch) {
		File path = new File(projectPath);
		List<File> files = Arrays.asList(path.getParentFile().listFiles());
		for(File f : files) {
			if(f.getName().contains("pom.xml")) {
				return path.getParentFile();
			}
		}
		if(levelsToSearch == 0) {
			return null;
		} else {
			return findPomFolder(path.getParentFile().getAbsolutePath(), levelsToSearch - 1);
		}
		
	}

	public static void main(String[] args) {
		RascalJavaInterface rascalJavaInterface = new RascalJavaInterface(null);
		rascalJavaInterface.initDB("/Users/uriel/Documents/Projetos/pessoal/rascal/src");
		DB.getInstance().fetchFromDb();
//		System.out.println(rascalJavaInterface.isCollection("main.java.TesteForEach2Funcional", "list"));
	}
		
	public boolean isCollection(String className, String fieldName) {
		String fieldType = getFieldType(className, fieldName);
		if(fieldType.endsWith("[]")) {
			return false; 
		} else {
			return isRelated(fieldType, "java.utiel.Collection");
		}
	}
	
	public String getFieldType(String className, String fieldName) {
		FieldDefinition field = DB.getInstance().getField(className, fieldName);
		Matcher regexMatcher = Pattern.compile("(.*?)<.*>").matcher(field.getType());
		if(regexMatcher.find()) {
			return regexMatcher.group(1);
		} else {
			return field.getType();
		}
	}
	public IValue isRelated(IString clazzA, IString clazzB) {
    	return vf.bool(isRelated(clazzA.getValue(), clazzB.getValue()));
    }

    public boolean isRelated(String clazzA, String clazzB) {
    	String qualifiedClazzA = DB.getInstance().findQualifiedName(clazzA);
    	String qualifiedClazzB = DB.getInstance().findQualifiedName(clazzB);
    	if(qualifiedClazzA.equals(qualifiedClazzB)) {
    		return true;
    	} 
    	List<ClassDefinition> classAAncestors = DB.getInstance().getAllAncestors(qualifiedClazzA);
    	List<ClassDefinition> classBAncestors = DB.getInstance().getAllAncestors(qualifiedClazzB);
    	return classAAncestors.stream().anyMatch((a) -> a.getQualifiedName().equals(qualifiedClazzB)) || 
    			classBAncestors.stream().anyMatch((a) -> a.getQualifiedName().equals(qualifiedClazzA));
    }
}
