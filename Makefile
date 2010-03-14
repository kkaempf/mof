all:
	(cd parser; make)
	(cd src; make)

test: all
	(cd test; make)
