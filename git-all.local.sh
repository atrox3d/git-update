#!/usr/bin/env bash

SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
SCRIPT_NAME="$(basename $0)"
cd "${SCRIPT_DIR}"

VALID_ACTION_LIST=(
	fetch
	push
	pull
	pushall
	list
)
VALID_ACTIONS=$(IFS='|';echo "${VALID_ACTION_LIST[*]}")
SYNTAX="$(basename ${0}) [-h][-p SEARCH_PATH] ${VALID_ACTIONS},..."
SEARCH_PATH="${SCRIPT_DIR}"

while getopts ":hp:" OPTION; do
    case ${OPTION} in
		h)
			echo "syntax ${SYNTAX}"
			exit
		;;
		p)
			SEARCH_PATH="${OPTARG}"
		;;
	esac
done
shift $((OPTIND -1))

[ ${#} -gt 0 ] || {
	echo "syntax ${SYNTAX}"
	exit 1
}

ACTIONS=("${@,,}")
echo "ACTIONS=${ACTIONS[@]}"
for action in "${ACTIONS[@]}"
do
	# ACTION=${1:?"syntax ${SYNTAX}"}
	# ACTION=${ACTION,,}
	[[ ${action} =~ ^(${VALID_ACTIONS}$) ]] || {
		echo "syntax ${SYNTAX}"
		exit 1
	}
done

echo "SEARCH_PATH=${SEARCH_PATH}"
#repos=( */.git ) && repos=( "${repos[@]%/.git}" );printf '%s\n' "${repos[@]}"

shopt -s globstar
REPOS=("${SEARCH_PATH}"/**/.git)
shopt -u globstar

REPOS=("${REPOS[@]%/.git}")

[[ "${ACTIONS[@]}" == *" list "* ]] && {
	echo "list detected, listing and exiting..."
	printf '%s\n' "${REPOS[@]}"
	exit
}


for repo in "${REPOS[@]}"
do
	echo "##################################################################"
	echo "                          ${repo}"
	echo "##################################################################"
	for ACTION in "${ACTIONS[@]}"
	do
		echo "action=${ACTION}:"
		case ${ACTION} in
			pushall)
				(cd ${repo};for remote in $(git remote); do echo ${remote};git push ${remote} HEAD;done)
			;;
			*)
				git -C "${repo}" ${ACTION}
			;;
		esac
		echo ""
	done
done


