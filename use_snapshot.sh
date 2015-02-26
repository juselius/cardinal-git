#!/bin/bash
shopt -s extglob
[ ! -d .snap ] && exit 1
[ ! -e .snap/branches/$1 ] && exit 1
rm -rf ./!(.snap|.|..)
sha1=`cat .snap/branches/$1`
cp -a .snap/snapshots/$sha1/!(message|.|..) .
echo $1 >.snap/HEAD
