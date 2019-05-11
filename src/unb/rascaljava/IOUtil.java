package unb.rascaljava;

import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class IOUtil {
	public static List<File> findAllFiles(String location, String extension) {
  	  List<File> res = new ArrayList<>();
  	  List<File> allFiles = new ArrayList<>(); 
  	  File root = new File(location);
  	  if(root.isDirectory() || (getFileExtension(root).equals("jar")) || (getFileExtension(root).equals("zip"))) {
  	     allFiles.addAll(Arrays.asList(root.listFiles()));
  	  }
  	  else {
  	    allFiles.add(root);
  	  }
  	  
  	  for(File f : allFiles) {
  	    if(f.isDirectory()) {
  	      res.addAll(findAllFiles(f.getPath(), "java"));
  	    }
  	    else {
  	      if(getFileExtension(f).equals(extension)) {
  	         res.add(f);
  	      };
  	    };
  	  };
  	  return res; 
  	}
	
	public static String getFileExtension(File file) {
		String fileName = file.getName();
		if(fileName.lastIndexOf(".") != -1 && fileName.lastIndexOf(".") != 0) {
			return fileName.substring(fileName.lastIndexOf(".")+1);
		} else {
			return "";
		}
	}
}
