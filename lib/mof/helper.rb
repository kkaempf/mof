#
# parse_helper.rb
#
# Helper functions for mofparser
#
#

module MOF
module Helper

  require 'pathname'
  
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
      file = nil
      if name[0,1] == "/"
	# absolute path
	file = File.open( name ) if File.readable?( name )
      else
	# relative path, try each include dir
	@includes.each do |incdir|
	  f = File.join(incdir, name)
#	  $stderr.puts "Trying '#{f}': #{File.exists?(f)}"
          f << ".mof" unless File.readable?( f )
          file = File.open( f ) rescue nil
	  break if file
	  #	$stderr.puts "\tNope"
	end
      end
      # still not found in include dirs ?
      unless file
	# might be relative to last path
	if @name && @name[0,1] != "/" # not absolute
	  dir = File.dirname(@name)           # try same dir as last file
	  f = File.join(dir, name)
	  file = File.open(f) if File.readable?( f )
	end
      end
      # no luck opening the file, give up
      unless file
	return if origin == :pragma # silently ignore failing pragmas
	$stderr.puts "'#{name}' not found, searched in"
	@includes.each { |incdir| $stderr.puts "  #{incdir}" }
	raise "Cannot open #{name}"
      end
    end
    @fstack << [ @file, @name, @lineno, @iconv, $/, @result ] if @file  
    @file = file
    @name = name
    @lineno = 1
    @result = MOF::Result.new
    # read the byte order mark to check for utf-16 windows files
    bom = @file.read(2)
    if bom == "\376\377"
      @iconv = "UTF-16BE"
      $/ = "\0\r\0\n"
    elsif bom == "\377\376"
      @iconv = "UTF-16LE"
      $/ = "\r\0\n\0"
    elsif ! has_valid_utf8(@name)
      $stderr.puts "#{name} contains invalid UTF-8, treating as ISO-8859-1"
      @iconv = "ISO-8859-1"
      @file.rewind
      $/ = "\n"
    else
      @file.rewind
      @iconv = nil
      $/ = "\n"
    end
    @style = :wmi if @iconv
    #  $stderr.puts "$/(#{$/.split('').inspect})"

  end

  def has_valid_utf8 name
    valid = true

    begin
      # throws on invalid byte sequences such as 0x91 / 0x92 (smartquotes)
      # and 0xAE (copyright) that may be present in Microsoft ISO-8859-1 MOFs
      File.open(name, 'r:UTF-8', &:read).split('') << ''
    rescue => e
      if e.class == ArgumentError && e.message == 'invalid byte sequence in UTF-8'
        valid = false
      end
    end

    valid
  end
  
  #----------------------------------------------------------
  # Error classes
  #
  
  # to be used to flag @style issues
  class Error < ::SyntaxError
    attr_reader :name, :lineno, :line, :msg
    def initialize name, lineno, line, msg
      @name,@lineno,@line,@msg = name, lineno, line, msg
    end
    def to_s
      "#{@name}:#{@lineno}: #{line}\n#{msg}"
    end
  end
  
  class ScannerError < Error
    def initialize name, lineno, line, msg
      super name,lineno,line,"Unrecognized '#{msg}'"
    end
  end
  
  class ParserError < Error
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
	when String, NilClass
	  s = s.inspect
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
  
  class StyleError < Error
  end
  
  public
  #
  # error_handler
  #
  def error_handler e
    $stderr.puts "*** #{@name}:#{@lineno}:"
    case e
    when StyleError
      $stderr.puts "\t Syntax does not comply to '#{self.style}' style"
    when ScannerError
      $stderr.puts "\t ScannerError: #{$!}"
    when ParserError
      $stderr.puts "\t ParserError: #{$!}"
    when Error
      $stderr.puts "\t Error: #{$!}"
    else
      $stderr.puts "\t Exception: #{$!}[#{$!.class}]"
      $stderr.puts $@
    end
  end
  
end # module Helper
end # module MOF
