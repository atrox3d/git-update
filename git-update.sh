#!/usr/bin/env bash
###############################################################################
#
#	gitupdate.sh
#
#	- 	iterates over each subdirectory of current path
#		if it contains a .git subfolder then performs:
#			- git fetch
#			- git status
#		based on git status result displays colored status line
#		if the repo needs pull/add/commit/... it displays git output
#
###############################################################################
HERE="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"	# get current path
. "${HERE}/.setup"												# load modules
HERE="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"	# get current path
NAME="$(basename ${BASH_SOURCE[0]})"							# save this script name
###############################################################################
REGEX_DIR="${HERE}/regex-sandbox"
PULL_ENABLED="false"
STOP_AT_FIRST="false"

while getopts "fp" arg
do
	arg="${arg,,}"							# force lowercase

	case "${arg}" in
	
		p)									# pull from origin
			PULL_ENABLED="true"
			info "PULL is ENABLED"
		;;
	
		f)									# stop at first check (?)
			STOP_AT_FIRST="true"
			info "STOP_AT_FIRST is ENABLED"
		;;
	esac
done
shift "$((OPTIND-1))"

PATHS=()
for arg
do
	if [ -d "${arg}"/.git ]
	then
		PATHS+=( "${arg}" )
		info "PATH | ${arg}"
	else
		warn "path ${arg} is not a git repo, ignoring"
	fi
done

#
#	main loop
#
echo
for DIR in "${PATHS[@]}"
do
	printf -v TAG "[%-60.60s]" "$DIR"								# formatted [dir name]
	#
	# begin subshell
	#
	(
		unset EXTRA
		cd "$DIR"													# let's move into
		
		[ "$(git remote -v)" != "" ] && {							# do we have remotes?
			git fetch > /dev/null									# yes, then we fetch
		} || {
			printf -v EXTRA "[%-25.25s]" "no remotes available"		# no, we dont
		}
		
		GIT_STATUS="$(git status 2>&1 )"							# git output
		GIT_EXIT=$?													# git exit code
		#
		if [ $GIT_EXIT -eq 0 ]										# everyithing ok
		then
			#
			#	ok, no errors. let's check if there's something to do
			#
			if echo "${GIT_STATUS}" | tr $'\n' ' ' | "${REGEX_DIR}/regex-tester.sh" "${REGEX_DIR}/up-to-date.regex"
			then
				#
				#	nothing to do, repo up-to-date
				#
				printf -v STATUS "$(echolor -f black -b green "%-25.25s")" ok
				info "${TAG}${STATUS}${EXTRA}"
			elif echo "${GIT_STATUS}" | tr $'\n' ' ' | "${REGEX_DIR}/regex-tester.sh" "${REGEX_DIR}/behind-pull.regex"
			then
				#
				#	something to do
				#
				printf -v STATUS "$(echolor -f black -b yellow "%-25.25s")" "PULL needed"
				info "${TAG}${STATUS}${EXTRA}"
				
				if [ "$PULL_ENABLED" = "true" ]
				then
					git pull && {
						printf -v STATUS "$(echolor -f black -b green "%-25.25s")" "PULL ok"
					info "${TAG}${STATUS}${EXTRA}"
					} || {
						printf -v STATUS "$(echolor -f black -b red "%-25.25s")" "PULL ERROR"
						info "${TAG}${STATUS}${EXTRA}"
					}
				else
					echo "----------------------------------------------------------------------------"
					git status
					echo "----------------------------------------------------------------------------"
				fi
			elif echo "${GIT_STATUS}" | tr $'\n' ' ' | "${REGEX_DIR}/regex-tester.sh" "${REGEX_DIR}/ahead-push.regex"
			then
				printf -v STATUS "$(echolor -f black -b yellow "%-25.25s")" "PUSH needed"
				info "${TAG}${STATUS}${EXTRA}"
			else
				#
				#	something to do
				#
				printf -v STATUS "$(echolor -f black -b yellow "%-25.25s")" "check messages"
				info "${TAG}${STATUS}${EXTRA}"
				echo "----------------------------------------------------------------------------"
				git status
				echo "----------------------------------------------------------------------------"

				if [ "$STOP_AT_FIRST" = "true" ]
				then
					echo "STOP_AT_FIRST ENABLED (GIT_EXIT=$GIT_EXIT)"
					echo "exiting"
					exit 1
				fi
			fi
		else
			#
			#	ERROR!!!!
			#
			printf -v STATUS "$(echolor -f black -b red "%-25.25s")" "something's wrong"
			# echo  -e "${TAG}${STATUS}${EXTRA}\n"
			error "${TAG}${STATUS}${EXTRA}"
			echo "----------------------------------------------------------------------------"
			git status
			echo "----------------------------------------------------------------------------"
			
			if [ "$STOP_AT_FIRST" = "true" ]
			then
				info "STOP_AT_FIRST ENABLED (GIT_EXIT=$GIT_EXIT)"
				info "exiting"
				exit 1
			fi
		fi
	) || exit 1
	#
	#	end subshell, nothing happened
	#
done

