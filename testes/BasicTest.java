import java.util.ArrayList;


import java.util.*;

import com.sun.corba.se.impl.presentation.rmi.ExceptionHandlerImpl.ExceptionRWRMIImpl;

import java.io.IOException;
import java.lang.Exception;
public class BasicTest {
	public int test(int a, int b, int c[]) {
		return a + b;
	}
	List<String> list1 = new ArrayList();
	List<String> list2 = new ArrayList<>();
	Map<String, List<String>> myMap = new HashMap();
	Map<String, List<String>> myMap2 = new HashMap<String, List<String>>();
	public static void whileWithIteratorStatement() {
		Collection<String> list = new ArrayList<String>();

		list.add("a");
		list.add("b");
		list.add("c");
		list.add("d");

		Iterator<String> iterator = list.iterator();

		while (iterator.hasNext()) {
			String value = (String) iterator.next();
			System.out.println(value);
		}
		
		for(int s : list) { if(s.length()) { return true; }
		} return false;
		
		//for(int s: list) { if(s.lenght()) { return true; } } 
	}

	public static void ifElseStatement(String string, int number, boolean bool) {
		/* Example I */
		if (string.equals("boo")) {
			System.out.println("is a boo");
		} else if (string.equals("blah")) {
			System.out.println("is a blah");
		} else if (string.equals("foo")) {
			System.out.println("is a foo");
		} else {
			System.out.print("is an else");
		}

		/* Example II */
		if (string == "boo") {
			System.out.println("is a boo");
		} else {
			System.out.print("is an else");
		}

		/* Example III */
		if (number == 0) {
			System.out.println("is a number 0");
		} else if (number == 1) {
			System.out.println("is a number 1");
		} else if (number == 2) {
			System.out.println("is a number 2");
		} else {
			System.out.println("is a number " + number);
		}

		/* Example IV */
		if (number == 0) {
			System.out.println("is a number 0");
		} else {
			System.out.println("is a number " + number);
		}
		
		/* Example VI */
		if (bool) {
			System.out.println("is true");
		} else {
			System.out.println("is false");
		}
	}

	public static void switchCaseStatement(String string) {
		switch (string) {
			case "boo":
				System.out.println("is a boo");
				break;
			case "blah":
				System.out.println("is a blah");
				break;
			case "foo":
				System.out.println("is a foo");
				break;
			default:
				System.out.print("is a default");
				break;
		}

		switch (string) {
			case "boo":
				System.out.println("is a boo");
				break;
			default:
				System.out.print("is a default");
				break;
		}
	}

	public boolean simpleIfElse(int value) {
		if (value > 0) {
			return true;
		} else {
			return false;
		}
	}
	
	public void testMulticatch()
	{
		try{
			int x =0;
		}
		catch(ExceptionInInitializerError e){
			System.out.println(e);
		}
		catch(ExceptionRWRMIImpl e){
			System.out.println(e);
		}
		catch(IOException e) {
			e.printStackTrace();
		}
	}
}