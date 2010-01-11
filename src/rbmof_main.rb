
help = false
debug = false
quiet = false
style = :cim
includes = [Pathname.new "."]
moffiles = []

while ARGV.size > 0
  case opt = ARGV.shift
    when "-h":
      $stderr.puts "Ruby MOF compiler"
      $stderr.puts "rbmof [-h] [-d] [-I <dir>] [<moffiles>]"
      $stderr.puts "Compiles <moffile>"
      $stderr.puts "\t-s <style>  syntax style (wmi,cim)"
      $stderr.puts "\t-h  this help"
      $stderr.puts "\t-d  debug"
      $stderr.puts "\t-q  quiet"
      $stderr.puts "\t-I <dir>  include dir"
      $stderr.puts "\t<moffiles>  file(s) to read (else use $stdin)"
      exit 0
    when "-s": style = ARGV.shift.to_sym
    when "-d": debug = true
    when "-q": quiet = true
    when "-I": includes << Pathname.new(ARGV.shift)
    when /^-.+/:
      $stderr.puts "Undefined option #{opt}"
    else
      moffiles << opt
  end
end

parser = CIM::Schema::Mofparser.new debug, includes

puts "Mofparser starting"

moffiles << $stdin if moffiles.empty?

begin
  result = parser.parse( moffiles, style, quiet )
  unless quiet
    puts "Accept!"
    puts result
  end
rescue CIM::Schema::StyleError => e
  STDERR.puts "#{e.name}:#{e.line}: Syntax does not comply to '#{parser.style}' style"
  exit 1
rescue CIM::Schema::ScannerError => e
  STDERR.puts "*** ScannerError: #{$!}"
rescue Exception => e
  STDERR.puts "*** Error: #{$!}[#{$!.class}]"
  exit 1
end
