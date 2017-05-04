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