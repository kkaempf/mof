#
# features/support/env.rb
#

require 'rubygems'
require "test/unit"

PARENTNAME = File.expand_path(File.join(File.dirname(__FILE__),"..","..",".."))
GENPROVIDER = File.join(PARENTNAME,"genprovider.rb")
MOFDIR = File.join(File.dirname(__FILE__),"mof")
OUTPUT = File.join(File.dirname(__FILE__),"output.rb")
