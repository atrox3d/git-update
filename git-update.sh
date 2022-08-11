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
HERE="$(dirname ${BASH_SOURCE[0]})"
if which realpath |& /dev/null
then
	HERE="$(realpath ${HERE})"
elif which readlink |& /dev/null
then
	HERE="$(readlink -f ${HERE})"
else
	echo "FATAL | cannot determine script absolute path"
	exit 255
fi
###############################################################################
COLOR_INCLUDE="${HERE}/lib/color.include"
.  "${COLOR_INCLUDE}" || {
	echo "FATAL | cannot source ${COLOR_INCLUDE}"
	exit 255
}
###############################################################################
REGEX_DIR="${HERE}/regex-sandbox"
PULL_ENABLED="false"
STOP_AT_FIRST="false"
PATHS=()

for arg
do
	arg="${arg,,}"							# force lowercase

	case "${arg}" in
	
		"--pull")							# pull from origin
			PULL_ENABLED="true"
			echo "PULL is ENABLED"
		;;
	
		"--first")							# stop at first check (?)
			STOP_AT_FIRST="true"
			echo "STOP_AT_FIRST is ENABLED"
		;;
		
		*)									# path to git repo
			if [ -d "${arg}"/.git ]
			then
				PATHS+=( "${arg}" )
				echo "PATH | ${arg}"
			else
				echo "ERROR | path ${arg} is not a git repo, ignoring"
			fi
	esac
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
				echo  -e "${TAG}${STATUS}${EXTRA}\n"
			elif echo "${GIT_STATUS}" | tr $'\n' ' ' | "${REGEX_DIR}/regex-tester.sh" "${REGEX_DIR}/behind-pull.regex"
			then
				#
				#	something to do
				#
				printf -v STATUS "$(echolor -f black -b yellow "%-25.25s")" "PULL needed"
				echo  -e "${TAG}${STATUS}${EXTRA}\n"
				
				if [ "$PULL_ENABLED" = "true" ]
				then
					git pull && {
						printf -v STATUS "$(echolor -f black -b green "%-25.25s")" "PULL ok"
						echo  -e "${TAG}${STATUS}${EXTRA}\n"
					} || {
						printf -v STATUS "$(echolor -f black -b red "%-25.25s")" "PULL ERROR"
						echo  -e "${TAG}${STATUS}${EXTRA}\n"
					}
				else
					echo "----------------------------------------------------------------------------"
					git status
					echo "----------------------------------------------------------------------------"
				fi
			elif echo "${GIT_STATUS}" | tr $'\n' ' ' | "${REGEX_DIR}/regex-tester.sh" "${REGEX_DIR}/ahead-push.regex"
			then
				printf -v STATUS "$(echolor -f black -b yellow "%-25.25s")" "PUSH needed"
				echo  -e "${TAG}${STATUS}${EXTRA}\n"
			else
				#
				#	something to do
				#
				printf -v STATUS "$(echolor -f black -b yellow "%-25.25s")" "check messages"
				echo  -e "${TAG}${STATUS}${EXTRA}\n"
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
			echo  -e "${TAG}${STATUS}${EXTRA}\n"
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
	) || exit 1
	#
	#	end subshell, nothing happened
	#
done

