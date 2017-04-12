class SimpleForEach {

	public void test1(List<String> things, PrintWriter writer) {
        for (String thing: things) {
            writer.write(thing);
        }
    }
}