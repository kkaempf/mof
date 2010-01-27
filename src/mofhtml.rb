#
# mofhtml.rb
#
# MOF to HTML converter
#

require "rexml/document"
require 'pathname'
require File.dirname(__FILE__) + "/../parser/mofparser"

module CIM
  module Schema
    
    class Qualifier
      def self.array_to_html qualifiers, div
	container = div.add_element "div", "style" => "background-color: yellow; margin : 2px"
	left = container.add_element "div", "style" => "float : left; width : 14em"
	left.text = "Qualifiers"
	right = container.add_element "div", "style" => "float : left"
	# Qualifiers
	qualifiers.each do |q|
	  q.to_html left, right
	end
      end

      def to_html left, right
	cols = 1
	name = left.add_element "div", "style" => ""
	name.text = @definition.name.capitalize
	if @value
	  cols += 1
	  data = right.add_element "div", "style" => "font : sans-serif"
	  case @value
	  when String
	    @value.split("\\n").each do |l|
	      divc = data.add_element "div", "style" => "clear : both"
	      divc.text = l.gsub "\\\"", '"'
	    end
	  else
	    data.text = @value
	  end
	end
	if @flavor
	  cols += 1
	  data = div.add_element "div", "style" => "float: left"
	  data.text = @flavor.to_s
	end
	cols
      end
    end
    
    class Property
      def to_html div
	Qualifier.array_to_html @qualifiers, div
	d = div.add_element "div", "style" => "background-color: red; margin : 4px; clear : both"
	row = d.add_element "div"
	data = row.add_element "div", "style" => "float: left"
	span = data.add_element "span"
	span.text = @type.to_s
	span = data.add_element "span", "style" => "font: bold"
	span.text = @name
	if @default
	  span = data.add_element "span"
	  span.text = " = #{@default}"
	end
      end
    end
    
    class Class
      def to_html body
	h1 = body.add_element "h1"
	h1.text = name
	
	div0 = body.add_element "div", "style" => "background-color: blue; font : serif"
	
	qcols = Qualifier.array_to_html @qualifiers, div0
	
	# Class name, alias, superclass
	
	divc = div0.add_element "div", "style" => "font: bold; background-color : white; clear : both"
	divc.text = name
	span = divc.add_element "span"
	text = ""
	text += " as #{@alias_name}" if @alias_name
	if @superclass
	  text += ": " 
	  href = divc.add_element "a", "href" => "#{@superclass}.html"
	  href.text = @superclass
	end
	span.text = text
	
	# Class features
	
	first = true
	@features.each do |f|
	  divf = div0.add_element "div", "style" => "margin : 4px; background-color : olive; clear : both"
	  f.to_html divf
	end
      end
    end
  end
end

def class2html c, dir
  dir = "#{dir}/class"
  Dir.mkdir(dir) unless File.directory?(dir)
  name = c.name
  doc = REXML::Document.new
  html = doc.add_element "html"
  head = html.add_element "head"
  title = head.add_element "title"
  title.text = "Class #{name}"
  body = html.add_element "body"
  c.to_html body
  doc.write( File.new("#{dir}/#{name}.html", "w+"), 0 )
end



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

Dir.mkdir("html") unless File.directory?("html")

result.classes.each do |c|
  class2html c, "html"
end