{
		List<HttpMessageConverter<?>> combined = new ArrayList<>();
		List<HttpMessageConverter<?>> processing = new ArrayList<>(converters);
		for (HttpMessageConverter<?> defaultConverter : defaultConverters) {
			Iterator<HttpMessageConverter<?>> iterator = processing.iterator();
			while (iterator.hasNext()) {
				HttpMessageConverter<?> candidate = iterator.next();
				if (isReplacement(defaultConverter, candidate)) {
					combined.add(candidate);
					iterator.remove();
				}
			}
			combined.add(defaultConverter);
			if (defaultConverter instanceof AllEncompassingFormHttpMessageConverter) {
				configurePartConverters(
						(AllEncompassingFormHttpMessageConverter) defaultConverter,
						converters);
			}
		}
		combined.addAll(0, processing);
		return combined;
	}