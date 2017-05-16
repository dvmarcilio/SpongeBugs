{
			if (endpointHandlerMapping == null) {
				return NO_PATHS;
			}
			Set<? extends MvcEndpoint> endpoints = endpointHandlerMapping.getEndpoints();
			Set<String> paths = new LinkedHashSet<>(endpoints.size());
			for (MvcEndpoint endpoint : endpoints) {
				if (isIncluded(endpoint)) {
					String path = endpointHandlerMapping.getPath(endpoint.getPath());
					paths.add(path);
					if (!path.equals("")) {
						paths.add(path + "/**");
						// Add Spring MVC-generated additional paths
						paths.add(path + ".*");
					}
					paths.add(path + "/");
				}
			}
			return paths.toArray(new String[paths.size()]);
		}