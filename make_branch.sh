#!/bin/bash
[ ! -d .snap ] && exit 1
[ -d .snap/branches/$1 ] && exit 1
head=`cat .snap/HEAD`
echo "`cat .snap/branches/$head`" > .snap/branches/$1
