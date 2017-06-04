package lang.java.syntax;

abstract class Foo {
	public abstract void foo();
	public void teste() { }
}

interface Blah {
	public void action(int x);
}

interface X {
	public void action1(int val);
	public void action2(int x);
}

class Super {
	protected int x;
	
	Super() {
		x = 10;
	}
}
public class AnonymousInnerClassTeste extends Super {

	private int x = 5; 
	
	public void teste(Blah b) {
		b.action(4);
	}
	
	public void teste2(X x) {
		x.action1(3);
	}
	
	public void teste3(Foo f) {
		f.foo();
	}
	public void main(String args[]) {
		teste(new Blah() {
			public void action(int x) {
				System.out.println(this);
				System.out.println(x + 1);
			}
		});
		
		teste(new Blah() {
			public void action(int x) {
				System.out.println(super.x);
				System.out.println(x);
			}
		});
		
		teste(new Blah() {
			public void action(int x) {
				System.out.println(x);
				action(x);
			}
		});
		
		teste(new Blah() {
			public void action(int x) {
				System.out.println(x);
			}
		});
		
		teste2(new X() {
			public void action1(int val) {
				
			}
			
			public void action2(int x) {
				
			}
		});
		
		teste3(new Foo() {
			public void foo() { }
		});
	}
	

}
