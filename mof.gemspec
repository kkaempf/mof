# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mof"

Gem::Specification.new do |s|
  s.name        = "mof"
  s.version     = MOF::VERSION

  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Klaus Kämpf"]
  s.email       = ["kkaempf@suse.de"]
  s.homepage    = "https://github.com/kkaempf/mof"
  s.summary     = %q{A pure Ruby parser for MOF (Managed Object Format) files}
  s.description = %q{The Managed Object Format (MOF) language used to
describe classes and instances of the Common Information Model (CIM).
See http://www.dmtf.org/education/mof}

  s.rubyforge_project = "mof"

  # CIM metamodel
  s.add_dependency("cim", ["~> 0.5"])

  s.files         = `git ls-files`.split("\n") << "lib/mof/parser.rb"
  s.files.reject! { |fn| fn == '.gitignore' }
  s.extra_rdoc_files    = Dir['README*', 'TODO*', 'CHANGELOG*', 'LICENSE']
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
