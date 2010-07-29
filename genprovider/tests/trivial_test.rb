require "test/unit"

PARENTNAME = File.join(File.dirname(__FILE__),"..")
GENPROVIDER = File.expand_path(File.join(PARENTNAME,"genprovider.rb"))
MOFNAME = File.join(File.dirname(__FILE__),"trivial.mof")
OUTPUT = File.join(File.dirname(__FILE__),"output.rb")

def run_genprovider
  system "ruby", GENPROVIDER, "-o", OUTPUT, MOFNAME
end

class TrivialTest < Test::Unit::TestCase
  def test_running_genprovider
    run_genprovider
  end
end
