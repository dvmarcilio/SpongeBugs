@license{
  Copyright (c) 2009-2015 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Rodrigo Bonifacio - rbonifacio@unb.br - CIC/UnB}

// This grammar is based on the following references:
//
//  - https://docs.oracle.com/javase/specs/jls/se8/html/jls-19.html
//  - https://github.com/antlr/grammars-v4/blob/master/java8/Java8.g4

module Java8

syntax Literal = IntegerLiteral
  			   | FloatingPointLiteral
  			   | BooleanLiteral
  			   | CharacterLiteral
  			   | StringLiteral
  			   | NullLiteral
  			   ;
  		
/*
 * Productions from §4 (Types, Values, and Variables)
 */
 
 syntax Type = PrimitiveType
             | ReferenceType
             ;
             
 syntax PrimitiveType = Annotation* NumericType
                      | Annotation* "boolean" 
                      ;
                      
 syntax NumericType = IntegralType
                    | FloatingPointType
                    ;
                    
syntax IntegralType = "byte" 
                    | "short" 
                    | "int" 
                    | "long" 
                    | "char"
                    ;
                    
syntax FloatingPointType = "float" | "double" ;

syntax ReferenceType = ClassOrInterfaceType 
                     | TypeVariable 
                     | ArrayType
                     ;
                     
syntax ClassOrInterfaceType = ClassType 
                     | InterfaceType
                     ;
                                          
syntax ClassType = Annotation* Identifier TypeArguments? 
                 | ClassOrInterfaceType "." Annotation* Identifier TypeArguments?
                 ;                                          
syntax InterfaceType = ClassType;

syntax TypeVariable = Annotation* Identifier;

syntax ArrayType = PrimitiveType Dims 
                 | ClassOrInterfaceType Dims 
                 | TypeVariable Dims;
                 
syntax Dims = Annotation* "[" "]" (Annotation* "[" "]")*; 

syntax TypeParameter = TypeParameterModifier* Identifier TypeBound? ;

syntax TypeParameterModifier = Annotation; 

syntax TypeBound = "extends" TypeVariable
                 | "extends" ClassOrInterfaceType AdditionalBound*
                 ;
                 
syntax AdditionalBound = "&" InterfaceType ;


syntax TypeArguments = "\<"  {TypeArgument ","}* "\>" ;

syntax TypeArgument = ReferenceType 
                    | Wildcard
                    ;
                    
syntax Wildcard = Annotation* "?" WildcardBounds? ;

syntax WildcardBounds = "extends" ReferenceType
	                  |	"super" ReferenceType
	                  ;                                    

/*
 * Productions from §6 (Names)
 */
 
syntax TypeName = Identifier
                | PackageOrTypeName "." Identifier
                ;
                
syntax PackageOrTypeName = Identifier 
                         | PackageOrTypeName "." Identifier
                         ;
syntax ExpressionName = Identifier 
                      | AmbiguousName "." Identifier                        
                      ;
                     
syntax MethodName = Identifier;

syntax PackageName = Identifier 
                   | PackageName "." Identifier
                   ;
                   
syntax AmbiguousName = Identifier 
                     | AmbiguousName "." Identifier
                     ;
                     
                     
/*
 * Productions from §7 (Packages)
 */                    
 
syntax CompilationUnit = PackageDeclaration? ImportDeclaration* TypeDeclaration* ;
 
syntax PackageDeclaration = PackageModifier* "package" {Identifier "."}+ ";" ;

syntax PackageModifier = Annotation ;

syntax ImportDeclaration = SingleTypeImportDeclaration       // import Class; 
                         | TypeImportOnDemandDeclaration     // import br.unb.rascal.*;
                         | SingleStaticImportDeclaration     // import static br.unb.rascal.Foo.m;
                         | StaticImportOnDemandDeclaration   // import static br.unb.rascal.Foo.*;
                         ;
 
syntax SingleTypeImportDeclaration = "import" TypeName ";" ;

syntax TypeImportOnDemandDeclaration = "import" PackageOrTypeName "." "*" ";" ;

syntax SingleStaticImportDeclaration = "import" "static" TypeName "." Identifier ";";

