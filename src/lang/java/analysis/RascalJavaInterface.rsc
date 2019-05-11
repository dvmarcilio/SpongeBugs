module lang::java::analysis::RascalJavaInterface


import String;


@javaClass{unb.rascaljava.RascalJavaInterface}
java int initDB(str projectPath);

@javaClass{unb.rascaljava.RascalJavaInterface}
java bool isRelated(str clazzA, str clazzB);
