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
      def self.array_to_mediawiki qualifiers, indent=0
	return unless qualifiers
	return if qualifiers.empty?
	# Qualifiers
	mediawiki = []
	qualifiers.each do |q|
	  mediawiki.concat q.to_mediawiki(indent)
	  mediawiki << "|-"
	end
	mediawiki
      end

      def to_mediawiki indent=0
	mediawiki = "| %s''%s'' || " % [" || "*indent, @definition.name.capitalize ]
	case @value
	when Array
	  mediawiki << "{ #{@value.join(', ')} }"
	when String
	  @value.split("\\n").each do |l|
	    mediawiki << l.gsub("\\\"", '"')
	    mediawiki << "\n"
	  end
	else
	  mediawiki << @value.to_s
	end
	if @flavor
	  mediawiki << " || #{@flavor.to_s}"
	end
	[ mediawiki ]
      end
    end
    
    class Property
      def self.array_to_mediawiki properties, indent=0
	return unless properties
	return if properties.empty?
	mediawiki = []
	# Properties
	properties.each do |p|
	  mediawiki.concat p.to_mediawiki(indent)
	  mediawiki << "|-"
	end
	mediawiki
      end

      def to_mediawiki indent=0
	out = '! %scolspan="2"|%s %s' % [ " ||"*indent,  @type.to_s, @name ]
        if @default
          out << " = #{@default}"
        end
	[out, "|-", Qualifier.array_to_mediawiki(@qualifiers, indent)]
      end
    end
    
    class Class
      def to_mediawiki dir
        mediawiki = [ "=Class #{name}=" ]

        mediawiki << ("%s%s%s" % [ name, @alias_name ? "as #{@alias_name}" : "", @superclass ? ": [[#{dir}/#{@superclass}|#{@superclass}]]" : "" ])
	
	# Class qualifiers
	mediawiki.concat [ "{|", '!colspan="4"|Qualifiers', "|-" ]
	
	mediawiki.concat Qualifier.array_to_mediawiki(@qualifiers,1)
	
	mediawiki << "|}"
	
	# Class properties (features)
	
	mediawiki.concat [ "{|", '!colspan="4"|Properties', "|-" ]
	mediawiki.concat Property.array_to_mediawiki(@features,1)
	mediawiki << "|}"
	
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

schemaprefix = File.dirname(moffiles.last)
wikiprefix = "SystemsManagement/CIM/Schema/" + schemaprefix

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
    dir = "#{basedir}/#{schemaprefix}"
    mediawiki = c.to_mediawiki wikiprefix
    FileUtils.mkdir_p(dir) unless File.directory?(dir)
    File.open("#{dir}/#{c.name}.mediawiki", "w+") do |f|
      mediawiki.each do |line|
	f.puts line
      end
    end
  end
end
