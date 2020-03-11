# SpongeBugs

Automatically fixing SonarQube and SpotBugs Java rules with source-to-source transformations.

```
@INPROCEEDINGS{Marcilio:SCAM:2019,
author={Diego {Marcilio} and Carlo A. {Furia} and Rodrigo {Bonifácio} and Gustavo {Pinto}},
booktitle={2019 19th International Working Conference on Source Code Analysis and Manipulation (SCAM)},
title={Automatically Generating Fix Suggestions in Response to Static Code Analysis Warnings},
year={2019},
pages={34-44},
keywords={Java;program debugging;program diagnostics;program verification;public domain software;software maintenance;software quality;static code analysis warnings;static code analysis tools;fix suggestions;open-source projects;industrial projects;Java program transformation;SpotBugs tools;SonarQube tools;Static Analysis Tools;Program Repair;Program Transformation},
doi={10.1109/SCAM.2019.00013},
ISSN={1942-5430},
month={Sep.},}

```

## Running
Please download the [runnable.jar](https://github.com/dvmarcilio/SpongeBugs/releases/download/2.0.0/spongebugs-runner-2.0.0.jar).

For a quickstart with default settings (all rules and ignoring test files):

    java -jar spongebugs-runner-2.0.0.jar /tmp/project/path/src
    
Please make sure that your java points to a JDK (version >= 8).

You can pass several path arguments to the jar, including directories and .java files. Make sure to provide full paths.

For more advanced settings, such as including/excluding specific rules, or to not ignore test files, refer to [RUNNING.md](RUNNING.md).

## Evaluation

First, we run SonarQube (through SonarCloud) on each project before and after running SpongeBugs. The rules implemented by SpongeBugs are outlined in the [Quality Profile](https://sonarcloud.io/organizations/spongebugs/rules?activation=true&qprofile=AWwfYsZg8aVgWcqKQLXH) used. Projects' dashboards can be found in [SpongeBugs' organization](https://sonarcloud.io/organizations/spongebugs/projects) in SonarCloud, and in the links below. Note that the dashboards below are related to SpongeBugs, and not the projects' original.  

For almost every project we asked whether pull-requests fixing issues would be welcome. We then proceeded to submit PRs with fixes that were randomly sampled.

### Eclipse IDE

GitHub (mirror): https://github.com/eclipse/eclipse.platform.ui

PRs welcome? [Tweet by Lars Vogel](https://twitter.com/vogella/status/1096088933144952832)

SonarCloud dashboard (Original): https://sonarcloud.io/dashboard?id=spongebugs-eclipse-platform-ui

SonarCloud dashboard (Extension): https://sonarcloud.io/dashboard?id=spongebugs-ext-eclipse-platform-ui

SonarCloud dashboard Without Step 1:: https://sonarcloud.io/dashboard?id=spongebugs-ext-nostep1-eclipse-platform-ui

commit hash: af25f6b71e4741983a94346ba782fbc272bbcdf5

Build instructions: https://www.slideshare.net/LarsVogel/eclipse-ide-and-platform-news-on-fosdem-2020/34

Build instructions 2: https://www.vogella.com/tutorials/EclipsePlatformDevelopment/article.html#build-instructions

PRs: 
1. https://git.eclipse.org/r/#/c/140484/
2. https://git.eclipse.org/r/#/c/140524/
3. https://git.eclipse.org/r/#/c/140668/
4. https://git.eclipse.org/r/#/c/141027/
5. https://git.eclipse.org/r/#/c/140856/
6. https://git.eclipse.org/r/#/c/140959/
7. https://git.eclipse.org/r/#/c/142386/
8. https://git.eclipse.org/r/#/c/143599/
9. https://git.eclipse.org/r/#/c/143788/

### SonarQube

GitHub: https://github.com/SonarSource/sonarqube

PRs welcome? Didn't ask.

SonarCloud dashboard (Original): https://sonarcloud.io/dashboard?id=spongebugs-sonar

SonarCloud dashboard (Extension): https://sonarcloud.io/dashboard?id=spongebugs-ext-sonar

SonarCloud dashboard Without Step 1:: https://sonarcloud.io/dashboard?id=spongebugs-ext-nostep1-sonar

commit hash: fd0b1a9c43ff7e50d3b817cb0f0359b6db4c6206

Build instructions: https://github.com/SonarSource/sonarqube#building

PRs: 
1. https://github.com/SonarSource/sonarqube/pull/3212

### SpotBugs

GitHub: https://github.com/spotbugs/spotbugs

PRs welcome? Question asked through e-mail.

SonarCloud dashboard (Original): https://sonarcloud.io/dashboard?id=spongebugs-spotbugs

SonarCloud dashboard (Extension): https://sonarcloud.io/dashboard?id=spongebugs-ext-spotbugs

SonarCloud dashboard Without Step 1:: https://sonarcloud.io/dashboard?id=spongebugs-ext-nostep1-spotbugs

commit hash: 01bc7b564e464860361f42a4bfd524a3f87cf2a2

Build instructions: https://github.com/spotbugs/spotbugs#build

PRs: 
1. https://github.com/spotbugs/spotbugs/pull/967

### atomix

GitHub: https://github.com/atomix/atomix

PRs welcome? [Asked on slack](https://atomixio.slack.com/archives/CE20WE4JC/p1559158367001400)

SonarCloud dashboard (Original): https://sonarcloud.io/dashboard?id=spongebugs-atomix

SonarCloud dashboard (Extension): https://sonarcloud.io/dashboard?id=spongebugs-ext-atomix

SonarCloud dashboard Without Step 1:: https://sonarcloud.io/dashboard?id=spongebugs-ext-nostep1-atomix

commit hash: dbad13756abfd997386c2d046a3d8bb8d45570d3

Build instructions: none

PRs: 
1. https://github.com/atomix/atomix/pull/1032
2. https://github.com/atomix/atomix/pull/1031

### Ant-Media Server

GitHub: https://github.com/ant-media/Ant-Media-Server

PRs welcome? [Asked on Google Group](https://groups.google.com/forum/#!topic/ant-media-server/Fo3n5zpU7vg)

SonarCloud dashboard (Original): https://sonarcloud.io/dashboard?id=spongebugs-ant-media-server

SonarCloud dashboard (Extension): https://sonarcloud.io/dashboard?id=spongebugs-ext-ant-media-server

SonarCloud dashboard Without Step 1:: https://sonarcloud.io/dashboard?id=spongebugs-ext-nostep1-ant-media-server

commit hash: 650f09b1aba67a6430fab16150f60ce58c7291ab

Build instructions: https://github.com/ant-media/Ant-Media-Server/wiki/Build-From-Source

PRs: 
1. https://github.com/ant-media/Ant-Media-Server/pull/1301
2. https://github.com/ant-media/Ant-Media-Server/pull/1302
3. https://github.com/ant-media/Ant-Media-Server/pull/1303

### database-rider

GitHub: https://github.com/database-rider/database-rider

PRs welcome? Question asked through e-mail.

SonarCloud dashboard (Original): https://sonarcloud.io/dashboard?id=spongebugs-database-rider

SonarCloud dashboard (Extension): https://sonarcloud.io/dashboard?id=spongebugs-ext-database-rider

SonarCloud dashboard Without Step 1:: https://sonarcloud.io/dashboard?id=spongebugs-ext-nostep1-database-rider

commit hash: 016f8bd6cdeb1521101d33905c3ac65c9f19f743

Build instructions: https://database-rider.github.io/getting-started/#setup_database_rider

PRs: 
1. https://github.com/database-rider/database-rider/pull/138
2. https://github.com/database-rider/database-rider/pull/139
3. https://github.com/database-rider/database-rider/pull/140
4. https://github.com/database-rider/database-rider/pull/141

### ddf

GitHub: https://github.com/codice/ddf

PRs welcome? [Asked on Google group](https://groups.google.com/forum/?fromgroups#!topic/ddf-developers/Ovdj2lohGow).

SonarCloud dashboard (Original): https://sonarcloud.io/dashboard?id=spongebugs-ddf

SonarCloud dashboard (Extension): https://sonarcloud.io/dashboard?id=spongebugs-ext-ddf

SonarCloud dashboard Without Step 1:: https://sonarcloud.io/dashboard?id=spongebugs-ext-nostep1-ddf

commit hash: 60518b55dbdd45f799eecf0e618be65077a0fbff

Build instructions: https://codice.atlassian.net/wiki/spaces/DDF/pages/70986756/Cloning+Building+DDF

PRs: 
1. https://github.com/codice/ddf/pull/4933
2. https://github.com/codice/ddf/pull/4934
3. https://github.com/codice/ddf/pull/4935

### DependencyCheck

GitHub: https://github.com/jeremylong/DependencyCheck

PRs welcome? [GitHub issue](https://github.com/jeremylong/DependencyCheck/issues/1963)

SonarCloud dashboard (Original): https://sonarcloud.io/dashboard?id=spongebugs-dependency-check

SonarCloud dashboard (Extension): https://sonarcloud.io/dashboard?id=spongebugs-ext-dependency-check

SonarCloud dashboard Without Step 1:: https://sonarcloud.io/dashboard?id=spongebugs-ext-nostep1-dependency-check

commit hash: c91f5ad50307598804382f379e3ea779470ba833

Build instructions: https://github.com/jeremylong/DependencyCheck#development-usage

Build instructions 2: https://github.com/jeremylong/DependencyCheck#building-from-source

PRs: 
1. https://github.com/jeremylong/DependencyCheck/pull/1976

### keanu

GitHub: https://github.com/improbable-research/keanu

PRs welcome? [GitHub issue](https://github.com/improbable-research/keanu/issues/565)

SonarCloud dashboard (Original): https://sonarcloud.io/dashboard?id=spongebugs-keanu

SonarCloud dashboard (Extension): https://sonarcloud.io/dashboard?id=spongebugs-ext-keanu

SonarCloud dashboard Without Step 1:: https://sonarcloud.io/dashboard?id=spongebugs-ext-nostep1-keanu

commit hash: 0088e7841265a106dcdafee717d521353dbb4868

Build instructions: https://github.com/improbable-research/keanu#building-the-code

PRs: 
1. https://github.com/improbable-research/keanu/pull/566
2. https://github.com/improbable-research/keanu/pull/567
3. https://github.com/improbable-research/keanu/pull/568

### mssql-jdbc

GitHub: https://github.com/microsoft/mssql-jdbc

PRs welcome? [GitHub issue](https://github.com/microsoft/mssql-jdbc/issues/1076)

SonarCloud dashboard (Original): https://sonarcloud.io/dashboard?id=spongebugs-mssql-jdbc

SonarCloud dashboard (Extension): https://sonarcloud.io/dashboard?id=spongebugs-ext-mssql-jdbc

SonarCloud dashboard Without Step 1:: https://sonarcloud.io/dashboard?id=spongebugs-ext-nostep1-mssql-jdbc

commit hash: 8d4613ef8cc3ce20ad4d58d6686a4070f12c30ed

Build instructions: https://github.com/microsoft/mssql-jdbc#build

PRs: 
1. https://github.com/microsoft/mssql-jdbc/pull/1077

### Payara

GitHub: https://github.com/payara/Payara

PRs welcome? [GitHub issue](https://github.com/payara/Payara/issues/4017)

SonarCloud dashboard (Original): https://sonarcloud.io/dashboard?id=spongebugs-payara

SonarCloud dashboard (Extension): https://sonarcloud.io/dashboard?id=spongebugs-ext-payara2

SonarCloud dashboard Without Step 1:: https://sonarcloud.io/dashboard?id=spongebugs-ext-nostep1-payara

commit hash: c5ddbc755c

Build instructions: https://payara.gitbooks.io/payara-server/build-instructions/build-instructions.html

PRs: 
1. https://github.com/payara/Payara/pull/4022
2. https://github.com/payara/Payara/pull/4026
3. https://github.com/payara/Payara/pull/4030
4. https://github.com/payara/Payara/pull/4032
5. https://github.com/payara/Payara/pull/4033
6. https://github.com/payara/Payara/pull/4038

### PrimeFaces

GitHub: https://github.com/primefaces/primefaces

PRs welcome? [Asked on forum](https://forum.primefaces.org/viewtopic.php?f=3&t=59104)

SonarCloud dashboard (Original): https://sonarcloud.io/dashboard?id=spongebugs-primefaces

SonarCloud dashboard (Extension): https://sonarcloud.io/dashboard?id=spongebugs-ext-primefaces

SonarCloud dashboard Without Step 1:: https://sonarcloud.io/dashboard?id=spongebugs-ext-nostep1-primefaces

commit hash: 3183384cfd940d3d4d46ace5bbbd379818a0a567

Build instructions: https://github.com/primefaces/primefaces/wiki/Building-From-Source

PRs: 
1. https://github.com/primefaces/primefaces/pull/4879
2. https://github.com/primefaces/primefaces/pull/4880
3. https://github.com/primefaces/primefaces/pull/4885
4. https://github.com/primefaces/primefaces/pull/4887
