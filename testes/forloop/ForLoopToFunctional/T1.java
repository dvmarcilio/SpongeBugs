{
    checkCanCreate();

    logger.fine(" Testing: " + name);
    logger.fine("Features: " + formatFeatureSet(features));

    FeatureUtil.addImpliedFeatures(features);

    logger.fine("Expanded: " + formatFeatureSet(features));

    // Class parameters must be raw.
    List<Class<? extends AbstractTester>> testers = getTesters();

    TestSuite suite = new TestSuite(name);
    for (Class<? extends AbstractTester> testerClass : testers) {
      final TestSuite testerSuite =
          makeSuiteForTesterClass((Class<? extends AbstractTester<?>>) testerClass);
      if (testerSuite.countTestCases() > 0) {
        suite.addTest(testerSuite);
      }
    }
    return suite;
  }