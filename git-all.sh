#!/usr/bin/env bash

SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
SCRIPT_NAME="$(basename $0)"
# cd "${SCRIPT_DIR}"

# valid actions array
VALID_ACTION_LIST=(
	fetch
	push
	pull
	pushall
	branch
	list
)
# valid actions as a | separated string
VALID_ACTIONS=$(IFS='|';echo "${VALID_ACTION_LIST[*]}")
# dynamic (almost) syntax message
SYNTAX="$(basename ${0}) [-h][-p SEARCH_PATH] ${VALID_ACTIONS}[:param:param],..."

# set default search path to the script directory for the -p option
SEARCH_PATH="${PWD}"

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

# check params
[ ${#} -gt 0 ] || {
	echo "syntax ${SYNTAX}"
	exit 1
}

# convert all parameters to lowercase and store them in an array
COMPLETE_ACTIONS=("${@}")
ACTIONS=("${COMPLETE_ACTIONS[@]%%:*}")
echo "ACTIONS=${ACTIONS[@]}"
# check each action against the valid actions list
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


# get list of repos
shopt -s globstar
#repos=( */.git ) && repos=( "${repos[@]%/.git}" );printf '%s\n' "${repos[@]}"
REPOS=("${SEARCH_PATH}"/**/.git)
shopt -u globstar

REPOS=("${REPOS[@]%/.git}")

# list is special, lists all the repos and exits
[[ " ${ACTIONS[*]} " == *" list "* ]] && {
	echo "list detected, listing and exiting..."
	printf '%s\n' "${REPOS[@]}"
	exit
}

# perform each action on each repo
for repo in "${REPOS[@]}"
do
	echo "##################################################################"
	echo "repo  : ${repo}"
	for COMPLETE_ACTION in "${COMPLETE_ACTIONS[@]}"
	do
		ACTION="${COMPLETE_ACTION%%:*}"
		PARAMS=${COMPLETE_ACTION#*:}
		echo "action: ${ACTION}"
		echo "params: ${PARAMS}"
		[ "${PARAMS}" == "${COMPLETE_ACTION}" ] && PARAMS="" || PARAMS=($(IFS=:;echo ${PARAMS}))
		echo "------------------------------------------------------------------"
		echo "action: ${ACTION}"
		echo "params: ${PARAMS[*]}"
		echo "------------------------------------------------------------------"
		case ${ACTION} in
			pushall)
				(cd ${repo};for remote in $(git remote); do echo ${remote};git push ${remote} HEAD;done)
			;;
			push)
				[[ "${repo}" == *"repos/"* ]] && {
					echo "push ***FORBIDDEN*** for ${repo}"
					continue
				} || {
					echo git -C "${repo}" ${ACTION} ${PARAMS[@]}
					git -C "${repo}" push ${PARAMS[@]}
				}
			;;
			*)
				echo git -C "${repo}" ${ACTION} ${PARAMS[@]}
				git -C "${repo}" ${ACTION} ${PARAMS[@]}
			;;
		esac
		echo ""
		# exit
	done
done