syntax StaticImportOnDemandDeclaration = "import" "static" TypeName "." "*" ";" ;                         


syntax TypeDeclaration = ClassDeclaration 
                       | InterfaceDeclaration 
                       ;

syntax ClassDeclaration = NormalClassDeclaration 
                        | EnumDeclaration
                        ;
                        
syntax NormalClassDeclaration = ClassModifier* "class" Identifier TypeParameters? Superclass? Superinterfaces? ClassBody ;

syntax ClassModifier = Annotation 
                     | "public" 
                     | "protected" 
                     | "private" 
                     | "abstract" 
                     | "static" 
                     | "final" 
                     | "strictfp"
                     ;

syntax TypeParameters = "\<" {TypeParameter ","}+ "\>" ; 

syntax Superclass = "extends" ClassType ;

syntax Superinterfaces = "implements" {InterfaceType ","}+ ;

syntax ClassBody = "{" ClassBodyDeclaration* "}";

syntax ClassBodyDeclaration = ClassMemberDeclaration 
                            | InstanceInitializer 
                            | StaticInitializer 
                            | ConstructorDeclaration 
                            ;
                            
syntax ClassMemberDeclaration = FieldDeclaration 
                              | MethodDeclaration 
                              | ClassDeclaration 
                              | InterfaceDeclaration 
                              ;
                              
syntax FieldDeclaration = FieldModifier* UnannType VariableDeclaratorList ;

syntax FieldModifier = Annotation 
                     | "public" 
                     | "protected" 
                     | "private" 
                     | "static" 
                     | "final" 
                     | "transient" 
                     | "volatile"
                     ;

syntax VariableDeclaratorList = {VariableDeclarator ","}+ ; 

syntax VariableDeclarator = VariableDeclaratorId ("=" VariableInitializer)? ;

syntax VariableDeclaratorId = Identifier Dims? ;

syntax VariableInitializer = Expression 
                           | ArrayInitializer
                           ;                                                                               

syntax UnannType = UnannPrimitiveType 
                 | UnannReferenceType
                 ;
                 
syntax UnannPrimitiveType = NumericType 
                          | "boolean" 
                          ;

syntax UnannReferenceType = UnannClassOrInterfaceType 
                          | UnannTypeVariable 
                          | UnannArrayType
                          ;
                          
syntax UnannClassOrInterfaceType = UnannClassType 
                                 | UnannInterfaceType
                                 ; 
                          
syntax UnannClassType = Identifier TypeArguments? 
                      | UnannClassOrInterfaceType "." Annotation* Identifier TypeArguments?;
               
syntax UnannInterfaceType = UnannClassType ; 

syntax UnannTypeVariable = Identifier ; 

syntax UnannArrayType = UnannPrimitiveType Dims 
               | UnannClassOrInterfaceType Dims 
               |UnannTypeVariable Dims
               ;

syntax MethodDeclaration = MethodModifier* MethodHeader MethodBody ;

syntax MethodModifier = Annotation 
                      | "public" 
                      | "protected" 
                      | "private"
                      | "abstract" 
                      | "static" 
                      | "final" 
                      | "synchronized" 
                      | "native" 
                      | "strictfp"
                      ;

syntax MethodHeader = Result MethodDeclarator Throws?
                    |  TypeParameters Annotation* Result MethodDeclarator Throws
                    ;
                    
syntax Result = UnannType 
              | "void" 
              ;
              
syntax MethodDeclarator = Identifier "(" FormalParameterList? ")" Dims? ;

syntax FormalParameterList = ReceiverParameter 
                           | FormalParameters "," LastFormalParameter 
                           | LastFormalParameter
                           ;
                            
syntax FormalParameters = {FormalParameter ","}+  
                         | ReceiverParameter ("," FormalParameter)*
                         ;                                   

syntax FormalParameter = VariableModifier* UnannType VariableDeclaratorId ;

syntax VariableModifier = Annotation 
                        | "final" 
                        ;
                        
syntax LastFormalParameter = VariableModifier* UnannType Annotation* "..." VariableDeclaratorId 
                           | FormalParameter
                           ;

