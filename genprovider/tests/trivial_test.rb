require "test/unit"
PARENTNAME = File.join(File.dirname(__FILE__),"..")
GENPROVIDER = File.expand_path(File.join(PARENTNAME,"genprovider.rb"))
def run_genprovider
  system "ruby", GENPROVIDER, File.join(File.dirname(__FILE__),"trivial.mof")
end
class TrivialTest < Test::Unit::TestCase
  def test_running_genprovider
    run_genprovider
  end
end
