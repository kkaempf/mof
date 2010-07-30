#!/bin/sh
#
# genpkgdoc
# generate html class documentation for an installed package
#
# Usage:
#  genpkgdoc <pkgname> [ <target_dir> ]
name=$1
target=${2:-~/public_html/cim}/$name
sudo zypper in $name
echo "Generate html doc for $name at $target"
rm -rf html/class
ruby htmlpackage.rb $name > $target.html
rm -rf $target
mv html/class $target
