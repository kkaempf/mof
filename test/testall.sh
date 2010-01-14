#!/bin/sh
for i in $@; do
  echo $i
  ruby ../src/rbmof.rb -q -s wmi -I /usr/share/mof/cim-current ../mof/wmi-qualifiers.mof $i
done