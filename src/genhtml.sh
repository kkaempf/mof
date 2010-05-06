#!/bin/sh
#
for i in `find /usr/share/mof/cim-current/* -type d`; do
  echo $i
  b=`basename $i`
  ruby htmlhierachy.rb $b > html/$b.html
done