syntax ReceiverParameter = Annotation* UnannType (Identifier ".")? "this" ;

syntax Throws = "throws" { ExceptionType "," }+;  

syntax ExceptionType = ClassType 
                     | TypeVariable
                     ; 


syntax MethodBody = Block 
                  | ";"
                  ;
                   
syntax InstanceInitializer = Block ;

syntax StaticInitializer = "static" Block ;

syntax ConstructorDeclaration = ConstructorModifier* ConstructorDeclarator Throws? ConstructorBody ;

syntax ConstructorModifier = Annotation 
                           | "public" 
                           | "protected" 
                           | "private" 
                           ;
                           
syntax ConstructorDeclarator = TypeParameters? SimpleTypeName "(" FormalParameterList? ")" ;

syntax SimpleTypeName = Identifier ;

syntax ConstructorBody = "{" ExplicitConstructorInvocation? BlockStatements? "}" ;

syntax ExplicitConstructorInvocation = TypeArguments? "this" "(" ArgumentList? ")" ";"  
                                     | TypeArguments? "super" "(" ArgumentList? ")" ";" 
                                     | ExpressionName "." TypeArguments "super" "(" ArgumentList? ")" ";" 
                                     | Primary "." TypeArguments? "super" "(" ArgumentList? ")" ";"
                                     ;

syntax EnumDeclaration = ClassModifier* "enum" Identifier Superinterfaces? EnumBody ;

syntax EnumBody = "{" EnumConstantList? ","? EnumBodyDeclarations? "}" ;

syntax EnumConstantList = { EnumConstant "," }+ ;

syntax EnumConstant = EnumConstantModifier* Identifier ("(" ArgumentList? ")")? ClassBody ? ;

syntax EnumConstantModifier = Annotation ; 

syntax EnumBodyDeclarations = ";" ClassBodyDeclaration* ;

syntax InterfaceDeclaration = NormalInterfaceDeclaration 
                            | AnnotationTypeDeclaration
                            ;
                            
syntax NormalInterfaceDeclaration = InterfaceModifier* "interface" Identifier TypeParameters? ExtendsInterfaces? InterfaceBody ;

syntax InterfaceModifier = Annotation 
                         | "public" 
                         | "protected" 
                         | "private" 
                         | "abstract" 
                         | "static" 
                         | "strictfp"
                         ;
                         
syntax ExtendsInterfaces = "extends" {InterfaceType ","}+ ; 

syntax InterfaceBody = "{" InterfaceMemberDeclaration* "}" ;

syntax InterfaceMemberDeclaration = ConstantDeclaration 
                                  | InterfaceMethodDeclaration 
                                  | ClassDeclaration 
                                  | InterfaceDeclaration 
                                  | ";" 
                                  ;

syntax ConstantDeclaration = ConstantModifier* UnannType VariableDeclaratorList ";" ;

syntax ConstantModifier = Annotation 
                        | "public" 
                        | "static" 
                        | "final"
                        ;
                        
syntax InterfaceMethodDeclaration = InterfaceMethodModifier* MethodHeader MethodBody ;

syntax InterfaceMethodModifier = Annotation 
                               | "public" 
                               | "abstract" 
                               | "default" 
                               | "static" 
                               | "strictfp"
                               ;
                               
syntax AnnotationTypeDeclaration = InterfaceModifier* "@" "interface" Identifier AnnotationTypeBody ;

syntax AnnotationTypeBody = "{" AnnotationTypeMemberDeclaration* "}" ;

syntax AnnotationTypeMemberDeclaration = AnnotationTypeElementDeclaration 
                                       | ConstantDeclaration 
                                       | ClassDeclaration 
                                       | InterfaceDeclaration 
                                       | ";"
                                       ;

syntax AnnotationTypeElementDeclaration = AnnotationTypeElementModifier* UnannType Identifier "(" ")" Dims? DefaultValue? ;

syntax AnnotationTypeElementModifier = Annotation 
                                     | "public" 
                                     | "abstract"
                                     ;
                                     
syntax DefaultValue = "default" ElementValue ;

