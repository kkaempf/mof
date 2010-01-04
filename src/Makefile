#
# Makefile for rbmof
#
# mof compiler in Ruby
#

all: rbmof.rb Makefile

rbmof.rb: rbmof.y mofscanner.rb
	racc -g -v -o $@ $<

clean:
	$(RM) rbmof.rb
	$(RM) rbmof.output

distclean: clean
	$(RM) *~
