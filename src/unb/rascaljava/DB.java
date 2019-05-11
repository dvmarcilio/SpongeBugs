package unb.rascaljava;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import io.usethesource.vallang.IString;

public class DB {
	
	private Connection connection;
	private static DB instance = null;
	
	private DB(){
	}
	
	public static DB getInstance() {
      if(instance == null) {
         instance = new DB();
      }
      return instance;
	}
	
	public void setup() {
		try {
			Class.forName("org.h2.Driver");
			connection = DriverManager.
			        getConnection("jdbc:h2:mem:test;DB_CLOSE_DELAY=-1", "", "");
			createClassTable();
			createInheritanceTable();
			createMethodTable();
			createFieldtable();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	private void createFieldtable() throws SQLException {
		PreparedStatement stmt;
		stmt = connection.prepareStatement(
			"CREATE TABLE FIELD_DEFINITION" +
			"(field_id int NOT NULL PRIMARY KEY AUTO_INCREMENT, name VARCHAR(255), type VARCHAR(255)," +
			"class_id int, constraint fk_fieldclass FOREIGN KEY (class_id) REFERENCES CLASS_DEFINITION(class_id))"
		);
		stmt.execute();
	}

	private void createMethodTable() throws SQLException {
		PreparedStatement stmt;
		stmt = connection.prepareStatement(
			"CREATE TABLE METHOD_DEFINITION" +
			"(method_id int NOT NULL PRIMARY KEY AUTO_INCREMENT, name VARCHAR(255), return_type VARCHAR(255), " +
			"class_id int,  CONSTRAINT fk_methodclass FOREIGN KEY (class_id) REFERENCES CLASS_DEFINITION(class_id))"
		);
		stmt.execute();
	}

	private void createInheritanceTable() throws SQLException {
		PreparedStatement stmt;
		stmt = connection.prepareStatement(
				"CREATE TABLE `INHERITANCE` (" + 
				"  `class_id` INT NOT NULL," + 
				"  `superclass_id` INT NOT NULL," + 
				"  PRIMARY KEY (`class_id`, `superclass_id`)," + 
				"  CONSTRAINT `fk_inheritance_class_id`" + 
				"    FOREIGN KEY (`class_id`)" + 
				"    REFERENCES `CLASS_DEFINITION` (`class_id`)," + 
				"  CONSTRAINT `fk_inheritance_superclass_id`" + 
				"    FOREIGN KEY (`superclass_id`)" + 
				"    REFERENCES `CLASS_DEFINITION` (`class_id`)" + 
				"    )"
			);
		stmt.execute();
	}

	private void createClassTable() throws SQLException {
		PreparedStatement stmt = connection.prepareStatement(
			"CREATE TABLE CLASS_DEFINITION" +
			"(class_id int NOT NULL PRIMARY KEY AUTO_INCREMENT, qualified_name VARCHAR(255), method_id int, " +
			"is_class tinyint(1))"
		);
		stmt.execute();
	}
	
	public ClassDefinition saveToDb(ClassDefinition classDef) {
	    try {
	    	int class_id = 0;
	    	PreparedStatement stmt;
	    	class_id = saveClass(classDef);
	    	
			for(FieldDefinition f : classDef.getFields()) {
				stmt = connection.prepareStatement("INSERT INTO FIELD_DEFINITION (name, type, class_id) values(?, ?, ?)");
				stmt.setString(1, f.getName());
				stmt.setString(2, f.getType());
				stmt.setInt(3, class_id);
				stmt.executeUpdate();
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
	    return classDef;
	}

	public int saveClass(ClassDefinition classDef) {
		int class_id = 0;
		try {
			PreparedStatement stmt;
			stmt = connection.prepareStatement("INSERT INTO CLASS_DEFINITION (qualified_name, is_class) values(?,?)");
			stmt.setString(1, classDef.getQualifiedName());
			stmt.setInt(2, classDef.isClass() ? 1 : 0);
			stmt.executeUpdate();
			stmt = connection.prepareStatement("SELECT * FROM CLASS_DEFINITION ORDER BY class_id DESC LIMIT 1 ");
			ResultSet rs = stmt.executeQuery();
			if (rs.next()) {
				class_id = rs.getInt(1);
				classDef.setId(class_id);
			}
			for(ClassDefinition superClassDef : classDef.getSuperClasses()) {
				ClassDefinition superClass = loadSuperClass(superClassDef);
				if(superClass != null) {
					stmt = connection.prepareStatement("INSERT INTO INHERITANCE (class_id, superclass_id) values(?,?)");
					stmt.setInt(1, class_id);
					stmt.setInt(2, superClassDef.getId());
					stmt.executeUpdate();
				}
			}
		} catch(SQLException e) {
			e.printStackTrace();
		}
		return class_id;
	}
	
	public ClassDefinition loadSuperClass(ClassDefinition superClass) {
		if(superClass == null) {
			return null;
		} else if(superClass.getId() == null) {
			return findByQualifiedName(superClass.getQualifiedName());
		} else {
			return superClass;
		}
	}
	

	public ClassDefinition findByQualifiedName(String qualifiedName) {
		PreparedStatement stmt;
		try {
			ClassDefinition classDef = null;
			stmt = connection.prepareStatement("SELECT * FROM CLASS_DEFINITION where qualified_name = ?");
			stmt.setString(1, qualifiedName);
			ResultSet rs = stmt.executeQuery();
			while (rs.next()) {
				classDef = new ClassDefinition();
				classDef.setId(rs.getInt("class_id"));
				classDef.setQualifiedName(rs.getString("qualified_name"));
				classDef.setClass(rs.getInt("is_class") != 0 ? true : false);
			}
			return classDef;
		} catch (SQLException e) {
			e.printStackTrace();
		}
		
		return null;
	}

	public void fetchFromDb() {
		Map<String, Integer> names = new HashMap<>();
		List<ClassDefinition> list = new ArrayList<>();
		try {
			int classId;
			PreparedStatement stmt = connection.prepareStatement("SELECT class_id, qualified_name FROM CLASS_DEFINITION");
			ResultSet rs = stmt.executeQuery();
			while (rs.next()) {
				ClassDefinition def = new ClassDefinition();
				def.setId(rs.getInt("class_id"));
				def.setQualifiedName(rs.getString("qualified_name"));
				list.add(def);
			}
			for(ClassDefinition def : list) {
				stmt = connection.prepareStatement("SELECT superclass_id FROM INHERITANCE where class_id = ?");
				stmt.setInt(1, def.getId());
				rs = stmt.executeQuery();
				while(rs.next()) {
					PreparedStatement stmt2 = connection.prepareStatement("SELECT class_id, qualified_name, is_class FROM CLASS_DEFINITION where class_id = ?");
					stmt2.setInt(1, rs.getInt("superclass_id"));
					ResultSet rs2 = stmt2.executeQuery();
					while(rs2.next()) {
						System.out.println("SUPERCLASSE id: " + rs2.getInt("class_id") + " qualified_name: " + rs2.getString("qualified_name") + "is_class:" + 
							(rs2.getInt("is_class") == 1 ? "classe" : "interface"));
					}
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	public String findQualifiedName(String className) {
		if(className.contains(".")) {
			return className;
		}
		PreparedStatement stmt;
		try {
			stmt = connection.prepareStatement(
				"SELECT * FROM CLASS_DEFINITION WHERE qualified_name like ? "
			);
			stmt.setString(1, "%." + className);
			ResultSet rs = stmt.executeQuery();
			
			if(rs.next()) {
				return rs.getString("qualified_name");
			}
		} catch (SQLException e) {
			e.printStackTrace();
		}
		return null;
	}

	public Connection getConnection() {
		return connection;
	}

	public boolean isPersisted(String qualifiedName) {
		return findByQualifiedName(qualifiedName) != null;
	}

	public List<ClassDefinition> getAllAncestors(String qualifiedName) {
		StringBuilder sb = new StringBuilder();
		sb.append("SELECT a.* from CLASS_DEFINITION a ");
		sb.append("INNER JOIN INHERITANCE b on a.class_id = b.superclass_id ");
		sb.append("INNER JOIN CLASS_DEFINITION c on c.class_id = b.class_id ");
		sb.append("WHERE c.qualified_name = ?");
		try {
			PreparedStatement stmt = connection.prepareStatement(sb.toString());
			stmt.setString(1, qualifiedName);
			ResultSet rs = stmt.executeQuery();
			List<ClassDefinition> ancestors = new ArrayList<>();
			List<ClassDefinition> list = new ArrayList<>();
			boolean goOn = true;
			while(rs.next()) {
				
				ClassDefinition classDef = new ClassDefinition();
				classDef.setId(rs.getInt("class_id"));
				classDef.setQualifiedName(rs.getString("qualified_name"));
				classDef.setClass(rs.getInt("is_class") != 0 ? true : false);
				list.add(classDef);
				ancestors.add(classDef);
				if(classDef.getQualifiedName().equals("java.lang.Object")) {
					goOn = false;
				} 
			}
			if(goOn) {
				 for(ClassDefinition ancestor : list) {
					 ancestors.addAll(getAllAncestors(ancestor.getQualifiedName()));
				 }
				return ancestors;
			} else {
				return ancestors;
			}
		} catch(SQLException e) {
			e.printStackTrace();
		}
		return new ArrayList<>();
		
	}

	public Integer countInserted() {
		try {
			PreparedStatement stmt = connection.prepareStatement("SELECT count(*) from CLASS_DEFINITION");
			ResultSet rs = stmt.executeQuery();
			if (rs.next()) {
				return rs.getInt(1);
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		return 0;
	}

	public FieldDefinition getField(String className, String fieldName) {
		try {
			ClassDefinition classDef = findByQualifiedName(className);
			PreparedStatement stmt = connection.prepareStatement("SELECT * from FIELD_DEFINITION where name = ? and class_id = ?");
			stmt.setString(1, fieldName);
			stmt.setInt(2, classDef.getId());
			ResultSet rs = stmt.executeQuery();
			if (rs.next()) {
				FieldDefinition fieldDef = new FieldDefinition(rs.getString("name"), rs.getString("type"));
				return fieldDef;
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		return null;
	}
	
}
