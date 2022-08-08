#!/usr/bin/env bash


if [ ! -t 0 -a $# -ge 1 ]
then
	input=-										# pipe input stdin
	regex="${1}"								# regex in first param
elif [ -t 0 -a $# -ge 2 ]
then
	input="${1}"								# input filename in ${1}
	regex="${2}"								# regex in second param
else
	echo "syntax | command | ${0} regex"
	echo "syntax | ${0} filename regex"
	exit 255
fi

input="$(cat "${input}" | tr $'\n' ' ' )"		# assign input

if [ -f "${regex}" ]							# 2nd parameter is filename
then
	echo "${regex} file found"
	regex="$(cat "${regex}" | tr -d $'\n')"		#  assign regex file content
fi

echo "input | '${input}'"
echo "regex | '${regex}'"

echo "${input}" | egrep -qi "${regex}" && {
	echo found
	exit 0
} || {
	echo not found
	exit 1
}



