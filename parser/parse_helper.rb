#
# mofparser.rb
#
# A mof parsing class
#
# Defines CIM::Schema::Mofparser
#
#

module ParseHelper

  def lineno
    @lineno
  end
  
  def name
    @name
  end
  
  def style
    @style
  end
  
  #
  # open file for parsing
  #
  # origin == :pragma for 'pragma include'
  #
  private
  def open name, origin = nil
    return if @seen_files.include? name
    @seen_files << name
    if name.kind_of? IO
      file = name
    else
      $stderr.puts "open #{name} [#{origin}]" unless @quiet
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
      @iconv = nil
      $/ = "\n"
    end
    @style = :wmi if @iconv
    #  $stderr.puts "$/(#{$/.split('').inspect})"
    
  end
  
  #----------------------------------------------------------
  # Error classes
  #
  
  # to be used to flag @style issues
  class RbmofError < ::SyntaxError
    attr_reader :name, :lineno, :line, :msg
    def initialize name, lineno, line, msg
      @name,@lineno,@line,@msg = name, lineno, line, msg
    end
    def to_s
      "#{@name}:#{@lineno}: #{line}\n#{msg}"
    end
  end
  
  class ScannerError < RbmofError
    def initialize name, lineno, line, msg
      super name,lineno,line,"Unrecognized '#{msg}'"
    end
  end
  
  class ParserError < RbmofError
    attr_reader :line, :token, :token_value, :stack
    def initialize name, lineno, line, token, token_value, stack
      @token,@token_value,@stack = token, token_value, stack
      super name,lineno,line,""
    end
    def to_s
      ret = "#{super}\tnear token #{@token_value.inspect}\n"
      ret << "\tStack [#{@stack.size}]:\n"
      idx = stack.size-1
      (1..12).each do |i|
	s = stack[idx]
	c = s.class
	case s
	when String, NilClass: s = s.inspect
	else
	  s = s.to_s
	end
	if s.size > 80
	  ret << "[#{i}:#{c}]\t#{s[0,80]}..."
	else
	  ret << "[#{i}:#{c}]\t#{s}"
	end
	ret << "\n"
	idx -= 1
	break if idx < 0
      end
      ret
    end
  end
  
  class StyleError < RbmofError
  end
  
  public
  #
  # error_handler
  #
  def error_handler e
    case e
    when StyleError
      $stderr.puts "#{e.name}:#{e.line}: Syntax does not comply to '#{self.style}' style"
    when ScannerError
      $stderr.puts "*** ScannerError: #{$!}"
    when ParserError
      $stderr.puts "*** ParserError: #{$!}"
    when RbmofError
      $stderr.puts "*** Error: #{$!}"
    else
      $stderr.puts "*** Exception: #{$!}[#{$!.class}]"
      $stderr.puts $@
    end
  end
  
end # module ParseHelper
