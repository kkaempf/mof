/*
 * According to appendix A of
 * http://www.dmtf.org/standards/cim/cim_spec_v22
 */

class Mofparser
  prechigh
/*    nonassoc UMINUS */
    left '*' '/'
    left '+' '-'
  preclow

  token PRAGMA IDENTIFIER CLASS ASSOCIATION INDICATION
        ENABLEOVERRIDE DISABLEOVERRIDE RESTRICTED TOSUBCLASS  
	TRANSLATABLE QUALIFIER SCOPE SCHEMA PROPERTY REFERENCE
	METHOD PARAMETER FLAVOR INSTANCE
	AS REF ANY OF
	DT_UINT8 DT_SINT8 DT_UINT16 DT_SINT16 DT_UINT32 DT_SINT32
	DT_UINT64 DT_SINT64 DT_REAL32 DT_REAL64 DT_CHAR16 DT_STR
	DT_BOOL DT_DATETIME
	positiveDecimalValue
	stringValue
	realValue
	charValue
	booleanValue
	nullValue
	binaryValue
	octalValue
	decimalValue
	hexValue
	
rule

  mofSpecification
        : /* empty */
	  { result = @schema }
	| mofProduction
	  { result = @schema }
	| mofSpecification mofProduction
	  { result = @schema }
        ;
	
  mofProduction
        : compilerDirective
	| classDeclaration
	  { @schema.classes << val[0] }
	| assocDeclaration
	  { @schema.associations << val[0] }
	| indicDeclaration
	  { @schema.indications << val[0] }
	| qualifierDeclaration
	  { @schema.qualifiers << val[0] }
	| instanceDeclaration
	  { @schema.instances << val[0] }
        ;

/***
 * compilerDirective
 *
 */
 
  compilerDirective
	: "#" PRAGMA pragmaName pragmaParameter
	  { case val[2]
              when "include"
		open val[3], :pragma
            end
	    result = nil
          }
        ;

  pragmaName
	: IDENTIFIER
        ;

  pragmaParameter
        : /* empty */
	  { raise InvalidMofSyntax, "#pragma parameter missing" unless @strict == :windows }
	| "(" pragmaParameterValue ")"
	  { result = val[1] }
	;
  pragmaParameterValue
        : string
	| integerValue
	  { raise InvalidMofSyntax, "#pragma parameter missing" unless @strict == :windows }
	;

/***
 * classDeclaration
 *
 */
 
  classDeclaration
	: qualifierList_opt CLASS className alias_opt superClass_opt "{" classFeatures "}" ";"
        ;

  qualifierList_opt
	: /* empty */
	| qualifierList
        ;

  qualifierList
	: "[" qualifier qualifiers "]"
        ;

  qualifiers
	: /* empty */
        | qualifiers "," qualifier
        ;
	
  qualifier
	: qualifierName qualifierParameter_opt flavor_opt
        ;

  flavor_opt
	: /* empty */
	| ":" flavor
        ;

  qualifierParameter_opt
	: /* empty */
        | qualifierParameter
        ;

  qualifierParameter
	: "(" constantValue ")"
	  { result = val[1] }
        | arrayInitializer
        ;

  /* CIM::Meta::Flavors */
  flavor
	: ENABLEOVERRIDE | DISABLEOVERRIDE | RESTRICTED | TOSUBCLASS | TRANSLATABLE
        ;

  alias_opt
	: /* empty */
	| alias
        ;

  superClass_opt
	: /* empty */
	| superClass
        ;

  classFeatures
	: /* empty */
	| classFeatures classFeature
        ;

/***
 * assocDeclaration
 *
 */
 
  assocDeclaration
	: "[" ASSOCIATION qualifiers "]" CLASS className alias_opt superClass_opt "{" associationFeatures "}" ";"
        ;

  associationFeatures
	: /* empty */
	| associationFeatures associationFeature
        ;

  /* Context:
   *
   * The remaining qualifier list must not include
   * the ASSOCIATION qualifier again. If the
   * association has no super association, then at
   * least two references must be specified! The
   * ASSOCIATION qualifier may be omitted in
   * sub associations.
   */

