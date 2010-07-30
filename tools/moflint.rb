#
# moflint.rb
#
# MOF syntax checker
#  and Mofparser tester
#
require 'pathname'
require File.dirname(__FILE__) + "/../parser/mofparser"

moffiles, options = Mofparser.argv_handler "moflint", ARGV
options[:style] ||= :cim;
options[:includes] ||= []
options[:includes].unshift(Pathname.new ".")
options[:includes].unshift(Pathname.new "/usr/share/mof/cim-current")

moffiles.unshift "qualifiers.mof" unless moffiles.include? "qualifiers.mof"

parser = Mofparser.new options

begin
  result = parser.parse moffiles
rescue Exception => e
  parser.error_handler e
  exit 1
end

result.each do |name,res|
  puts "/*=============== #{name} ===================*/\n"
  puts res
end
