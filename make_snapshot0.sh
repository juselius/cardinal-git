#!/bin/bash
shopt -s extglob
[ ! -d .snap ] && exit 1
n=$((`ls -1 .snap/snapshots | tail -1` + 1))
mkdir .snap/snapshots/$n
cp -a ./!(.snap|.|..) .snap/snapshots/$n
