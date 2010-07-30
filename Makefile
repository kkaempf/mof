all:
	(cd parser; make)
	(cd tools; make)

test: all
	(cd test; make)
