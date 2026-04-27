#!/bin/bash
# Autogeneries the quilt `series` from the patch order in the spec file.
# We don't use `quilt setup` because it makes a huge mess and doesn't work.
component="glibc"
rm -f series.new
extra_args="--fuzz=0"
count=0
# Transform patches into series file.
grep '^Patch.*:' glibc.spec | sed -e 's,Patch.*: ,,g' > series.new
count=`wc -l series.new | sed -e 's, .*$,,g'`
echo "Processed $count patches."
mv series.new series
echo "Generated quilt ./series file. Please do not commit."
exit 0
