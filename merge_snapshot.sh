#!/bin/bash
shopt -s extglob
[ ! -d .snap ] && exit 1
[ ! -e .snap/branches/$1 ] && exit 1
head=`cat .snap/HEAD`
mkdir -p /tmp/snap.$$/a /tmp/snap.$$/b
cp -a .snap/snapshots/`cat .snap/branches/$head`/!(.|..) /tmp/snap.$$/a
cp -a .snap/snapshots/`cat .snap/branches/$1`/!(.|..) /tmp/snap.$$/b
rm /tmp/snap.$$/a/message /tmp/snap.$$/b/message
diff -uN /tmp/snap.$$/a /tmp/snap.$$/b | patch
.snap/bin/make_snapshot.sh $branch
rm -rf /tmp/snap.$$
