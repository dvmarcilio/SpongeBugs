# Refactoring Java Code towards Language Evolution

### Motivation

<div style="text-align: right"> 
... when code does not evolve with its language,                                                    
maintaining backward compatibility means 
that a language can be expanded, but nothing can 
be removed
... This leads to a language 
that is increasingly large and complex and 
makes the learning curve steeper and maintenance 
more difficult

(Jeffrey Overbey and Ralph Johnson, [Regrowing a Language](http://dl.acm.org/citation.cfm?id=1640127). 
Onward! 2009.)
</div>


### Goal 

Implement a set of refactorings (using [Rascal-MPL](http://rascal-mpl.org)) 
to evolve a legacy Java systems towards the usage of more recent 
constructs of the language. 

### Current transformations 

   * Convert Anonymous Inner Classes into Lambda Expressions
   * Convert explicit typing of generic r-alues into Diamond Operator 
   * Conver if-then-else-if on the value of strings to Switch String
   * Convert similar catch blocks into MultiCatch 

### How to use it

   * clone this repository
   * install [rascal-mpl ide](http://www.rascal-mpl.org/start/)
   * import this project to the rascal workspace
   * execute the rascal shell using this project as reference
   * import the Driver module (such as > import Driver;)  
   * execute the function refactorProjects passing as argument a location for an input file 

The input file is in the CSV format, with at least the following columns: 

   * project name
   * project revision (to help on reproducibility) 
   * type of tranformation (DI for diamond operator, AC for anonymous to lambda, MC for multi-catch)
   * percentage (just a number, with the percentage of transformations with respect to the oportunities)   * absolute path to the project 


