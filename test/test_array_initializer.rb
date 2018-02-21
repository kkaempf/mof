D = File.expand_path(File.dirname(__FILE__))
require "test/unit"
require File.join(D,'..','lib','mof')

class TestQualifiers < Test::Unit::TestCase

  def setup
    @moffiles, @options = MOF::Parser.argv_handler "test_qualifier", ["array_initializer.mof"]
    @options[:style] ||= :cim
    @options[:includes] ||= [ D, File.join(D,"mof")]

    @parser = MOF::Parser.new @options
  end
  
  def test_parse
    result = @parser.parse @moffiles
    assert result
    _,res = result.shift
    # parsed one class
    assert_equal 1, res.classes.size
    c = res.classes.shift
    assert c.is_a? CIM::Class
    assert_equal "MOF_Test", c.name
    assert_equal "Parent_Class", c.superclass
    # one (property) feature
    assert_equal 1, c.features.size
    c.features.each do |f|
      next unless f.is_a? CIM::Property
      assert f.property?
      assert !f.method?
      assert_equal "text", f.name
      assert f.type == :string
      assert_equal 1, f.qualifiers.size
      q = f.qualifiers.shift
      assert_equal "Array", q.name
      assert q.type == :array
    end
  end
end
