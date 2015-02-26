#!/bin/bash
[ ! -d .snap ] && exit 1
[ ! -e .snap/branches/origin/$2 ] && exit 1
scp $1/.snap/branches/$2 .snap/branches/origin/$2
sha1=`cat .snap/branches/origin/$2`
while true; do
    [ -e .snap/snapshots/$sha1 ] && break
    echo $sha1
    scp -r $1/.snap/snapshots/$sha1 .snap/snapshots/
    sha1=`cat .snap/snapshots/$sha1/message | sed -n 's/parent: //p'`
    [ x$sha1 = x ] && break
done
