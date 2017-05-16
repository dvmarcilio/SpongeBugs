@Override
  public ImmutableMap<K, V> getAllPresent(Iterable<?> keys) {
    Map<K, V> result = Maps.newLinkedHashMap();
    for (Object key : keys) {
      if (!result.containsKey(key)) {
        @SuppressWarnings("unchecked")
        K castKey = (K) key;
        V value = getIfPresent(key);
        if (value != null) {
          result.put(castKey, value);
        }
      }
    }
    return ImmutableMap.copyOf(result);
  }