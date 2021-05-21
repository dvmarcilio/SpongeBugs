# SpongeBugs

Automatically fixing SonarQube and SpotBugs Java rules with source-to-source transformations.

## SonarQube Target Rules

### Bugs

- [Strings and Boxed types should be compared using "equals()"](https://rules.sonarsource.com/java/type/Bug/RSPEC-4973)
- ["BigDecimal(double)" should not be used](https://rules.sonarsource.com/java/type/Bug/RSPEC-2111)

### Code Smells

- [String literals should not be duplicated](https://rules.sonarsource.com/java/type/Code%20Smell/RSPEC-1192)
- [String function use should be optimized for single characters](https://rules.sonarsource.com/java/type/Code%20Smell/RSPEC-3027)
- [Strings should not be concatenated using '+' in a loop](https://rules.sonarsource.com/java/type/Code%20Smell/RSPEC-1643)
- [Parsing should be used to convert "Strings" to primitives](https://rules.sonarsource.com/java/type/Code%20Smell/RSPEC-2130)
- [Strings literals should be placed on the left side when checking for equality](https://rules.sonarsource.com/java/type/Code%20Smell/RSPEC-1132)
- [Constructors should not be used to instantiate "String", "BigInteger", "BigDecimal" and primitive-wrapper classes](https://rules.sonarsource.com/java/type/Code%20Smell/RSPEC-2129)
- ["entrySet()" should be iterated when both the key and value are needed](https://rules.sonarsource.com/java/type/Code%20Smell/RSPEC-2864)
- [Collection.isEmpty() should be used to test for emptiness](https://rules.sonarsource.com/java/type/Code%20Smell/RSPEC-1155)
- ["Collections.EMPTY_LIST", "EMPTY_MAP", and "EMPTY_SET" should not be used](https://rules.sonarsource.com/java/type/Code%20Smell/RSPEC-1596)

## Running

Please download the [runnable.jar](https://github.com/dvmarcilio/SpongeBugs/releases/download/2.0.0-final/spongebugs-runner-2.0.0.jar).

For a quickstart with default settings (all rules and ignoring test files):

```bash
java -jar spongebugs-runner-2.0.0.jar /tmp/project/path/src
```

Please make sure that your java points to a JDK (version >= 8).

You can pass several path arguments to the jar, including directories and .java files. Make sure to provide full paths.

For more advanced settings, such as including/excluding specific rules, or to not ignore test files, refer to [RUNNING.md](RUNNING.md).

## Research paper

SpongeBugs is an outcome of a research paper.

The pre-print is available at <https://dvmarcilio.github.io/papers/jss20-spongebugs.pdf>.

A list of Pull-Requests submitted to open-source projects is available at [EVALUATION.md](EVALUATION.md).

```latex
@article{DBLP:journals/jss/MarcilioFBP20,
  author    = {Diego Marcilio and
               Carlo A. Furia and
               Rodrigo Bonif{\'{a}}cio and
               Gustavo Pinto},
  title     = {SpongeBugs: Automatically generating fix suggestions in response to
               static code analysis warnings},
  journal   = {J. Syst. Softw.},
  volume    = {168},
  pages     = {110671},
  year      = {2020},
  url       = {https://doi.org/10.1016/j.jss.2020.110671},
  doi       = {10.1016/j.jss.2020.110671},
  timestamp = {Thu, 10 Sep 2020 09:33:17 +0200},
  biburl    = {https://dblp.org/rec/journals/jss/MarcilioFBP20.bib},
  bibsource = {dblp computer science bibliography, https://dblp.org}
}
```
