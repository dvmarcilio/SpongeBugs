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