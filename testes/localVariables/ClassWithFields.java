import java.util.ArrayList;
import java.util.List;

public class ClassWithFields {

	public static final String NAME = "Classe";

	private static final int NUMBERS_SIZE = 10;

	private String name;

	private List<Integer> numbers = new ArrayList<>(NUMBERS_SIZE);

	private Object[] objArray;

	private Object objArray2[];

}