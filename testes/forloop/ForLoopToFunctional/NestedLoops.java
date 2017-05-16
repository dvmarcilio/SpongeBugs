{
    List<Integer> colorElem = asList(0x00, 0x33, 0x66, 0x99, 0xCC, 0xFF);
    // javac won't compile this without "this.<Integer>"
    ImmutableSet.Builder<Integer> webSafeColorsBuilder
        = this.<Integer>builder();
    for (Integer red : colorElem) {
      for (Integer green : colorElem) {
        for (Integer blue : colorElem) {
          webSafeColorsBuilder.add((red << 16) + (green << 8) + blue);
        }
      }
    }
    ImmutableSet<Integer> webSafeColors = webSafeColorsBuilder.build();
    assertEquals(216, webSafeColors.size());
    Integer[] webSafeColorArray =
        webSafeColors.toArray(new Integer[webSafeColors.size()]);
    assertEquals(0x000000, (int) webSafeColorArray[0]);
    assertEquals(0x000033, (int) webSafeColorArray[1]);
    assertEquals(0x000066, (int) webSafeColorArray[2]);
    assertEquals(0x003300, (int) webSafeColorArray[6]);
    assertEquals(0x330000, (int) webSafeColorArray[36]);
    ImmutableSet<Integer> addedColor
        = webSafeColorsBuilder.add(LAST_COLOR_ADDED).build();
    assertEquals(
        "Modifying the builder should not have changed any already built sets",
        216, webSafeColors.size());
    assertEquals("the new array should be one bigger than webSafeColors",
        217, addedColor.size());
    Integer[] appendColorArray =
        addedColor.toArray(new Integer[addedColor.size()]);
    assertEquals(
        getComplexBuilderSetLastElement(), (int) appendColorArray[216]);
  }