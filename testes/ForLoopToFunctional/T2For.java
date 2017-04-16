for (K key : keySet) {
      V value = map.get(key);
      expectedKeySetHash += key != null ? key.hashCode() : 0;
      assertTrue(map.containsKey(key));
      assertTrue(map.containsValue(value));
      assertTrue(valueCollection.contains(value));
      assertTrue(valueCollection.containsAll(Collections.singleton(value)));
      assertTrue(entrySet.contains(mapEntry(key, value)));
      assertTrue(allowsNullKeys || (key != null));
    }