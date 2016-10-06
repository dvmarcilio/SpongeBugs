public class TryWithResources {

	static String readFirstLineFromFile(String path) throws IOException {
    	try (BufferedReader br =
                new BufferedReader(new FileReader(path))) {
        	return br.readLine();
    	}
    	finally { } 
	}
}