#
# Makefile for mof parser
#
# Parsing MOF files in Ruby
#

all: mofparser.rb Makefile

mofparser.rb: mofparser.y mofscanner.rb
	racc -g -v -o $@ $<

clean:
	$(RM) mofparser.rb
	$(RM) mofparser.output

distclean: clean
	$(RM) *~