/***
 * indicDeclaration
 *
 */
 
  indicDeclaration
	: "[" INDICATION qualifiers "]" CLASS className alias_opt superClass_opt "{" classFeatures "}" ";"
        ;

  className
	: IDENTIFIER /* must be <schema>_<classname> in CIM v2.x */
	  { raise ParseError, "Class name must be prefixed by '<schema>_'" unless val[0].include?("_") || @strict == :windows }
        ;

  alias
	: AS aliasIdentifier
        ;

  aliasIdentifier
	: "$" IDENTIFIER /* NO whitespace ! */
        ;

  superClass
	: ":" className
	  { result = val[1] }
        ;

  classFeature
	: propertyDeclaration
	| methodDeclaration
        ;

  associationFeature
	: classFeature
	| referenceDeclaration
        ;

  propertyDeclaration
	: qualifierList_opt dataType propertyName array_opt defaultValue_opt ";"
        ;
	
  referenceDeclaration
	: qualifierList_opt objectRef referenceName defaultValue_opt ";"
        ;

  methodDeclaration
	: qualifierList_opt dataType methodName "(" parameterList_opt ")" ";"
        ;

  propertyName
	: IDENTIFIER
        ;

  referenceName
	: IDENTIFIER
        ;

  methodName
	: IDENTIFIER
        ;

  dataType
	: DT_UINT8
	| DT_SINT8
	| DT_UINT16
	| DT_SINT16
	| DT_UINT32
	| DT_SINT32
	| DT_UINT64
	| DT_SINT64
	| DT_REAL32
	| DT_REAL64
	| DT_CHAR16
	| DT_STR
	| DT_BOOL
	| DT_DATETIME
        ;

  objectRef
	: className REF
        ;

  parameterList_opt
	: /* empty */
        | parameterList
        ;
	
  parameterList
	: parameter parameters
        ;

  parameters
	: /* empty */
	| parameters "," parameter
        ;

  parameter
	: qualifierList_opt typespec parameterName array_opt
        ;

  typespec
	: dataType
	| objectRef
        ;

  parameterName
	: IDENTIFIER
        ;

  array_opt
	: /* empty */
	  { result = nil }
        | array
        ;

  array
	: "[" positiveDecimalValue_opt "]"
	  { result = val[1] }
        ;

  positiveDecimalValue_opt
	: /* empty */
	  { result = -1 }
	| positiveDecimalValue
        ;

  defaultValue_opt
	: /* empty */
        | defaultValue
        ;
	
  defaultValue
	: "=" initializer
	  { result = val[1]}
        ;

  initializer
	: constantValue
	| arrayInitializer
	| referenceInitializer
        ;

  arrayInitializer
	: "{" constantValue constantValues "}"
        ;

  constantValues
	: /* empty */
	| constantValues "," constantValue
        ;

  constantValue
	: integerValue
	| realValue
	| charValue
	| string
	| booleanValue
	| nullValue
        ;

  integerValue
	: binaryValue
	| octalValue
	| decimalValue
	| positiveDecimalValue
	| hexValue
        ;

  string
        : stringValue
	| string stringValue
	  { result = val[0] + val[1] }
	;
	
  referenceInitializer
	: objectHandle
	| aliasIdentifier
        ;

  objectHandle
	: namespace_opt modelPath
        ;

  namespace_opt
	: /* empty */
	| namespaceHandle ":"
        ;

  namespaceHandle
	: IDENTIFIER
        ;

  /*
   * Note
	: structure depends on type of namespace
   */

  modelPath
	: className "." keyValuePairList
        ;

  keyValuePairList
	: keyValuePair keyValuePairs
        ;

  keyValuePairs
	: /* empty */
	| keyValuePairs "," keyValuePair
        ;

  keyValuePair
	: keyname "=" initializer
        ;

  keyname
	: propertyName | referenceName
        ;

/***
 * qualifierDeclaration
 *
 */
 
  qualifierDeclaration
          /*      0             1             2     3                 4 */
	: QUALIFIER qualifierName qualifierType scope defaultFlavor_opt ";"
	  { result = CIM::Meta::Qualifier.new( val[1], val[2][0], nil, val[3], val[4], val[2][1]) }
        ;

  defaultFlavor_opt
	: /* empty */
	| defaultFlavor
        ;

  qualifierName
	: IDENTIFIER
	| ASSOCIATION /* meta qualifier */
	| INDICATION /* meta qualifier */
	| SCHEMA
        ;

        /* [ Type, val ] */
  qualifierType
	: ":" dataType array_opt defaultValue_opt
	  { type = val[2].nil? ? val[1] : CIM::Meta::Array.new(val[2],val[1])
	    result = [ type, val[3] ]
	  }
        ;

  scope
	: "," SCOPE "(" metaElements ")"
	  { result = val[3] }
        ;

  metaElements
	: metaElement
	  { result = CIM::Meta::Scope.new(val[0]) }
	| metaElements "," metaElement
	  { result = val[0] << CIM::Meta::Scope.new(val[2]) }
        ;

  metaElement
	: SCHEMA
	| CLASS
	| ASSOCIATION
	| INDICATION
	| QUALIFIER
	| PROPERTY
	| REFERENCE
	| METHOD
	| PARAMETER
	| ANY
        ;

  defaultFlavor
	: "," FLAVOR "(" flavors ")"
	  { result = val[3] }
        ;

  flavors
	: flavor
	  { result = val[0] }
	| flavors "," flavor
	  { result = val[0] << val[2] }
        ;

/***
 * instanceDeclaration
 *
 */
 
  instanceDeclaration
	: qualifierList_opt INSTANCE OF className alias_opt "{" valueInitializers "}" ";"
        ;

  valueInitializers
        : valueInitializer
        | valueInitializers valueInitializer
        ;

  valueInitializer
	: qualifierList_opt keyname "=" initializer ";"
        ;

end

---- header ----

# rbmof.rb - generated by racc

require 'strscan'
require File.dirname(__FILE__) + '/mofscanner'
require File.dirname(__FILE__) + '/rbmof_io'
require File.dirname(__FILE__) + '/../../rbcim/rbcim'
require 'pathname'

# to be used to flag @strict issues
class InvalidMofSyntax < SyntaxError
end

#class ParseError < SyntaxError
#end

---- inner ----

include Mofscanner

include Rbmof_IO

---- footer ----

require File.dirname(__FILE__) + '/rbmof_main'
