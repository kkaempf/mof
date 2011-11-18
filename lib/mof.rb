$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

# keep version separate so mof.gemspec can source it without all the rest
require "mof/version"

module MOF
  require "mof/parser"
end
