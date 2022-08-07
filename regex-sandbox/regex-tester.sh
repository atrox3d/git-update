#!/usr/bin/env bash


if [ ! -t 0 -a $# -ge 1 ]			# pipe input stdin
then
	input=-
	regex="$1"
elif [ -t 0 -a $# -ge 2 ]			# filename in $1
then
	input="$1"
	regex="$2"
else
	echo "syntax | command | $0 regex"
	echo "syntax | $0 filename regex"
	exit 255
fi

echo "input | $input"
echo "regex | $regex"

cat "$input" | tr $'\n' ' ' | egrep -qi "$regex" && echo found || echo not found


