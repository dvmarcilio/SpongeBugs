{
    Set<K> keySet = map.keySet();
    Collection<V> valueCollection = map.values();
    Set<Entry<K, V>> entrySet = map.entrySet();

    assertEquals(map.size() == 0, map.isEmpty());
    assertEquals(map.size(), keySet.size());
    assertEquals(keySet.size() == 0, keySet.isEmpty());
    assertEquals(!keySet.isEmpty(), keySet.iterator().hasNext());

    int expectedKeySetHash = 0;
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
    assertEquals(expectedKeySetHash, keySet.hashCode());

    assertEquals(map.size(), valueCollection.size());
    assertEquals(valueCollection.size() == 0, valueCollection.isEmpty());
    assertEquals(!valueCollection.isEmpty(), valueCollection.iterator().hasNext());
    for (V value : valueCollection) {
      assertTrue(map.containsValue(value));
      assertTrue(allowsNullValues || (value != null));
    }

    assertEquals(map.size(), entrySet.size());
    assertEquals(entrySet.size() == 0, entrySet.isEmpty());
    assertEquals(!entrySet.isEmpty(), entrySet.iterator().hasNext());
    assertEntrySetNotContainsString(entrySet);

    boolean supportsValuesHashCode = supportsValuesHashCode(map);
    if (supportsValuesHashCode) {
      int expectedEntrySetHash = 0;
      for (Entry<K, V> entry : entrySet) {
        assertTrue(map.containsKey(entry.getKey()));
        assertTrue(map.containsValue(entry.getValue()));
        int expectedHash =
            (entry.getKey() == null ? 0 : entry.getKey().hashCode())
                ^ (entry.getValue() == null ? 0 : entry.getValue().hashCode());
        assertEquals(expectedHash, entry.hashCode());
        expectedEntrySetHash += expectedHash;
      }
      assertEquals(expectedEntrySetHash, entrySet.hashCode());
      assertTrue(entrySet.containsAll(new HashSet<Entry<K, V>>(entrySet)));
      assertTrue(entrySet.equals(new HashSet<Entry<K, V>>(entrySet)));
    }

    Object[] entrySetToArray1 = entrySet.toArray();
    assertEquals(map.size(), entrySetToArray1.length);
    assertTrue(Arrays.asList(entrySetToArray1).containsAll(entrySet));

    Entry<?, ?>[] entrySetToArray2 = new Entry<?, ?>[map.size() + 2];
    entrySetToArray2[map.size()] = mapEntry("foo", 1);
    assertSame(entrySetToArray2, entrySet.toArray(entrySetToArray2));
    assertNull(entrySetToArray2[map.size()]);
    assertTrue(Arrays.asList(entrySetToArray2).containsAll(entrySet));

    Object[] valuesToArray1 = valueCollection.toArray();
    assertEquals(map.size(), valuesToArray1.length);
    assertTrue(Arrays.asList(valuesToArray1).containsAll(valueCollection));

    Object[] valuesToArray2 = new Object[map.size() + 2];
    valuesToArray2[map.size()] = "foo";
    assertSame(valuesToArray2, valueCollection.toArray(valuesToArray2));
    assertNull(valuesToArray2[map.size()]);
    assertTrue(Arrays.asList(valuesToArray2).containsAll(valueCollection));

    if (supportsValuesHashCode) {
      int expectedHash = 0;
      for (Entry<K, V> entry : entrySet) {
        expectedHash += entry.hashCode();
      }
      assertEquals(expectedHash, map.hashCode());
    }

    assertMoreInvariants(map);
  }