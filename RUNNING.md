# Running

Please download the [runnable.jar](https://github.com/dvmarcilio/SpongeBugs/releases/download/1.0.1/spongebugs-runner-20-12-19.jar).

Make sure that your java points to a JDK (version >= 8).

You can pass several path arguments to the jar, including directories and .java files. Make sure to provide full paths.

    java -jar spongebugs-runner-20-12-19.jar /tmp/project/path/src
    
    java -jar spongebugs-runner-20-12-19.jar /tmp/project/path/src/main/java/Main.java --rules=C8,C9 --ignoreTestFiles=false
    
    java -jar spongebugs-runner-20-12-19.jar /tmp/project1/path /tmp/project2/path /tmp/project3/path/src/main/java/Main.java --rules=B1,B2

## Parameters

## Ignoring test files

`--ignoreTestFiles=true` (default)

`--ignoreTestFiles=false`

### Including/excluding rules
You can either include some rules, or exclude rules. You can't have both.

Use `,` as a separator if you want more than one rule, with no spaces in between. 

See the [Rules](#rules) section for more details on each rule.

Running only with rules C1 and C5:

    java -jar spongebugs-runner-20-12-19.jar project/path/src --rules=C1,C5
    
Running all rules expect B1:

    java -jar spongebugs-runner-20-12-19.jar project/path/src --excludeRules=B1

## Rules 

Please note that Rules B2 and C6 were implemented together, therefore if you want to include/exclude one, you impact the other one as well.

| ID   | Description                                   | 
| ---- |-------------------------------------------------------------|
| B1   | [Strings and Boxed types should be compared using "equals()"](https://sonarcloud.io/organizations/spongebugs/rules?open=java%3AS4973&rule_key=java%3AS4973) |
| B2   | ["BigDecimal(double)" should not be used](https://sonarcloud.io/organizations/spongebugs/rules?open=java%3AS2111&rule_key=java%3AS2111) (B2) <br> [Constructors should not be used to instantiate "String", "BigInteger", "BigDecimal" and primitive-wrapper classes](https://sonarcloud.io/organizations/spongebugs/rules?open=java%3AS2129&rule_key=java%3AS2129) (C6) |
| C1   | [String literals should not be duplicated](https://sonarcloud.io/organizations/spongebugs/rules?open=java%3AS1192&rule_key=java%3AS1192)     |
| C2   | [String function use should be optimized for single characters](https://sonarcloud.io/organizations/spongebugs/rules?open=java%3AS3027&rule_key=java%3AS3027) |
| C3   | [Strings should not be concatenated using '+' in a loop](https://sonarcloud.io/organizations/spongebugs/rules?open=java%3AS1643&rule_key=java%3AS1643) |
| C4   | [Parsing should be used to convert "Strings" to primitives](https://sonarcloud.io/organizations/spongebugs/rules?open=java%3AS2130&rule_key=java%3AS2130) |
| C5   | [Strings literals should be placed on the left side when checking for equality](https://sonarcloud.io/organizations/spongebugs/rules?open=java%3AS1132&rule_key=java%3AS1132) |
| C7   | ["entrySet()" should be iterated when both the key and value are needed](https://sonarcloud.io/organizations/spongebugs/rules?open=java%3AS2864&rule_key=java%3AS2864) |
| C8   | [Collection.isEmpty() should be used to test for emptiness](https://sonarcloud.io/organizations/spongebugs/rules?open=java%3AS1155&rule_key=java%3AS1155) |
| C9   | ["Collections.EMPTY_LIST", "EMPTY_MAP", and "EMPTY_SET" should not be used](https://sonarcloud.io/organizations/spongebugs/rules?open=java%3AS1596&rule_key=java%3AS1596) |
