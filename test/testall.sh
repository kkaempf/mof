#!/bin/sh
for i in $@; do
  echo -n $i " "
  ruby ../src/rbmof.rb -q -s wmi -I /usr/share/mof/cim-current ../mof/wmi-qualifiers.mof $i
  if [ $? -ne 0 ]; then
    break
  fi
done