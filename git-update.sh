#!/usr/bin/env bash
###############################################################################
#
#	gitupdate.sh
#
#	- 	iterates over each subdirectory of path parameters or TODO: current path
#		if it contains a .git subfolder then performs:
#			- git fetch
#			- git status
#		based on git status result displays colored status line
#		if the repo needs pull/add/commit/... it displays git output
#
#########################################################################################
HERE="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"	# get current path
. "${HERE}/.setup"												# load modules
HERE="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"	# get current path
NAME="$(basename ${BASH_SOURCE[0]})"							# save this script name
#########################################################################################
REGEX_DIR="${HERE}/regex-sandbox"
PULL_ENABLED="false"
STOP_AT_FIRST="false"
TAG_WIDTH=30
EXTRA_WIDTH=30
STATUS_WIDTH=15
#########################################################################################
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
#########################################################################################
PATHS=()
for arg										# loop through remaining params
do
	if [ -d "${arg}"/.git ]					# if param/.git is a directory
	then
		PATHS+=( "${arg}" )					# add path to PATHS array
		info "PATH | ${arg}"
	else
		warn "path ${arg} is not a git repo, ignoring"
	fi
done

function git_uptodate()
{
	[ $# -gt 0 ] || {
		fatal "git_uptodate | expected 1 parameter"
		exit 255
	}
	echo "${*}" | "${REGEX_DIR}/regex-tester.sh" "${REGEX_DIR}/up-to-date.regex"
}

function git_behindpull()
{
	[ $# -gt 0 ] || {
		fatal "git_behindpull | expected 1 parameter"
		exit 255
	}
	echo "${*}" | "${REGEX_DIR}/regex-tester.sh" "${REGEX_DIR}/behind-pull.regex"
}

function git_aheadpush()
{
	[ $# -gt 0 ] || {
		fatal "git_aheadpush | expected 1 parameter"
		exit 255
	}
	echo "${*}" | "${REGEX_DIR}/regex-tester.sh" "${REGEX_DIR}/ahead-push.regex"
}
#########################################################################################
#
#	main loop
#
echo
for DIR in "${PATHS[@]}"
do
	printf -v TAG "[%-*.*s]" ${TAG_WIDTH} ${TAG_WIDTH} "$DIR"		# formatted [dir name]
	#
	# begin subshell
	#
	(
		unset EXTRA
		cd "$DIR"													# let's move into
		
		[ "$(git remote -v)" != "" ] && {							# do we have remotes?
			git fetch > /dev/null									# yes, then we fetch
		} || {
			printf -v EXTRA "[%-*.*s]" ${EXTRA_WIDTH} ${EXTRA_WIDTH} "no remotes available"		# no, we dont
		}
		
		GIT_STATUS="$(git status 2>&1 )"							# git output
		GIT_EXIT=$?													# git exit code
		GIT_STATUS="$(echo "${GIT_STATUS}" | tr $'\n' ' ')"			# normalize git output
		#
		if [ $GIT_EXIT -eq 0 ]										# everyithing ok
		then
			#
			#	ok, no errors. let's check if there's something to do
			#
			if  git_uptodate "${GIT_STATUS}"
			then
				#
				#	nothing to do, repo up-to-date
				#
				printf -v STATUS "$(echolor -f black -b green "%-*.*s")" ${STATUS_WIDTH} ${STATUS_WIDTH} ok
				info "${TAG}${STATUS}${EXTRA}"
			elif git_behindpull "${GIT_STATUS}"
			then
				#
				#	something to do
				#
				printf -v STATUS "$(echolor -f black -b yellow "%-*.*s")" ${STATUS_WIDTH} ${STATUS_WIDTH} "PULL needed"
				info "${TAG}${STATUS}${EXTRA}"
				
				if [ "$PULL_ENABLED" = "true" ]
				then
					git pull && {
						printf -v STATUS "$(echolor -f black -b green "%-*.*s")" ${STATUS_WIDTH} ${STATUS_WIDTH} "PULL ok"
					info "${TAG}${STATUS}${EXTRA}"
					} || {
						printf -v STATUS "$(echolor -f black -b red "%-*.*s")" ${STATUS_WIDTH} ${STATUS_WIDTH} "PULL ERROR"
						info "${TAG}${STATUS}${EXTRA}"
					}
				else
					echo "----------------------------------------------------------------------------"
					git status
					echo "----------------------------------------------------------------------------"
				fi
			# elif echo "${GIT_STATUS}" | "${REGEX_DIR}/regex-tester.sh" "${REGEX_DIR}/ahead-push.regex"
			elif git_aheadpush "${GIT_STATUS}"
			then
				printf -v STATUS "$(echolor -f black -b yellow "%-*.*s")" ${STATUS_WIDTH} ${STATUS_WIDTH} "PUSH needed"
				info "${TAG}${STATUS}${EXTRA}"
			else
				#
				#	something else to do
				#
				printf -v STATUS "$(echolor -f black -b yellow "%-*.*s")" ${STATUS_WIDTH} ${STATUS_WIDTH} "check messages"
				info "${TAG}${STATUS}${EXTRA}"
				echo "----------------------------------------------------------------------------"
				git status
				echo "----------------------------------------------------------------------------"

				if [ "$STOP_AT_FIRST" = "true" ]
				then
					echo "STOP_AT_FIRST ENABLED (GIT_EXIT=$GIT_EXIT)"
					echo "exiting"
					exit 0
				fi
			fi
		else
			#
			#	ERROR!!!!
			#
			printf -v STATUS "$(echolor -f black -b red "%-*.*s")" ${STATUS_WIDTH} ${STATUS_WIDTH} "something's wrong"
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

