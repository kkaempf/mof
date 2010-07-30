require "test/unit"

PARENTNAME = File.join(File.dirname(__FILE__),"..")
GENPROVIDER = File.expand_path(File.join(PARENTNAME,"genprovider.rb"))
MOFDIR = File.join(File.dirname(__FILE__),"mof")
OUTPUT = File.join(File.dirname(__FILE__),"output.rb")

def run_genprovider
  system "ruby", GENPROVIDER, "-o", OUTPUT, MOFNAME
end
