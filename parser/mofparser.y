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

  token PRAGMA INCLUDE IDENTIFIER CLASS ASSOCIATION INDICATION
        AMENDED ENABLEOVERRIDE DISABLEOVERRIDE RESTRICTED TOSUBCLASS TOINSTANCE
	TRANSLATABLE QUALIFIER SCOPE SCHEMA PROPERTY REFERENCE
	METHOD PARAMETER FLAVOR INSTANCE
	AS REF ANY OF
	DT_VOID
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

  /* Returns a Hash of filename and MofResult */
  mofSpecification
        : /* empty */
	  { result = Hash.new }
	| mofProduction
	  { result = { @name => @result } }
	| mofSpecification mofProduction
	  { result = val[0]
	    result[@name] = @result
	  }
        ;
	
  mofProduction
        : compilerDirective
	| classDeclaration
	  { #puts "Class '#{val[0].name}'"
	    @result.classes << val[0]
	  }
	| qualifierDeclaration
	  { @result.qualifiers << val[0]
	    @qualifiers[val[0].name.downcase] = val[0]
	  }
	| instanceDeclaration
	  { @result.instances << val[0] }
        ;

/***
 * compilerDirective
 *
 */
 
  compilerDirective
	: "#" PRAGMA INCLUDE pragmaParameters_opt
	  { raise RbmofError.new(@name,@lineno,@line,"Missing filename after '#pragma include'") unless val[3]
	    open val[3], :pragma
	  }
	| "#" PRAGMA pragmaName pragmaParameters_opt
	| "#" INCLUDE pragmaParameters_opt
	  { raise StyleError.new(@name,@lineno,@line,"Use '#pragma include' instead of '#include'") unless @style == :wmi
	    raise RbmofError.new(@name,@lineno,@line,"Missing filename after '#include'") unless val[2]
	    open val[2], :pragma
	  }
        ;

  pragmaName
	: IDENTIFIER
        ;

  pragmaParameters_opt
        : /* empty */
	  { raise StyleError.new(@name,@lineno,@line,"#pragma parameter missing") unless @style == :wmi }
	| "(" pragmaParameterValues ")"
	  { result = val[1] }
	;

  pragmaParameterValues
        : pragmaParameterValue
	| pragmaParameterValues "," pragmaParameterValue
	;

  pragmaParameterValue
        : string
	| integerValue
	  { raise StyleError.new(@name,@lineno,@line,"#pragma parameter missing") unless @style == :wmi }
	| IDENTIFIER
	;

