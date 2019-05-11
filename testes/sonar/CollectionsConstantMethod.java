public Set getParents() {
	if (parentSet != null)
		return parentSet;
	if (parent != null)
		return Collections.singleton(parent);
	return Collections.EMPTY_SET;
}