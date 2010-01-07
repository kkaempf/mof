require File.dirname(__FILE__) + '/cim_schema'

module Rbmof_IO

def initialize debug, includes
  @yydebug = debug
  @includes = includes
  @lineno = 1
  @file = nil
  @iconv = nil
  @eol = "\n"
  @fname = nil
  @fstack = []
  @schema = CIM::Schema.new  
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
    @iconv = nil
    $/ = "\n"
  end
  @strict = :windows if @iconv
#  $stderr.puts "$/(#{$/.split('').inspect})"

end
end # Rbmof_IO
