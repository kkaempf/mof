#
# mofscanner.rb
#
# A scanner module for MOF files
# to extend the Scanner class (via include)
#
# functions offered:
#  parse( file ) : start parsing of file
#  next_token    : return next [token,value] pair
#  on_error      : report error
#
# Class variables:
#
# @file: file being scanned
# @name: name of file
# @lineno: current line number in file (for error reports)
# @iconv: non-nil if iconv needed (i.e. Windows utf-16 mof files)
# @fstack: stack of [ @file, @name, @lineno, @iconv ] for open files (to handle includes)
# @q: Queue of [token,value] pairs, [false,false] denotes EOF
#

require 'iconv'

module Mofscanner
  def fill_queue
    if @file.eof?
#      $stderr.puts "eof ! #{@fstack.size}"
      @file.close unless @file == $stdin
      unless @fstack.empty?
	@file, @name, @lineno, @iconv, $/ = @fstack.pop
#	$stderr.puts "fill! #{@fstack.size}, #{@name}@#{@lineno}"
        return fill_queue
      end
      @q.push [false, false]
      return false
    end
    @line = @file.gets
    return true unless @line
    @lineno += 1

#    $stderr.puts "fill_queue(#{@line.split('').inspect})"
    @line.chomp!  # remove $/
    @line = Iconv.conv( "ISO-8859-1", @iconv, @line ) if @iconv
    $stderr.puts "scan(#{@line})" unless @quiet
    scanner = StringScanner.new(@line)

    until scanner.empty?
