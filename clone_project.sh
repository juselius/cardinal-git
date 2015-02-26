#!/bin/bash
shopt -s extglob
scp -r $1 $2
cd $2/.snap/branches
mkdir origin
mv ./!(origin)  origin
cp origin/master .
cd ..
echo "master" > HEAD

