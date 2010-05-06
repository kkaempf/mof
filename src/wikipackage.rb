# create MediaWiki CIM package page
#
# Usage: [ -p <prefix> ] [ -b <basedir> ] <package>
#
# prefix: Wiki prefix, defaults to SystemsManagement/CIM/Providers
# basedir: schema base directory, defaults to /usr/share/mof/cim-current
#
#

arg = ARGV.shift
basedir = "/usr/share/mof/cim-current"
package = nil
if arg == "-b"
  basedir = ARGV.shift
else
  package = arg.chomp
end

prefix = "SystemsManagement/CIM/Providers"

if package.nil?
  $stderr.puts "Usage: [ -b <basedir> ] <package>"
  exit 1
end

content = %x{ "rpm" "-ql" "#{package}" }

unless $?.exitstatus == 0
  $stderr.puts "Package #{package} is not installed"
  exit 1
end

puts "= #{package} ="

content.each do |l|
  next unless l =~ /.mof$/
  next if l =~ /deploy.mof/
  l.chomp!
  parent = File.dirname(l)
  file = File.basename(l)
  classes = %x{ "ruby" "mofmediawiki.rb" "-q" "-I" "/usr/share/mof/cim-current" "-I" "#{parent}" "qualifiers.mof" "qualifiers_optional.mof" "#{file}" }
  puts "== #{File.basename(file, '.mof')} =="
  classes.each do |c|
    c.chomp!
    puts "* [[#{prefix}/#{package}/#{c}|#{c}]]"
  end
end
