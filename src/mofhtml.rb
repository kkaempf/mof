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
      def to_html tr
	td = tr.add_element "td"
	td.text = self.to_s
      end
    end
  end
  
  module Schema
    
    class Method
      def to_html div
	tr = div.add_element "tr", "class" => "feature_method"
	td = tr.add_element "td"
	td.text = @name
	super tr
	td = tr.add_element "td"
	td.text = @parameters.to_s
      end
    end
    
    class Qualifier
      def self.array_to_html qualifiers, div
	return unless qualifiers
	return if qualifiers.empty?
	container = div.add_element "tr", "class" => "qualifiers_container"
	left = container.add_element "td", "class" => "qualifiers_container_head", "colspan" => "4"
	left.text = "Qualifiers"
	# Qualifiers
	qualifiers.each do |q|
	  q.to_html div
	end
      end

      def to_html div
	tr = div.add_element "tr", "class" => "qualifier_line"
	td = tr.add_element "td", "class" => "qualifier_left"
	td = tr.add_element "td", "class" => "qualifier_name"
	td.text = @definition.name.capitalize
	td = tr.add_element "td", "class" => "qualifier_value"
	if @value
	  case @value
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
	td.text = @flavor.to_s if @flavor
      end
    end
    
    class Property
      def to_html div
	Qualifier.array_to_html @qualifiers, div
	row = div.add_element "tr", "class" => "property"
	data = row.add_element "td", "class" => "property_data"
	span = data.add_element "td", "class" => "property_type"
	span.text = @type.to_s
	span = data.add_element "td", "class" => "property_name"
	span.text = @name
	if @default
	  span = data.add_element "td", "class" => "property_default"
	  span.text = " = #{@default}"
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
	
	qcols = Qualifier.array_to_html @qualifiers, table.add_element("table")
#	return
	
	# Class features
	
	first = true
	@features.each do |f|
	  f.to_html table.add_element "table", "border" => "1"
	end if @features
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
  c.to_html body
  doc
end

#------------------------------------------------------------------

moffiles, options = Mofparser.argv_handler "mofhtml", ARGV
options[:style] ||= :cim;
options[:includes] ||= []
options[:includes].unshift(Pathname.new ".")

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
