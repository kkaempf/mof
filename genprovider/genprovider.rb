#
# mofhtml.rb
#
# MOF to HTML converter
#

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
    @file.write "  " * @indent
  end
  public
  def initialize file
    @file = file
    @indent = 0
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
  def puts str=""
    indent
    @file.puts str
    self
  end
  def comment str=""
    indent
    @file.write "#"
    @file.write "  #{str}" if str.size > 0
    @file.puts
    self
  end
  def printf format, *args
    printf @file, format, *args
    @file.puts
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
  out.puts("def #{feature.name}").inc
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

moffiles, options = Mofparser.argv_handler "genprovider", ARGV
options[:style] ||= :cim;
options[:includes] ||= []
options[:includes].unshift(Pathname.new ".")
options[:includes].unshift(Pathname.new "/usr/share/mof/cim-current")

moffiles.unshift "qualifiers.mof" unless moffiles.include? "qualifiers.mof"
moffiles.unshift "qualifiers_optional.mof" unless moffiles.include? "qualifiers_optional.mof"

parser = Mofparser.new options

begin
  result = parser.parse moffiles
rescue Exception => e
  parser.error_handler e
  exit 1
end

exit 0 unless result

result.each do |name, res|
  output = if options[:output]
             File.open(options[:output], "w+")
	   else
	     $stdout
	   end
  res.classes.each do |c|
    class2provider c, output
  end
end
