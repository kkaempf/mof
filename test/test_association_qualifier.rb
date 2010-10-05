D = File.expand_path(File.dirname(__FILE__))
require "test/unit"
require File.join(D,'..','lib','mof')

class TestQualifiers < Test::Unit::TestCase

  def setup
    @moffiles, @options = MOF::Parser.argv_handler "test_qualifier", ["association_qualifier.mof"]
    @options[:style] ||= :cim
    @options[:includes] ||= [ D, File.join(D,"mof")]

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
    assert q.type == :bool
    assert q.default == false
    # has one qualifier scopes
    assert_equal 1, q.scope.size
    assert q.scope.include? :association
    # has two qualifier flavors
    assert_equal 2, q.flavor.size
    assert q.flavor.include? :disableoverride
    assert q.flavor.include? :tosubclass
  end
end
