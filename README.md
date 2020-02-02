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
Please download the [runnable.jar](https://github.com/dvmarcilio/SpongeBugs/releases/download/1.0.1/spongebugs-runner-20-12-19.jar).

For a quickstart with default settings (all rules and ignoring test files):

    java -jar spongebugs-runner-20-12-19.jar project/path/src
    
Please make sure that your java points to a JDK (at least version 8).

You can pass as many paths as arguments to the jar, including directories and .java files. Make sure to provide full paths.

For more advanced settings, such as including/excluding specific rules, or to not ignore test files, refer to [RUNNING.md](RUNNING.md).

## Evaluation

First, we run SonarQube (through SonarCloud) on each project before and after running SpongeBugs. The rules implemented by SpongeBugs are outlined in the [Quality Profile](https://sonarcloud.io/organizations/spongebugs/rules?activation=true&qprofile=AWwfYsZg8aVgWcqKQLXH) used. Projects' dashboards can be found in [SpongeBugs' organization](https://sonarcloud.io/organizations/spongebugs/projects) in SonarCloud, and in the links below. Note that the dashboards below are related to SpongeBugs, and not the projects' original.  

For almost every project we asked whether pull-requests fixing issues would be welcome. We then proceeded to submit PRs with fixes that were randomly sampled.

### Eclipse IDE

**GitHub (mirror):** https://github.com/eclipse/eclipse.platform.ui

**SonarCloud dashboard**: https://sonarcloud.io/dashboard?id=spongebugs-eclipse-platform-ui

**PRs welcome?** [Tweet by Lars Vogel](https://twitter.com/vogella/status/1096088933144952832)

**PRs:** 
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

**GitHub:** https://github.com/SonarSource/sonarqube

**SonarCloud dashboard**: https://sonarcloud.io/dashboard?id=spongebugs-sonar

**PRs welcome?** Didn't ask.

**PRs:** 
1. https://github.com/SonarSource/sonarqube/pull/3212

### SpotBugs

**GitHub:** https://github.com/spotbugs/spotbugs

**SonarCloud dashboard**: https://sonarcloud.io/dashboard?id=spongebugs-spotbugs

**PRs welcome?** Question asked through e-mail.

**PRs:** 
1. https://github.com/spotbugs/spotbugs/pull/967

### atomix

**GitHub:** https://github.com/atomix/atomix

**SonarCloud dashboard**: https://sonarcloud.io/dashboard?id=spongebugs-atomix

**PRs welcome?** [Asked on slack](https://atomixio.slack.com/archives/CE20WE4JC/p1559158367001400)

**PRs:** 
1. https://github.com/atomix/atomix/pull/1032
2. https://github.com/atomix/atomix/pull/1031

### Ant-Media Server

**GitHub:** https://github.com/ant-media/Ant-Media-Server

**SonarCloud dashboard**: https://sonarcloud.io/dashboard?id=spongebugs-ant-media-server

**PRs welcome?** [Asked on Google Group](https://groups.google.com/forum/#!topic/ant-media-server/Fo3n5zpU7vg)

**PRs:** 
1. https://github.com/ant-media/Ant-Media-Server/pull/1301
2. https://github.com/ant-media/Ant-Media-Server/pull/1302
3. https://github.com/ant-media/Ant-Media-Server/pull/1303

### database-rider

**GitHub:** https://github.com/database-rider/database-rider

**SonarCloud dashboard**: https://sonarcloud.io/dashboard?id=spongebugs-database-rider

**PRs welcome?** Question asked through e-mail.

**PRs:** 
1. https://github.com/database-rider/database-rider/pull/138
2. https://github.com/database-rider/database-rider/pull/139
3. https://github.com/database-rider/database-rider/pull/140
4. https://github.com/database-rider/database-rider/pull/141

### ddf

**GitHub:** https://github.com/codice/ddf

**SonarCloud dashboard**: https://sonarcloud.io/dashboard?id=spongebugs-ddf 

**PRs welcome?** [Asked on Google group](https://groups.google.com/forum/?fromgroups#!topic/ddf-developers/Ovdj2lohGow).

**PRs:** 
1. https://github.com/codice/ddf/pull/4933
2. https://github.com/codice/ddf/pull/4934
3. https://github.com/codice/ddf/pull/4935

### DependencyCheck

**GitHub:** https://github.com/jeremylong/DependencyCheck

**SonarCloud dashboard**: https://sonarcloud.io/dashboard?id=spongebugs-dependency-check

**PRs welcome?** [GitHub issue](https://github.com/jeremylong/DependencyCheck/issues/1963)

**PRs:** 
1. https://github.com/jeremylong/DependencyCheck/pull/1976

### keanu

**GitHub:** https://github.com/improbable-research/keanu

**SonarCloud dashboard**: https://sonarcloud.io/dashboard?id=spongebugs-keanu

**PRs welcome?** [GitHub issue](https://github.com/improbable-research/keanu/issues/565)

**PRs:** 
1. https://github.com/improbable-research/keanu/pull/566
2. https://github.com/improbable-research/keanu/pull/567
3. https://github.com/improbable-research/keanu/pull/568

### mssql-jdbc

**GitHub:** https://github.com/microsoft/mssql-jdbc

**SonarCloud dashboard**: https://sonarcloud.io/dashboard?id=spongebugs-mssql-jdbc

**PRs welcome?** [GitHub issue](https://github.com/microsoft/mssql-jdbc/issues/1076)

**PRs:** 
1. https://github.com/microsoft/mssql-jdbc/pull/1077

### Payara

**GitHub:** https://github.com/payara/Payara

**SonarCloud dashboard**: https://sonarcloud.io/dashboard?id=spongebugs-payara

**PRs welcome?** [GitHub issue](https://github.com/payara/Payara/issues/4017)

**PRs:** 
1. https://github.com/payara/Payara/pull/4022
2. https://github.com/payara/Payara/pull/4026
3. https://github.com/payara/Payara/pull/4030
4. https://github.com/payara/Payara/pull/4032
5. https://github.com/payara/Payara/pull/4033
6. https://github.com/payara/Payara/pull/4038

### PrimeFaces

**GitHub:** https://github.com/primefaces/primefaces

**SonarCloud dashboard**: https://sonarcloud.io/dashboard?id=spongebugs-primefaces

**PRs welcome?** [Asked on forum](https://forum.primefaces.org/viewtopic.php?f=3&t=59104)

**PRs:** 
1. https://github.com/primefaces/primefaces/pull/4879
2. https://github.com/primefaces/primefaces/pull/4880
3. https://github.com/primefaces/primefaces/pull/4885
4. https://github.com/primefaces/primefaces/pull/4887
