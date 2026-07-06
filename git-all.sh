#!/usr/bin/env bash

SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
SCRIPT_NAME="$(basename $0)"
# let pwd decide work dir
# cd "${SCRIPT_DIR}"

#
# valid actions array
#
VALID_ACTION_LIST=(
	fetch
	push
	pull
	pushall
	branch
	list
)
#
# valid actions as a | separated string
#
VALID_ACTIONS=$(IFS='|';echo "${VALID_ACTION_LIST[*]}")
#
# dynamic (almost) syntax message
#
SYNTAX="$(basename ${0}) [-h][-p SEARCH_PATH] ${VALID_ACTIONS}[:param:param],..."
#
# set default search path to the script directory for the -p option
#
SEARCH_PATH="${PWD}"
#
# manage options
#
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
#
# check params
#
[ ${#} -gt 0 ] || {
	echo "syntax ${SYNTAX}"
	exit 1
}
# 
# save complete actions, like: action:param:param
# 
COMPLETE_ACTIONS=("${@}")
# 
# save the actions removing any parameters
# 
ACTIONS=("${COMPLETE_ACTIONS[@]%%:*}")
echo "ACTIONS=${ACTIONS[@]}"
# 
# check each action against the valid actions list
# 
for action in "${ACTIONS[@]}"
do
	[[ ${action} =~ ^(${VALID_ACTIONS}$) ]] || {
		echo "syntax ${SYNTAX}"
		exit 1
	}
done

echo "SEARCH_PATH=${SEARCH_PATH}"

# 
# get list of repos: using globstar for recursion
# 
#repos=( */.git ) && repos=( "${repos[@]%/.git}" );printf '%s\n' "${repos[@]}"
shopt -s globstar
REPOS=("${SEARCH_PATH}"/**/.git)
shopt -u globstar
#
# remove the .git appendix
#
REPOS=("${REPOS[@]%/.git}")
# 
# list is special, lists all the repos and exits
# 
[[ " ${ACTIONS[*]} " == *" list "* ]] && {
	echo "list detected, listing and exiting..."
	printf '%s\n' "${REPOS[@]}"
	exit
}
# 
# perform each action on each repo
# 
for repo in "${REPOS[@]}"
do
	echo "##################################################################"
	echo "repo  : ${repo}"
	for COMPLETE_ACTION in "${COMPLETE_ACTIONS[@]}"
	do
		unset PARAMS									# if PARAMS is an array, setting PARAMS='whatever' sets the first item!!!
		ACTION="${COMPLETE_ACTION%%:*}"					# extract action
		PARAMS=${COMPLETE_ACTION#*:}					# extract param:param
		# echo "complete action: ${COMPLETE_ACTION}"
		# echo "action         : ${ACTION}"
		# echo "params         : ${PARAMS}"
		[ "${PARAMS}" = "${COMPLETE_ACTION}" ] && {
			#
			# if params = complete_action then we do not have any params
			#
			# echo "SETTING PARAMS TO ''"
			PARAMS=""
		 } || {
			#
			# get the params as space separated strings
			#
			#  echo "SETTING PARAMS TO ARRAY"
			 PARAMS=($(IFS=:;echo ${PARAMS}))
		 }
		echo "------------------------------------------------------------------"
		echo "action: ${ACTION}"
		echo "params: ${PARAMS[*]}"
		echo "------------------------------------------------------------------"
		case ${ACTION} in
			pushall)
				#
				# special custom action
				#
				(cd ${repo};for remote in $(git remote); do echo ${remote};git push ${remote} HEAD;done)
			;;
			push)
				#
				# filter out bitbucket repos from push
				#
				[[ "${repo}" == *"repos/"* ]] && {
					echo "push ***FORBIDDEN*** for ${repo}"
					continue
				} || {
					echo git -C "${repo}" ${ACTION} ${PARAMS[@]}
					git -C "${repo}" push ${PARAMS[@]}
				}
			;;
			*)
				#
				# generic git command params
				#
				echo git -C "${repo}" ${ACTION} ${PARAMS[@]}
				git -C "${repo}" ${ACTION} ${PARAMS[@]}
			;;
		esac
		echo ""
		# exit
	done
done


