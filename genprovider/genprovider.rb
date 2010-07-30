#!/usr/bin/ruby
#
# genprovider
#
#  Generate Ruby provider templates for use with cmpi-bindings
#
# == Usage
#
# genprovider.rb [-d] [-h] [-q] [-I <includedir>] [-o <output>] <moffile> [<moffile> ...]
#
# -d:
#   turn on debugging
# -h:
#   show (this) help
# -q:
#   be quiet
# -I <includedir>
#   additional include directories to search
# -o <output>
#   provider file to write
# <moffile>
#   .mof files to read
#
require 'rdoc/usage'

require "rexml/document"
require 'pathname'
require 'fileutils'
require File.dirname(__FILE__) + "/../parser/mofparser"

module CIM
  module Meta
    class Feature
      # parameters will be non-nil for a Method
      def to_html div, parameters = nil
	tr = div.add_element "tr", "class" => "feature_qualifiers_line"
	Schema::Qualifier.array_to_html @qualifiers, tr.add_element("td", "class" => "feature_qualifiers", "colspan" => "4")
	tr = div.add_element "tr", "class" => "feature_line"
	td = tr.add_element "td", "class" => "feature_type"
	case @type
	when CIM::Meta::Array
	  td.text = @type.type.to_s
	else
	  td.text = @type.to_s
	end
	td = tr.add_element "td", "class" => "feature_name"
	td.text = @name
	td.text << "[]" if @type.is_a? CIM::Meta::Array
	td = tr.add_element "td", "class" => "feature_parameters"
	first = true
	if parameters
	  t = "("
	  parameters.each do |p|
	    if first
	      first = false
	    else
	      t << ", "
	    end
	    t << "[IN] " if p.qualifiers.include? :in
	    t << "[OUT] " if p.qualifiers.include? :out
	    t << "#{p.name}"
	  end
	  td.text = t + ")"
	else
	  td.text = ""
        end
	td = tr.add_element "td", "class" => "feature_default"
	td.text = @default ? " = #{@default}" : "" 
	if parameters
	  Schema::Qualifier.array_to_html parameters, div.add_element("tr", "class" => "feature_parameters")
	end
      end
    end
  end
  
  module Schema
    
    class Method
      def to_html div
	super div, @parameters?@parameters:[]
      end
    end
    
    class Qualifier
      def self.array_to_html qualifiers, div
	return unless qualifiers
	return if qualifiers.empty?
	container = div.add_element "table", "class" => "qualifiers_container"
	head = container.add_element("tr").add_element("td", "class" => "qualifiers_container_head", "colspan" => "2")
	head.text = "Qualifiers"
	body = container.add_element("tr", "class" => "qualifiers_container_body")
	body.add_element("td", "class" => "qualifiers_container_left")
	body_right = body.add_element("td").add_element("table", "class" => "qualifiers_container_right")
	# Qualifiers
	qualifiers.each do |q|
	  q.to_html body_right
	end
      end

      def to_html div
	tr = div.add_element "tr", "class" => "qualifier_line"
	td = tr.add_element "td", "class" => "qualifier_name"
	td.text = @definition.name.capitalize
	td = tr.add_element "td", "class" => "qualifier_value"
	if @value
	  case @value
	  when Array
	    td.text = "{ #{@value.join(', ')} }"
	  when String
	    @value.split("\\n").each do |l|
	      divc = td.add_element "div", "style" => "clear : both"
	      divc.text = l.gsub "\\\"", '"'
	    end
	  else
	    td.text = @value
	  end
	end
	td = tr.add_element "td", "class" => "qualifier_flavor"
	td.text = @flavor ? @flavor.to_s : "" 
      end
    end
    
    class Property
      def self.array_to_html properties, div
	return unless properties
	return if properties.empty?
	container = div.add_element "table", "class" => "properties_container"
	head = container.add_element("tr").add_element("td", "class" => "properties_container_head", "colspan" => "2")
	head.text = "Properties"
	body = container.add_element("tr", "class" => "properties_container_body")
	body.add_element("td", "class" => "properties_container_left")
	body_right = body.add_element("td").add_element("table", "class" => "properties_container_right")
	# Properties
	properties.each do |p|
	  p.to_html body_right
	end
      end
    end
    
    class Class
      def to_html body
	h1 = body.add_element "h1"
	h1.text = name
	
	table = body.add_element "table", "class" => "class_container"
	
	tr = table.add_element "tr", "class" => "class_header"
	td = tr.add_element "td", "class" => "class_name"
	td.text = name
	if @alias_name
	  td = tr.add_element "td", "class" => "class_alias"
	  td.text = " as #{@alias_name}"
	end
	if @superclass
	  td = tr.add_element "td", "class" => "parent_name"
	  td.text = ": " 
	  href = td.add_element "a", "href" => "#{@superclass}.html"
	  href.text = @superclass
	end
	
	# Class qualifiers
	
	Qualifier.array_to_html @qualifiers, table.add_element("tr", "class" => "qualifiers_row").add_element("td", "colspan" => "2")
	
	# Class properties (features)
	
	Property.array_to_html @features, table.add_element("tr", "class" => "properties_row").add_element("td", "colspan" => "2")
      end
    end
  end
end

#-------------------------------------------------------------