/***
 * classDeclaration
 *
 */
 
  classDeclaration
	: qualifierList_opt CLASS className alias_opt superClass_opt "{" classFeatures "}" ";"
	  { qualifiers = val[0]
	    features = val[6]
	    if qualifiers and qualifiers.include?(:association)
	      # FIXME: 'association' must be first
              # Context:
	      #
	      # The remaining qualifier list must not include
	      # the ASSOCIATION qualifier again. If the
	      # association has no super association, then at
	      # least two references must be specified! The
	      # ASSOCIATION qualifier may be omitted in
	      # sub associations.
	      result = CIM::Schema::Association.new(val[2],qualifiers,val[3],val[4],features)
	    elsif qualifiers and qualifiers.include?(:indication)
	      # FIXME: 'indication' must be first
	      # FIXME: features must not include references
	      result = CIM::Schema::Indication.new(val[2],qualifiers,val[3],val[4],features)
	    else
	      # FIXME: features must not include references
	      result = CIM::Schema::Class.new(val[2],qualifiers,val[3],val[4],features)
	    end
	  }
        ;

  classFeatures
	: /* empty */
	| classFeatures classFeature
	  { result = (val[0]||[]) << val[1] }
        ;

  classFeature
	: propertyDeclaration
	| methodDeclaration
	| referenceDeclaration /* must have association qualifier */
        ;


  qualifierList_opt
	: /* empty */
	| qualifierList
        ;

  qualifierList
	: "[" qualifier qualifiers "]"
	  { result = (val[2]||[])
	    result.unshift val[1] if val[1]
	  }
        ;

  qualifiers
	: /* empty */
	  { result = CIM::Schema::Qualifiers.new }
        | qualifiers "," qualifier
	  { result = val[0]
	    result << val[2] if val[2]
	  }
        ;
	
  qualifier
	: qualifierName qualifierParameter_opt flavor_opt
	  { # Get qualifier decl
	    qualifier = case val[0]
	      when CIM::Schema::Qualifier: val[0].definition
	      when CIM::Meta::Qualifier: val[0]
	      when String: @qualifiers[val[0].downcase]
	      else
	        nil
	      end
	    raise RbmofError.new(@name,@lineno,@line,"'#{val[0]}' is not a valid qualifier") unless qualifier
	    value = val[1]
	    raise RbmofError.new(@name,@lineno,@line,"#{value.inspect} does not match qualifier type '#{qualifier.type}'") unless qualifier.type.matches?(value)||@style == :wmi
	    # Don't propagate a boolean 'false'
	    if qualifier.type == :bool && value == false
	      result = nil
	    else
	      result = CIM::Schema::Qualifier.new(qualifier,value,val[2])
	    end
	  }
        ;

  flavor_opt
	: /* empty */
	| ":" qflavors
	  { result = val[1] }
        ;

  qflavors
        : flavor
	  { result = [ val[0] ] }
	| qflavors flavor
	  { result = val[0] << val[1] }
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
	: AMENDED | ENABLEOVERRIDE | DISABLEOVERRIDE | RESTRICTED | TOSUBCLASS | TRANSLATABLE | TOINSTANCE
	  { case val[0].to_sym
	      when :amended, :toinstance
	        raise StyleError.new(@name,@lineno,@line,"'#{val[0]}' is not a valid flavor") unless @style == :wmi
	    end
	  }
        ;

  alias_opt
	: /* empty */
	| alias
        ;

  superClass_opt
	: /* empty */
	| superClass
        ;

  className
	: IDENTIFIER /* must be <schema>_<classname> in CIM v2.x */
	  { raise ParseError.new("Class name must be prefixed by '<schema>_'") unless val[0].include?("_") || @style == :wmi }
        ;

  alias
	: AS aliasIdentifier
	  { result = val[1] }
        ;

  aliasIdentifier
	: "$" IDENTIFIER /* NO whitespace ! */
	  { result = val[1] }
        ;

  superClass
	: ":" className
	  { result = val[1] }
        ;


  propertyDeclaration
	: qualifierList_opt dataType propertyName array_opt defaultValue_opt ";"
	  { if val[3]
	      type = CIM::Meta::Array.new val[3],val[1]
	    else
	      type = val[1]
	    end
	    result = CIM::Schema::Property.new(type,val[2],val[0],val[4])
	  }
        ;
	
  referenceDeclaration
	: qualifierList_opt objectRef referenceName array_opt defaultValue_opt ";"
	  { if val[4]
	      raise StyleError.new(@name,@lineno,@line,"Array not allowed in reference declaration") unless @style == :wmi
	    end
	    result = CIM::Schema::Property.new(val[1],val[2],val[0],val[5]) }
        ;

  methodDeclaration
	: qualifierList_opt dataType methodName "(" parameterList_opt ")" ";"
	  { result = CIM::Schema::Method.new(val[1],val[2],val[0],val[4]) }
        ;

  propertyName
	: IDENTIFIER
	| PROPERTY
	  { # tmplprov.mof has 'string Property;'
	    raise StyleError.new(@name,@lineno,@line,"Invalid keyword '#{val[0]}' used for property name") unless @style == :wmi
	  }
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
	| DT_VOID
	  { raise StyleError.new(@name,@lineno,@line,"'void' is not a valid datatype") unless @style == :wmi }
        ;

  objectRef
	: className
	  { # WMI uses class names as data types (without REF ?!)
	    raise StyleError.new(@name,@lineno,@line,"Expected 'ref' keyword after classname '#{val[0]}'") unless @style == :wmi
	    result = CIM::Meta::Reference.new val[0]
	  }

	| className REF
	  { result = CIM::Meta::Reference.new val[0] }
        ;

  parameterList_opt
	: /* empty */
        | parameterList
        ;
	
  parameterList
	: parameter parameters
	  { result = (val[1]||[]).unshift val[0] }
        ;

  parameters
	: /* empty */
	| parameters "," parameter
	  { result = (val[0]||[]) << val[2] }
        ;

  parameter
	: qualifierList_opt typespec parameterName array_opt parameterValue_opt
	  { if val[3]
	      type = CIM::Meta::Array.new val[3], val[1]
	    else
	      type = val[1]
	    end
	    result = CIM::Schema::Property.new(type,val[2],val[0])
	  }
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

  parameterValue_opt
        : /* empty */
	| defaultValue
	  { raise "Default parameter value not allowed in syntax style '{@style}'" unless @style == :wmi }
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
	  { result = val[1] }
        ;

  initializer
	: constantValue
	| arrayInitializer
	| referenceInitializer
        ;

  arrayInitializer
	: "{" constantValues "}"
	  { result = val[2] }
        ;

  constantValues
	: /* empty */
	| constantValue
	  { result = [ val[0] ] }
	| constantValues "," constantValue
	  { result = val[0] << val[2] }
        ;

  constantValue
	: integerValue
	| realValue
	| charValue
	| string
	| booleanValue
	| nullValue
	| instance
	  { raise "Instance as property value not allowed in syntax style '{@style}'" unless @style == :wmi }
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
	  { qname = val[1]
	    if qname.is_a?(CIM::Meta::Qualifier)
	      raise "Wrong default type for #{qname}" unless qname.type.matches?(val[2][0])
	      raise "Wrong default value for #{qname}" unless qname.type.matches?(val[2][1])
	      result = qname
	    else
	      result = CIM::Meta::Qualifier.new( val[1], val[2][0], val[2][1], val[3], val[4])
	    end
	  }
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

        /* [type, Variant] */
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
	: instance ";"
        ;

  instance
	: qualifierList_opt INSTANCE OF className alias_opt "{" valueInitializers "}"
        ;

  valueInitializers
        : valueInitializer
        | valueInitializers valueInitializer
        ;

  valueInitializer
	: qualifierList_opt keyname "=" initializer ";"
	| qualifierList_opt keyname ";"
	  { raise "Instance property '#{val[1]} must have a value" unless @style == :wmi }
        ;

