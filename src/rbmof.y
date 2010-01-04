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
	| mofProduction
	| mofSpecification mofProduction
        ;
	
  mofProduction
        : compilerDirective
	| classDeclaration
	| assocDeclaration
	| indicDeclaration
	| qualifierDeclaration
	| instanceDeclaration
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

  qualifier
	: qualifierName qualifierParameter_opt flavor_opt
        ;

  qualifiers
	: /* empty */
        | qualifiers "," qualifier
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
	: schemaName "_" IDENTIFIER /* NO whitespace ! */
	  { result = val[0]+val[1]+val[2] }
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
        | array
        ;

  array
	: "[" positiveDecimalValue_opt "]"
        ;

  positiveDecimalValue_opt
	: /* empty */
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
	: QUALIFIER qualifierName qualifierType scope defaultFlavor_opt ";"
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

  qualifierType
	: ":" dataType array_opt defaultValue_opt
	  { result = val[1] }
        ;

  scope
	: "," SCOPE "(" metaElements ")"
	  { result = val[3] }
        ;

  metaElements
	: metaElement
	| metaElements "," metaElement
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
        ;

  flavors
	: flavor
	| flavors "," flavor
        ;

/***
 * instanceDeclaration
 *
 */
 
  instanceDeclaration
	: qualifierList_opt INSTANCE OF className alias_opt "{" valueInitializer "}" ";"
        ;

  valueInitializer
	: qualifierList_opt keyname "=" initializer ";"
        ;

  /* 
   * These productions do not allow whitespace between the terms:
   */

  /* Context:
   * Schema name must not include "_" !
   */

  schemaName
	: IDENTIFIER
        ;

end

---- header ----

# rbmof.rb - generated by racc

require 'strscan'
require File.dirname(__FILE__) + '/mofscanner'
require 'pathname'

# to be used to flag @strict issues
class InvalidMofSyntax < Exception
end

---- inner ----

include Mofscanner

def initialize debug, includes
  @yydebug = debug
  @includes = includes
  @lineno = 1
  @file = nil
  @iconv = nil
  @eol = "\n"
  @fname = nil
  @fstack = []
  @in_comment = false
  @strict = :cim22  # default to strict CIM v2.2 syntax
end

def lineno
  @lineno
end

def name
  @name
end

#
# open file for parsing
#
# origin == :pragma for 'pragma include'
#

def open name, origin = nil
  $stderr.puts "open #{name} [#{origin}]"
  if name.kind_of? IO
    file = name
  else
    p = Pathname.new name
    file = nil
    @includes.each do |incdir|
      f = incdir + p
#      $stderr.puts "Trying #{f}"
      file = File.open( f ) if File.readable?( f )
      break if file
    end
    if @name && name[0,1] != "/" # not absolute
      dir = File.dirname(@name)           # try same dir as last file
      f = dir + "/" + p
      file = File.open(f) if File.readable?( f )
    end
    
    unless file
      return if origin == :pragma
      raise "Cannot open #{name}"
    end
  end
  @fstack << [ @file, @name, @lineno, @iconv, $/ ] if @file  
  @file = file
  @name = name
  @lineno = 1
  # read the byte order mark to check for utf-16 windows files
  bom = @file.read(2)
  if bom == "\376\377"
    @iconv = "UTF-16BE"
    $/ = "\0\r\0\n"
  elsif bom == "\377\376"
    @iconv = "UTF-16LE"
    $/ = "\r\0\n\0"
  else
    @file.rewind
    $/ = "\n"
  end
  @strict = :windows if @iconv
#  $stderr.puts "$/(#{$/.split('').inspect})"

end

---- footer ----

help = false
debug = false
includes = [Pathname.new "."]
moffile = nil

while ARGV.size > 0
  case opt = ARGV.shift
    when "-h":
      $stderr.puts "Ruby MOF compiler"
      $stderr.puts "rbmof [-h] [-d] [-I <dir>] [<moffile>]"
      $stderr.puts "Compiles <moffile>"
      $stderr.puts "\t-h  this help"
      $stderr.puts "\t-d  debug"
      $stderr.puts "\t-I <dir>  include dir"
      $stderr.puts "\t<moffile>  file to read (else use $stdin)"
      exit 0
    when "-d": debug = true
    when "-I": includes << Pathname.new(ARGV.shift)
    when /^-.+/:
      $stderr.puts "Undefined option #{opt}"
    else
      $stderr.puts "Multiple input files given, discarding previous #{moffile}" if moffile
      moffile = opt
  end
end

parser = Mofparser.new debug, includes

puts "Mofparser starting"

moffile = $stdin unless moffile

begin
  val = parser.parse( moffile )
  puts "Accept!"
rescue ParseError
  puts "#{parser.name}:#{parser.lineno}: #{$!}"
  exit 1
rescue InvalidMofSyntax => e
  puts "#{parser.name}:#{parser.lineno}: Syntax does not comply to #{@strict}"
  exit 1
rescue Exception => e
  puts "unexpected error #{e} ?!"
  exit 1
end
