import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class SimpleViolations {

	private String name;

	private Integer age;

	private List<String> strs = new ArrayList<>();

	private Set<Integer> ints = new HashSet<>();

	private Date date = new Date();

	private List<String> strsNonViolation = new ArrayList<>();

	private Set<Integer> intsNonViolation = new HashSet<>();

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public Integer getAge() {
		return age;
	}

	public void setAge(Integer age) {
		this.age = age;
	}

	public List<String> getStrs() {
		return strs;
	}

	public void setStrs(List<String> strs) {
		this.strs = strs;
	}

	public Set<Integer> getInts() {
		return ints;
	}

	public void setInts(Set<Integer> ints) {
		this.ints = ints;
	}

	public Date getDate() {
		return date;
	}

	public void setDate(Date date) {
		this.date = date;
	}

	public List<String> getStrsNonViolation() {
		return Collections.unmodifiableList(strsNonViolation);
	}

	public void setStrsNonViolation(List<String> strsNonViolation) {
		this.strsNonViolation = new ArrayList<>(strsNonViolation);
	}

	public Set<Integer> getIntsNonViolation() {
		return Collections.unmodifiableSet(intsNonViolation);
	}

	public void setIntsNonViolation(Set<Integer> intsNonViolation) {
		this.intsNonViolation = new HashSet<>(intsNonViolation);
	}
}