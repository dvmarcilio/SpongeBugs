{

		// This set is sorted
		Set<String> keys = this.zSetOperations.range(0, -1);
		Iterator<String> keysIt = keys.iterator();

		List<Metric<?>> result = new ArrayList<>(keys.size());
		List<String> values = this.redisOperations.opsForValue().multiGet(keys);
		for (String v : values) {
			String key = keysIt.next();
			Metric<?> value = deserialize(key, v, this.zSetOperations.score(key));
			if (value != null) {
				result.add(value);
			}
		}
		return result;

	}