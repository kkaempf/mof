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

#
# return XHTML tree for class 'c'
#

def class2html c
  name = c.name
  doc = REXML::Document.new
  html = doc.add_element "html", "xmlns"=>"http://www.w3.org/1999/xhtml", "xml:lang"=>"en", "lang"=>"en"
  head = html.add_element "head"
  head.add_element "meta", "http-equiv"=>"Content-type", "content"=>"text/html; charset=utf-8"
  title = head.add_element "title"
  title.text = "Class #{name}"
  css = head.add_element "link", "rel"=>"stylesheet", "href"=>"mofhtml.css", "type"=>"text/css", "media"=>"screen,projection,print"
  body = html.add_element "body"
  c.to_html body.add_element("div", "class" => "outer_div")
  doc
end

#------------------------------------------------------------------

moffiles, options = Mofparser.argv_handler "mofhtml", ARGV
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

exit 0 unless result

basedir = File.join("html", options[:namespace])

result.each do |name, res|
  res.classes.each do |c|
    xhtml = class2html c
    dir = "#{basedir}/class"
    FileUtils.mkdir_p(dir) unless File.directory?(dir)
    xhtml.write( File.new("#{dir}/#{c.name}.html", "w+"), 0 )
  end
end
