interface DefaultMethod {
	
	public int foo();
	
	default int blah() {
		return 3;
	}
	
}