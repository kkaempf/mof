#
# mofmediawiki.rb
#
# MOF to MediaWiki converter
#

require "rexml/document"
require 'pathname'
require 'fileutils'
require File.dirname(__FILE__) + "/../parser/mofparser"

module CIM
  module Meta
    class Feature
      def to_mediawiki
	[ self.to_s ]
      end
    end
  end
  
  module Schema
    
    class Method
      def to_mediawiki
	[ "#{@name}", super, "(", @parameters.to_s, ")" ]
      end
    end
    
    class Qualifier
      def self.array_to_mediawiki qualifiers
	return unless qualifiers
	return if qualifiers.empty?
	mediawiki = [ "{|", "!Qualifiers", "|-" ]
	# Qualifiers
	qualifiers.each do |q|
	  mediawiki.concat q.to_mediawiki
	  mediawiki << "|-"
	end
	mediawiki << "|}"
      end

      def to_mediawiki
	mediawiki = [ @definition.name.capitalize ]
	if @value
	  mediawiki << "||"
	  case @value
	  when String
	    @value.split("\\n").each do |l|
	      mediawiki << l.gsub("\\\"", '"')
	    end
	  else
	    mediawiki << @value
	  end
	end
	if @flavor
	  mediawiki << "||"
	  mediawiki << @flavor.to_s
	end
	mediawiki
      end
    end
    
    class Property
      def self.array_to_mediawiki properties
	return unless properties
	return if properties.empty?
	mediawiki = [ "{|", "!Properties", "|-" ]
	# Properties
	properties.each do |p|
	  mediawiki.concat p.to_mediawiki
	  mediawiki << "|-"
	end
	mediawiki << "|}"
      end

      def to_mediawiki
	mediawiki = Qualifier.array_to_mediawiki @qualifiers
	mediawiki.concat [ "{|", "!Properties", "|-" ]
	mediawiki << @type.to_s
        mediawiki << "||"
	mediawiki << @name
        if @default
          mediawiki << "||"
	  mediawiki << " = #{@default}"
        end
        mediawiki << "|}"
      end
    end
    
    class Class
      def to_mediawiki dir
        mediawiki = [ "=Class #{name}=" ]

        mediawiki << ("Class %s%s%s" % [ name, @alias_name ? "as #{@alias_name}" : "", @superclass ? ": [[#{dir}/#{@superclass}|#{@superclass}]]" : "" ])
	
	# Class qualifiers
	
	mediawiki.concat Qualifier.array_to_mediawiki(@qualifiers)
	
	# Class properties (features)
	
	mediawiki.concat Property.array_to_mediawiki(@features)

	mediawiki
      end
    end
  end
end


#------------------------------------------------------------------

moffiles, options = Mofparser.argv_handler "mofmediawiki", ARGV
options[:style] ||= :cim;
options[:includes] ||= []
options[:includes].unshift(Pathname.new ".")

wikiprefix = "SystemsManagement/CIM/classes"

parser = Mofparser.new options

begin
  result = parser.parse moffiles
rescue Exception => e
  parser.error_handler e
  exit 1
end

exit 0 unless result

basedir = File.join("mediawiki", options[:namespace])

result.each do |name, res|
  res.classes.each do |c|
    dir = "#{basedir}/class"
    mediawiki = c.to_mediawiki wikiprefix
    FileUtils.mkdir_p(dir) unless File.directory?(dir)
    File.open("#{dir}/#{c.name}.mediawiki", "w+") do |f|
      mediawiki.each do |line|
	f.puts line
      end
    end
  end
end
