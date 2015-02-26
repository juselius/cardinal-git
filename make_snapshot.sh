#!/bin/bash
[ ! -d .snap ] && exit 1
echo -n "message: "; read msg
branch=`cat .snap/HEAD`

cat << EOF0 > .message
parent: `cat .snap/branches/$branch`
author: $USER <$USER@`hostname -f`>
date: `date`
message: $msg
EOF0
[ x$1 != x ] && echo "parent: `cat .snap/branches/$1`" >> .message

sha1=`sha1sum .message | cut -d ' ' -f1`
mkdir .snap/snapshots/$sha1
cp -a * .snap/snapshots/$sha1
mv .message .snap/snapshots/$sha1/message
echo $sha1 > .snap/branches/$branch
