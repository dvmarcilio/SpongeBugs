for (String v : values) {
			String key = keysIt.next();
			Metric<?> value = deserialize(key, v, this.zSetOperations.score(key));
			if (value != null) {
				result.add(value);
			}
		}