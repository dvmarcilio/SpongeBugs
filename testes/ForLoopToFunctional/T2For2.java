for (Entry<K, V> entry : entrySet) {
        assertTrue(map.containsKey(entry.getKey()));
        assertTrue(map.containsValue(entry.getValue()));
        int expectedHash =
            (entry.getKey() == null ? 0 : entry.getKey().hashCode())
                ^ (entry.getValue() == null ? 0 : entry.getValue().hashCode());
        assertEquals(expectedHash, entry.hashCode());
        expectedEntrySetHash += expectedHash;
      }