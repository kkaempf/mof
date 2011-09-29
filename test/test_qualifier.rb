$d = File.expand_path(File.dirname(__FILE__))
require "test/unit"
require File.join($d,'..','lib','mof')

class TestQualifiers < Test::Unit::TestCase

  def setup
    @moffiles, @options = MOF::Parser.argv_handler "test_qualifier", ["qualifier.mof"]
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
    # parsed one qualifier
    assert_equal 1, res.qualifiers.size
    q = res.qualifiers.shift
    assert q.is_a? CIM::QualifierDeclaration
    assert q.type == :string
    # has two qualifier scopes
    assert_equal 2, q.scopes.size
    assert q.scopes.include? :class
    assert q.scopes.include? :property
  end
end
