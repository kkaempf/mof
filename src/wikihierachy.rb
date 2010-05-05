# create MediaWiki hierarchy
#
# Usage: [ -p <prefix> ] [ -b <basedir> ] <schema>
#
# prefix: Wiki prefix, defaults to SystemsManagement/CIM/Schema
# basedir: base directory, defaults to /usr/share/mof/cim-current
#
#

COLUMNS = 3

arg = ARGV.shift
basedir = "/usr/share/mof/cim-current"
if arg == "-b"
  basedir = ARGV.shift
else
  schema = arg
end

prefix = "SystemsManagement/CIM/Schema"

if schema.nil?
  $stderr.puts "Usage: [ -b <basedir> ] <schema>"
  exit 1
end

puts "= #{schema} ="
puts
puts "{|"

classes = []
Dir.foreach( File.join(basedir, schema) ) do |f|
  next if f[0,1] == "."
  classes << File.basename(f, ".mof")
end
classes.sort!

count = classes.size
i = 0
classes.each do |classname|
  if i % COLUMNS == 0
    print "| "
  end
  print "[[#{prefix}/#{schema}/#{classname}|#{classname}]]"
  i += 1
  if i < count
    if i % COLUMNS == 0
      puts "\n|-"
    else
      print " || "
    end
  end
end
puts "\n|}"
