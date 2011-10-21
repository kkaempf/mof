$d = File.expand_path(File.dirname(__FILE__))
require "test/unit"
require File.join($d,'..','lib','mof')

class TestClassQualifiers < Test::Unit::TestCase

  def setup
    @moffiles, @options = MOF::Parser.argv_handler "test_class_qualifier", ["class_qualifiers.mof"]
    @options[:style] ||= :cim
    @options[:includes] ||= [ $d, File.join($d,"mof")]

    @parser = MOF::Parser.new @options
  end
  
  def test_parse
    result = @parser.parse @moffiles
    assert result
    # parsed one file
    assert_equal 1, result.size

    name,res = result.shift
    assert !res.qualifiers.empty?
    # parsed three qualifier
    assert_equal 3, res.qualifiers.size
    assert res.qualifiers.include? :association
    assert res.qualifiers.include? :indication
    assert res.qualifiers.include? :description
  end
end