syntax Annotation = NormalAnnotation 
                  | MarkerAnnotation 
                  | SingleElementAnnotation
                  ;

syntax NormalAnnotation = "@" TypeName "(" ElementValuePairList? ")" ;

syntax ElementValuePairList = {ElementValuePair ","}+ ;

syntax ElementValuePair = Identifier "=" ElementValue ;

syntax ElementValue = ConditionalExpression 
                    | ElementValueArrayInitializer 
                    | Annotation 
                    ;
                    
syntax ElementValueArrayInitializer = "{" ElementValueList? ","? "}" ;

syntax ElementValueList = { ElementValue "," }*;

syntax MarkerAnnotation = "@" TypeName ;

syntax SingleElementAnnotation = "@" TypeName "(" ElementValue ")" ;

/*
 * Productions from §10 (Arrays)
 */
 
syntax ArrayInitializer = "{" VariableInitializerList? ","? "}" ; 

syntax VariableInitializerList = { VariableInitializer "," }+ ;

/*
 * Productions from §14 (Blocks and Statements)
 */
 
syntax Block = "{" BlockStatements? "}" ;

syntax BlockStatements = BlockStatement* ;

syntax BlockStatement = LocalVariableDeclarationStatement 
                      | ClassDeclaration 
                      | Statement
                      ;
                      
syntax LocalVariableDeclarationStatement = LocalVariableDeclaration ";" ;

syntax LocalVariableDeclaration = VariableModifier* UnannType VariableDeclaratorList ;

syntax Statement = StatementWithoutTrailingSubstatement 
                 | LabeledStatement 
                 | IfThenStatement 
                 | IfThenElseStatement 
                 | WhileStatement 
                 | ForStatement
                 ; 
                 
syntax StatementNoShortIf = StatementWithoutTrailingSubstatement 
                          | LabeledStatementNoShortIf 
                          | IfThenElseStatementNoShortIf 
                          | WhileStatementNoShortIf 
                          | ForStatementNoShortIf
                          ; 
                          
syntax StatementWithoutTrailingSubstatement = Block 
                                            | EmptyStatement 
                                            | ExpressionStatement 
                                            | AssertStatement 
                                            | SwitchStatement 
                                            | DoStatement 
                                            | BreakStatement 
                                            | ContinueStatement 
                                            | ReturnStatement 
                                            | SynchronizedStatement 
                                            | ThrowStatement 
                                            | TryStatement
                                            ;
syntax EmptyStatement = ";" ; 

syntax LabeledStatement = Identifier ":" Statement ;

syntax LabeledStatementNoShortIf = Identifier ":"  StatementNoShortIf ; 

syntax ExpressionStatement = StatementExpression ";" ;

syntax StatementExpression = Assignment 
                           | PreIncrementExpression 
                           | PreDecrementExpression 
                           | PostIncrementExpression 
                           | PostDecrementExpression 
                           | MethodInvocation 
                           | ClassInstanceCreationExpression
                           ;
                           
                           
syntax IfThenStatement = "if" "(" Expression ")" Statement ;

syntax IfThenElseStatement = "if" "(" Expression ")" StatementNoShortIf "else" Statement ;

syntax IfThenElseStatementNoShortIf = "if" "(" Expression ")" StatementNoShortIf "else" StatementNoShortIf ;

syntax AssertStatement = "assert" Expression ";"   
                       | "assert" Expression ":" Expression ";" 
                       ; 
                      
syntax SwitchStatement = "switch" "(" Expression ")" SwitchBlock ; 

syntax SwitchBlock = "{" SwitchBlockStatementGroup* SwitchLabel* "}" ;

syntax SwitchBlockStatementGroup = SwitchLabels BlockStatements ;

syntax SwitchLabels = SwitchLabel+ ; 

syntax SwitchLabel = "case" ConstantExpression ":" 
                   | "case" EnumConstantName ":" 
                   | "default" ":" 
                   ;
                   
syntax EnumConstantName = Identifier ;  

syntax WhileStatement = "while" "(" Expression ")" Statement ; 

syntax WhileStatementNoShortIf = "while" "(" Expression ")" StatementNoShortIf ;

                   

