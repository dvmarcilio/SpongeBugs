import java.util.List;

import org.springframework.context.ApplicationContext;
import org.springframework.context.support.ClassPathXmlApplicationContext;

import br.unb.cic.sa.model.Project;
import br.unb.cic.sa.util.CDI;
import br.unb.cic.sa.util.ReadCsv;

public class LambdaSample {
	 
	public static void main(String[] args) {
				
		//String pathCsv = ""; 
			
		if(args.length == 1) {
			System.out.println("Args: "+ args[0].toString());
			pathCsv = args[0];
		}else {
			System.out.println("Error: inform a valid csv file!!!\nEXIT");
			System.exit(0);
		}
		
		ReadCsv rcsv = new ReadCsv(pathCsv);
		
		//List<String> errors = rcsv.getError();
		
		//errors.forEach(e -> System.out.println("Error in "+e));
 
		ApplicationContext ctx = CDI.Instance().getContextCdi(); 
		
		ProjectAnalyser pa = ctx.getBean("pa", ProjectAnalyser.class);
		
		List<String> projects = null; // rcsv.readInput();
		
		try {		
	//		projects.stream().forEach(project -> { pa.analyse(project)});
		}catch(Exception t) {
			t.printStackTrace();
		}
		
//		Count total of lines of code in each project
//		int totalLoc = projects.parallelStream().mapToInt(Project::getLoc).sum();	
//		System.out.println("TotalLoc: "+ totalLoc);
	}
}