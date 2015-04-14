#
# scanner.rb
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

module MOF
module Scanner

  require 'iconv' unless String.method_defined? :encode

  def fill_queue
    if @file.closed? || @file.eof?
#      $stderr.puts "eof ! #{@fstack.size}"
      unless @file.closed?
        @file.close unless @file == $stdin
      end
      unless @fstack.empty?
	@file, @name, @lineno, @iconv, $/, @result = @fstack.pop
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
    if @iconv
      if String.method_defined? encode
        @line = @line.encode( "ISO-8859-1", @iconv )
      else
        @line = Iconv.conv( "ISO-8859-1", @iconv, @line )
      end
    end
#    $stderr.puts "scan(#{@line})" unless @quiet
    scanner = StringScanner.new(@line)

    until scanner.eos?
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

      when m = scanner.scan(%r{[123456789]\d*})
	@q.push [:positiveDecimalValue, m.to_i]
     
      # decimalValue = [ "+" | "-" ] ( positiveDecimalDigit *decimalDigit | "0" )
      # decimalDigit = "0" | positiveDecimalDigit
      when m = scanner.scan(%r{(\+|-)?\d+})
	@q.push [:decimalValue, m.to_i]

      #      charValue = // any single-quoted Unicode-character, except single quotes
      
      when m = scanner.scan(%r{\'([^\'])\'})
	@q.push [:charValue, scanner[1]]

      #      stringValue = 1*( """ *ucs2Character """ )
      #      ucs2Character = // any valid UCS-2-character

#      when m = scanner.scan(%r{\"([^\\\"]*)\"})
#	@q.push [:stringValue, scanner[1]]

      # string with embedded backslash
      when m = scanner.scan(%r{\"(([^\\\"]|(\\[nrt\(\)/\"\'\\]))*)\"})
#	$stderr.puts "scan(#{@line})" unless @quiet
#	$stderr.puts ":string(#{scanner[1]})"
	@q.push [:stringValue, scanner[1]]

      when m = scanner.scan(%r{\w+})
	case m.downcase
	when "amended" then @q.push [:AMENDED, m]
	when "any" then @q.push [:ANY, m]
	when "as" then @q.push [:AS, nil]
	when "association" then @q.push [:ASSOCIATION, m]
	when "class" then @q.push( [:CLASS, m] )
	when "disableoverride" then @q.push [:DISABLEOVERRIDE, m]
	when "void" then @q.push [:DT_VOID, CIM::Type.new(:void)]
	when "boolean" then @q.push [:DT_BOOLEAN, CIM::Type.new(:boolean)]
	when "char16" then @q.push [:DT_CHAR16, CIM::Type.new(m)]
	when "datetime" then @q.push [:DT_DATETIME, CIM::Type.new(m)]
	when "real32" then @q.push [:DT_REAL32, CIM::Type.new(m)]
	when "real64" then @q.push [:DT_REAL64, CIM::Type.new(m)]
	when "sint16" then @q.push [:DT_SINT16, CIM::Type.new(m)]
	when "sint32" then @q.push [:DT_SINT32, CIM::Type.new(m)]
	when "sint64" then @q.push [:DT_SINT64, CIM::Type.new(m)]
	when "sint8" then @q.push [:DT_SINT8, CIM::Type.new(m)]
	when "string" then @q.push [:DT_STR, CIM::Type.new(m)]
	when "uint16" then @q.push [:DT_UINT16, CIM::Type.new(m)]
	when "uint32" then @q.push [:DT_UINT32, CIM::Type.new(m)]
	when "uint64" then @q.push [:DT_UINT64, CIM::Type.new(m)]
	when "uint8" then @q.push [:DT_UINT8, CIM::Type.new(m)]
	when "enableoverride" then @q.push [:ENABLEOVERRIDE, m]
	when "false" then @q.push [:booleanValue, false]
	when "flavor" then @q.push [:FLAVOR, nil]
	when "include" then @q.push [:INCLUDE, nil]
	when "indication" then @q.push [:INDICATION, m]
	when "instance" then @q.push [:INSTANCE, m]
	when "method" then @q.push [:METHOD, m]
	when "null" then @q.push [:nullValue, CIM::Variant.new(:null,nil)]
	when "of" then @q.push [:OF, nil]
	when "parameter" then @q.push [:PARAMETER, m]
	when "pragma" then @q.push [:PRAGMA, nil]
	when "property" then @q.push [:PROPERTY, m]
	when "qualifier" then @q.push [:QUALIFIER, m]
	when "ref" then @q.push [:REF, nil]
	when "reference" then @q.push [:REFERENCE, m]
	when "restricted" then @q.push [:RESTRICTED, m]
	when "schema" then @q.push [:SCHEMA, m]
	when "scope" then @q.push [:SCOPE, nil]
	when "toinstance" then @q.push [:TOINSTANCE, m]
	when "tosubclass" then @q.push [:TOSUBCLASS, m]
	when "translatable" then @q.push [:TRANSLATABLE, m]
	when "true" then @q.push [:booleanValue, true]
	else
	  @q.push( [:IDENTIFIER, m] )
	end # case m.downcase
      
      else
	require File.join(File.dirname(__FILE__), 'helper')
	raise MOF::Helper::ScannerError.new( @name, @lineno, @line, scanner.rest ) unless scanner.rest.empty?
      end # case
    end # until scanner.eos?
#    $stderr.puts "scan done, @q #{@q.size} entries"
    true
  end

  def parse files
    return unless files
    return if files.empty?
    # open files in reverse order
    #  open() will stack them and parse starts in right order
    files.reverse_each do |file|
      open file, :argv
#      puts "Opened #{file} as #{@file} @ #{@fstack.size}"
    end
    @q = [] # init the token queue
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
    require File.join(File.dirname(__FILE__), 'helper')
    raise MOF::Helper::ParserError.new @name,@lineno, @line, token,token_value,value_stack
  end

end # module Scanner
end # module MOF