end # class Mofparser

---- header ----

# rbmof.rb - generated by racc

require 'strscan'
require File.dirname(__FILE__) + '/../../rbcim/rbcim'
require File.dirname(__FILE__) + '/mofresult'
require File.dirname(__FILE__) + '/mofscanner'
require File.dirname(__FILE__) + '/parse_helper'

---- inner ----

#
# Initialize Mofparser
#  Mofparser.new options = {}
#
#  options -> Hash of options
#    :debug -> bool
#    :includes -> array of include dirs
#    :style -> :cim or :wmi
#
def initialize options = {}
  @yydebug = options[:debug]
  @includes = options[:includes] || []
  @quiet = options[:quiet]
  @style = options[:style] || :cim  # default to style CIM v2.2 syntax
  
  @lineno = 1
  @file = nil
  @iconv = nil
  @eol = "\n"
  @fname = nil
  @fstack = []
  @in_comment = false
  @seen_files = []
  @qualifiers = {}
end

#
# Make options hash from argv
#
# returns [ files, options ]
#

  def self.argv_handler name, argv
    files = []
    options = { :namespace => "" }
    while argv.size > 0
      case opt = argv.shift
      when "-h":
	$stderr.puts "Ruby MOF compiler"
	$stderr.puts "#{name} [-h] [-d] [-I <dir>] [<moffiles>]"
	$stderr.puts "Compiles <moffile>"
	$stderr.puts "\t-d  debug"
	$stderr.puts "\t-h  this help"
	$stderr.puts "\t-I <dir>  include dir"
	$stderr.puts "\t-n <namespace>"
	$stderr.puts "\t-s <style>  syntax style (wmi,cim)"
	$stderr.puts "\t-q  quiet"
	$stderr.puts "\t<moffiles>  file(s) to read (else use $stdin)"
	exit 0
      when "-s": options[:style] = argv.shift.to_sym
      when "-d": options[:debug] = true
      when "-q": options[:quiet] = true
      when "-I"
	options[:includes] ||= []
	dirname = argv.shift
	unless File.directory?(dirname)
	  files << dirname
	  dirname = File.dirname(dirname)
	end
	options[:includes] << Pathname.new(dirname)
      when "-n": options[:namespace] = argv.shift
      when /^-.+/:
	$stderr.puts "Undefined option #{opt}"
      else
	files << opt
      end
    end
    [ files, options ]
  end

include ParseHelper
include Mofscanner

---- footer ----