class Output
 private
  def indent
    @file.write " " * @depth * @indent
  end
 public
  def initialize file
    @file = file
    @indent = 0
    @wrap = 75 # wrap at this column
    @depth = 2 # indent depth
  end
  def inc
    @indent += 1
    self
  end
  def dec
    @indent -= 1
    @indent = 0 if @indent < 0
    self
  end
  def write str
    @file.write str
  end
  def puts str=""
    indent
    @file.puts str
    self
  end
  def comment str=nil
    if str =~ /\\n/
      comment $`
      comment $'
      return
    end
    wrap = @wrap - (@depth * @indent + 2)
    if str && str.size > wrap # must wrap
#      puts "#{str.size} > #{wrap}"
      pivot = wrap
      while pivot > 0 && str[pivot] != 32 # search space left of wrap
        pivot -= 1
      end
      if pivot == 0 # no space left of wrap
        pivot = wrap
        while pivot < str.size && str[pivot] != 32 # search space right of wrap
          pivot += 1
        end
      end
      if 0 < pivot && pivot < str.size
#        puts "-wrap @ #{pivot}-"
        comment str[0,pivot]
	comment str[pivot+1..-1]
	return
      end
    end
    indent
    @file.write "#"
    @file.write " #{str}" if str
    @file.puts
    self
  end
  def printf format, *args
    indent
    Kernel.printf @file, format, *args
    self
  end
end

def mkdescription out, element
  p = element.qualifiers["description", :string]
  out.comment p.value if p
end

def mkdef out, feature
  case feature
  when CIM::Schema::Property: out.comment "Property"
  when CIM::Schema::Reference: out.comment "Reference"
  when CIM::Schema::Method: out.comment "Method"
  else
    raise "Unknown feature class #{feature.class}"
  end
  mkdescription out, feature
#  puts feature.name
  name = feature.name.gsub(/[A-Z]+/) do |match|
#    puts "#{$`}<#{match}>#{$'}"
    if $`.empty? || $`[-1,1] == "_" || $'.empty? || $'[0,1] == "_"
      match.downcase
    else
      "_#{match.downcase}"
    end
  end
  
  out.printf "def %s", name
  if feature.method?
    out.write " ("
    first = true
    feature.parameters.each do |p|
      if first
	first = false
      else
	out.write ", "
      end
      out.write p.name
      out.write "_out" if p.qualifiers.include? :out
    end
    out.write ")"
  end
  out.puts.inc
end

#
# generate provider code for property
#

def property2provider property, out
  mkdef out, property
  out.dec.puts("end")
end

#
# generate provider code for reference
#

def reference2provider reference, out
  mkdef out, reference
  out.dec.puts("end")
end

#
# generate provider code for method
#

def method2provider method, out
  mkdef out, method
  out.dec.puts("end")
end

#
# generate provider code for features matching match
#

def features2provider features, out, match
  features.each do |f|
    next unless f.instance_of? match
    case f
    when CIM::Schema::Property: property2provider f, out
    when CIM::Schema::Reference: reference2provider f, out
    when CIM::Schema::Method: method2provider f, out
    else
      raise "Unknown feature class #{f.class}"
    end
  end
end

#
# generate provider code for class 'c'
#

def class2provider c, file = $stdout
  out = Output.new file
  #
  # Header: class name, provider name (Class qualifier 'provider')
  #
  providername = c.name
  p = c.qualifiers["provider", :string]

  providername = p.value if p
  out.comment
  out.comment "Provider #{providername} for class #{c.name}"
  out.comment
  out.puts("module Cmpi").inc

  mkdescription out, c
  #
  # baseclass and interfaces
  #
  providertypes = []
  providertypes << "InstanceProvider" if c.instance?
  providertypes << "MethodProvider" if c.method?
  providertypes << "AssociationProvider" if c.association?
  providertypes << "IndicationProvider" if c.indication?

  raise "Unknown provider type" if providertypes.empty?

  out.puts("class #{c.name}Provider < #{providertypes.shift}").inc
  providertypes.each do |t|
    out.puts "include #{t}IF"
  end
  # normal properties
  features2provider c.features, out, CIM::Schema::Property
  # reference properties
  features2provider c.features, out, CIM::Schema::Reference
  # methods
  features2provider c.features, out, CIM::Schema::Method
  out.dec.puts("end") # class
  out.dec.puts "end" # module
end

#------------------------------------------------------------------

cim_current = "/usr/share/mof/cim-current"

moffiles, options = Mofparser.argv_handler "genprovider", ARGV
RDoc::usage if moffiles.empty?

options[:style] ||= :cim;
options[:includes] ||= []
options[:includes].unshift(Pathname.new ".")
options[:includes].unshift(Pathname.new cim_current)

Dir.new(cim_current).each do |d|
  next if d[0,1] == "."
  fullname = File.join(cim_current, d)
  next unless File.stat(fullname).directory?
  options[:includes].unshift(Pathname.new fullname)
end

moffiles.unshift "qualifiers.mof" unless moffiles.include? "qualifiers.mof"
#moffiles.unshift "qualifiers_optional.mof" unless moffiles.include? "qualifiers_optional.mof"

parser = Mofparser.new options

begin
  result = parser.parse moffiles
rescue Exception => e
  parser.error_handler e
  exit 1
end

exit 0 unless result

#
# collect classes to find parent classes
#
classes = {}
result.each do |name, res|
  res.classes.each do |c|
    classes[c.name] = c unless classes.has_key? c.name
  end
end

classes.each_value do |c|
  next unless c.superclass
  next if classes.has_key? c.superclass
  # parent unknown
  #  try parent.mof
  begin
    parser = Mofparser.new options
    result = parser.parse ["qualifiers.mof", "#{c.superclass}.mof"]
    if result
      result.each_value do |r|
	r.classes.each do |parent|
	  if parent.name == c.superclass
	    classes[parent.name] = parent
	  end
	end
      end
    else
      $stderr.puts "Warn: Parent #{c.superclass} of #{c.name} not known"
    end
  rescue Exception => e
    parser.error_handler e
  end
end

output = if options[:output]
           File.open(options[:output], "w+")
	 else
	   $stdout
	 end

classes.each_value do |c|
  class2provider c, output
end
