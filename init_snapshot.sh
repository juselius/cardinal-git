#!/bin/bash

[ -d .snap ] && exit 1
script=`readlink -f $0`
snapdir=`dirname $script`

mkdir .snap
mkdir .snap/snapshots
mkdir .snap/bin
mkdir .snap/branches
mkdir .snap/tags

cp $snapdir/*.sh .snap/bin/
echo "master" > .snap/HEAD
echo "0" > .snap/branches/master