#      $stderr.puts "#{@q.size}:\"#{scanner.rest}\""
      if @in_comment
	if scanner.scan(%r{.*\*/})
	  @in_comment = false
	else
	  break
	end
      end

      case
      when scanner.scan(/\s+/)
	next        # ignore space
	
      when m = scanner.scan(/\n+/)
	@lineno += m.size
	next        # ignore newlines

      when m = scanner.scan(%r{/\*})
        @in_comment = true
	
      when m = scanner.scan(%r{//.*})
	next        # c++ style comment
	
      when m = scanner.scan(%r{[(){}\[\],;\$#:=]})
	@q.push [m, m]

      when m = scanner.scan(%r{[123456789]\d*})
	@q.push [:positiveDecimalValue, m.to_i]
     
      # decimalValue = [ "+" | "-" ] ( positiveDecimalDigit *decimalDigit | "0" )
      # decimalDigit = "0" | positiveDecimalDigit
      when m = scanner.scan(%r{(\+|-)?\d+})
	@q.push [:decimalValue, m.to_i]

      # hexValue = [ "+" | "-" ] [ "0x" | "0X"] 1*hexDigit
      #      hexDigit = decimalDigit | "a" | "A" | "b" | "B" | "c" | "C" | "d" | "D" | "e" | "E" | "f" | "F"
      when m = scanner.scan(%r{(\+|-)?(0x|0X)([0123456789]|[abcdef]|[ABCDEF])+})
	@q.push [:hexValue, m.to_i]

      # octalValue = [ "+" | "-" ] "0" 1*octalDigit
      when m = scanner.scan(%r{(\+|-)?0[01234567]+})
	@q.push [:octalValue, m.to_i]

      #	binaryValue = [ "+" | "-" ] 1*binaryDigit ( "b" | "B" )
      when m = scanner.scan(%r{(\+|-)?(0|1)(b|B)})
	@q.push [:binaryValue, m.to_i]
	
      #      realValue = [ "+" | "-" ] *decimalDigit "." 1*decimalDigit
      #      [ ( "e" | "E" ) [ "+" | "-" ] 1*decimalDigit ]

      when m = scanner.scan(%r{(\+|-)?\d*\.\d+})
	@q.push [:realValue, m.to_f]

      #      charValue = // any single-quoted Unicode-character, except single quotes
      
      when m = scanner.scan(%r{\'([^\'])\'})
	@q.push [:charValue, scanner[1]]

      #      stringValue = 1*( """ *ucs2Character """ )
      #      ucs2Character = // any valid UCS-2-character

      when m = scanner.scan(%r{\"([^\\\"]*)\"})
	@q.push [:stringValue, scanner[1]]

      # string with embedded backslash
      when m = scanner.scan(%r{\"([^\\]|(\\.))*\"})
#	$stderr.puts ":string(#{scanner[1]})"
	@q.push [:stringValue, scanner[1]]

      when m = scanner.scan(%r{\w+})
	case m.downcase
	when "any": @q.push [:ANY, m]
	when "as": @q.push [:AS, nil]
	when "association": @q.push [:ASSOCIATION, CIM::Meta::Qualifier.new(m.downcase)]
	when "class": @q.push( [:CLASS, m] )
	when "disableoverride": @q.push [:DISABLEOVERRIDE, CIM::Meta::Flavors.new(m)]
	when "boolean": @q.push [:DT_BOOL, CIM::Meta::Type.new(:bool)]
	when "char16": @q.push [:DT_CHAR16, CIM::Meta::Type.new(m)]
	when "datetime": @q.push [:DT_DATETIME, CIM::Meta::Type.new(m)]
	when "real32": @q.push [:DT_REAL32, CIM::Meta::Type.new(m)]
	when "real64": @q.push [:DT_REAL64, CIM::Meta::Type.new(m)]
	when "sint16": @q.push [:DT_SINT16, CIM::Meta::Type.new(m)]
	when "sint32": @q.push [:DT_SINT32, CIM::Meta::Type.new(m)]
	when "sint64": @q.push [:DT_SINT64, CIM::Meta::Type.new(m)]
	when "sint8": @q.push [:DT_SINT8, CIM::Meta::Type.new(m)]
	when "string": @q.push [:DT_STR, CIM::Meta::Type.new(m)]
	when "uint16": @q.push [:DT_UINT16, CIM::Meta::Type.new(m)]
	when "uint32": @q.push [:DT_UINT32, CIM::Meta::Type.new(m)]
	when "uint64": @q.push [:DT_UINT64, CIM::Meta::Type.new(m)]
	when "uint8": @q.push [:DT_UINT8, CIM::Meta::Type.new(m)]
	when "enableoverride": @q.push [:ENABLEOVERRIDE, CIM::Meta::Flavors.new(m)]
	when "false": @q.push [:booleanValue, false]
	when "flavor": @q.push [:FLAVOR, nil]
	when "indication": @q.push [:INDICATION, CIM::Meta::Qualifier.new(m.downcase)]
	when "instance": @q.push [:INSTANCE, m.to_sym]
	when "method": @q.push [:METHOD, m]
	when "null": @q.push [:nullValue, CIM::Meta::Variant.new(:null,nil)]
	when "of": @q.push [:OF, nil]
	when "parameter": @q.push [:PARAMETER, m]
	when "pragma": @q.push [:PRAGMA, nil]
	when "property": @q.push [:PROPERTY, m]
	when "qualifier": @q.push [:QUALIFIER, m]
	when "ref": @q.push [:REF, nil]
	when "reference": @q.push [:REFERENCE, m]
	when "restricted": @q.push [:RESTRICTED, CIM::Meta::Flavors.new(m)]
	when "schema": @q.push [:SCHEMA, m]
	when "scope": @q.push [:SCOPE, nil]
	when "toinstance": @q.push [:TOINSTANCE, CIM::Meta::Flavors.new(m)]
	when "tosubclass": @q.push [:TOSUBCLASS, CIM::Meta::Flavors.new(m)]
	when "translatable": @q.push [:TRANSLATABLE, CIM::Meta::Flavors.new(m)]
	when "true": @q.push [:booleanValue, true]
	else
	  @q.push( [:IDENTIFIER, m] )
	end # case m.downcase
      
      else
	raise CIM::Schema::ScannerError.new( @name, @lineno, @line, scanner.rest ) unless scanner.rest.empty?
      end # case
    end # until scanner.empty?
#    $stderr.puts "scan done, @q #{@q.size} entries"
    true
  end

  def parse( files, style, quiet )
    @style = style
    @quiet = quiet
    # open files in reverse order
    #  open() will stack them and parse starts in right order
    files.reverse_each do |file|
      open file, :argv
#      puts "Opened #{file} as #{@file} @ #{@fstack.size}"
    end
    @q = []
    do_parse
  end

  def next_token
    while @q.empty?
      break unless fill_queue 
    end
#    $stderr.puts "next_token #{@q.first.inspect}"
    @q.shift
  end
  
  # stack_size, last_token, value_stack
  # stack[0] == Result
  def on_error token, token_value, value_stack
    raise CIM::Schema::ParserError.new @name,@lineno,@line,token,token_value,value_stack
  end

end # module
