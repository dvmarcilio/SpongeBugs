import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;

public class BasicTest
{
	public int test(int a, int b, int c[]){
		return a + b;
	}

	public void whileStatements(){
		Collection<String> list = new ArrayList();
        
		list.add("a");
		list.add("b");
		list.add("c");
		list.add("d");
		
		Iterator<String> iterator = list.iterator();
		
        while (iterator.hasNext()) {
        	String value = (String)iterator.next();
			System.out.println(value);
		}
        
        int x = 0;
		while (x > 0){
			System.out.println(true);
		}
	}
	
	public boolean conditional(int value){
		if (value > 0){
			return true;
		}
		else{
			return false;
		}
	}
}