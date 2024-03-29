# Running

Please download the [runnable.jar](https://github.com/dvmarcilio/SpongeBugs/releases/download/2.0.0-final/spongebugs-runner-2.0.0.jar).

Make sure that your java path points to a JDK (version >= 8).

You can pass several path arguments to the jar, including directories and .java files. Make sure to provide full paths.

    java -jar spongebugs-runner-2.0.0.jar /tmp/project/path/src
    
    java -jar spongebugs-runner-2.0.0.jar /tmp/project/path/src/main/java/Main.java --rules=C8,C9 --ignoreTestFiles=false
    
    java -jar spongebugs-runner-2.0.0.jar /tmp/project1/path /tmp/project2/path /tmp/project3/path/src/main/java/Main.java --rules=B1,B2

## Parameters

### Ignoring test files

`--ignoreTestFiles=true` (default)

`--ignoreTestFiles=false`

### Including/excluding rules

You can either include some rules, or exclude rules. You cannot have both.

Use `,` as a separator if you want more than one rule, with no spaces in between.

See the [Rules](#rules) section for more details on each rule.

Running only with rules C1 and C5:

    java -jar spongebugs-runner-2.0.0.jar project/path/src --rules=C1,C5
  
Running all rules expect B1:

    java -jar spongebugs-runner-2.0.0.jar project/path/src --excludeRules=B1

## Rules

Please note that Rules B2 and C6 were implemented together, therefore if you want to include/exclude one, you impact the other one as well.

| ID   | Description                                   |
| ---- |-------------------------------------------------------------|
| B1   | [Strings and Boxed types should be compared using "equals()"](https://rules.sonarsource.com/java/type/Bug/RSPEC-4973) |
| B2   | ["BigDecimal(double)" should not be used](https://rules.sonarsource.com/java/type/Bug/RSPEC-2111) (B2) <br/> [Constructors should not be used to instantiate "String", "BigInteger", "BigDecimal" and primitive-wrapper classes](https://rules.sonarsource.com/java/type/Code%20Smell/RSPEC-2129) (C6) |
| C1   | [String literals should not be duplicated](https://rules.sonarsource.com/java/type/Code%20Smell/RSPEC-1192)     |
| C2   | [String function use should be optimized for single characters](https://rules.sonarsource.com/java/type/Code%20Smell/RSPEC-3027) |
| C3   | [Strings should not be concatenated using '+' in a loop](https://rules.sonarsource.com/java/type/Code%20Smell/RSPEC-1643) |
| C4   | [Parsing should be used to convert "Strings" to primitives](https://rules.sonarsource.com/java/type/Code%20Smell/RSPEC-2130) |
| C5   | [Strings literals should be placed on the left side when checking for equality](https://rules.sonarsource.com/java/type/Code%20Smell/RSPEC-1132) |
| C7   | ["entrySet()" should be iterated when both the key and value are needed](https://rules.sonarsource.com/java/type/Code%20Smell/RSPEC-2864) |
| C8   | [Collection.isEmpty() should be used to test for emptiness](https://rules.sonarsource.com/java/type/Code%20Smell/RSPEC-1155) |
| C9   | ["Collections.EMPTY_LIST", "EMPTY_MAP", and "EMPTY_SET" should not be used](https://rules.sonarsource.com/java/type/Code%20Smell/RSPEC-1596) |
