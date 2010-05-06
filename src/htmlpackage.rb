# create HTML CIM package page
#
# Usage: [ -p <prefix> ] [ -b <basedir> ] <package>
#
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

if package.nil?
  $stderr.puts "Usage: [ -b <basedir> ] <package>"
  exit 1
end

content = %x{ "rpm" "-ql" "#{package}" }

unless $?.exitstatus == 0
  $stderr.puts "Package #{package} is not installed"
  exit 1
end

puts "<HTML>"
puts "<HEAD>"
puts "<TITLE>Provider #{package}</TITLE>"
puts "</HEAD>"
puts "<BODY>"
puts "<h1>Classes implemented by #{package}</h1>"
puts

content.each do |l|
  next unless l =~ /.mof$/
  next if l =~ /deploy.mof/
  l.chomp!
  parent = File.dirname(l)
  file = File.basename(l)
  classes = %x{ "ruby" "mofhtml.rb" "-q" "-I" "/usr/share/mof/cim-current" "-I" "#{parent}" "qualifiers.mof" "qualifiers_optional.mof" "#{file}" }
  exit 1 unless $?.exitstatus == 0
  puts "<h2> #{File.basename(file, '.mof')} </h2>"
  puts "<ul>"
  classes.sort.each do |c|
    c.chomp!
    puts "<li><a href=\"#{package}/#{c}.html\">#{c}</a></li>"
  end
  puts "</ul>"
end
puts "</BODY>"
puts "</HTML>"
