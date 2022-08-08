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
#
#	colorful colors, yay...
#
function ansi_escape()
{
	# local code="${1}"
	
	for code
	do
		echo -n "\e[${code}m"
	done
}

readonly ANSI_RESET=0
readonly ANSI_LIGHT=1
readonly ANSI_DARK=0

readonly ANSI_FG=3
readonly ANSI_BG=4
readonly ANSI_REVERSE=7

readonly ANSI_RED=1
readonly ANSI_GREEN=2
readonly ANSI_YELLOW=3

readonly COLOR_RESET="$(ansi_escape ${ANSI_RESET})"
readonly COLOR_LIGHT_RED="$(ansi_escape ${ANSI_LIGHT} ${ANSI_FG}${ANSI_RED})"
readonly COLOR_LIGHT_GREEN="$(ansi_escape ${ANSI_LIGHT} ${ANSI_FG}${ANSI_GREEN})"
readonly COLOR_LIGHT_YELLOW="$(ansi_escape ${ANSI_LIGHT} ${ANSI_FG}${ANSI_YELLOW})"

readonly COLOR_REV_RED="$(ansi_escape ${ANSI_REVERSE})${COLOR_LIGHT_RED}"
readonly COLOR_REV_GREEN="$(ansi_escape ${ANSI_REVERSE})${COLOR_LIGHT_GREEN}"
readonly COLOR_REV_YELLOW="$(ansi_escape ${ANSI_REVERSE})${COLOR_LIGHT_YELLOW}"

function color()
{
	local _intensity="${1^^}"
	shift
	local _color="${1^^}"
	shift
	local _text="$*"
	
	local _color_name="COLOR_${_intensity}_${_color}"
	
	[[ -v ${_color_name} ]] || {
		echo "FATAL | unknow color ${_color_name}"
		exit 255
	}
	
	echo "${!_color_name}${_text}${COLOR_RESET}"
	
}

# HERE="$(dirname ${BASH_SOURCE[0]})"

HERE="$(dirname ${BASH_SOURCE[0]})"
if which realpath
then
	HERE="$(realpath ${HERE})"
elif which readlink
then
	HERE="$(readlink -f ${HERE})"
else
	echo "FATAL | cannot determine script absolute path"
	exit 255
fi
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
# for DIR in */.git
for DIR in "${PATHS[@]}"
do
	# just the dir name
	# DIR="${DIR%%/*}"
	# formatted [dir name]
	printf -v TAG "[%-60.60s]" "$DIR"
	# subshell
	(
		unset EXTRA
		# let's move into
		cd "$DIR"
		# do we have remotes?
		[ "$(git remote -v)" != "" ] && {
			# yes, then we fetch
			git fetch > /dev/null
		} || {
			# no, we dont
			#EXTRA="${COLOR_REV_RED}* no remotes available * ${COLOR_OFF}"
			printf -v EXTRA "[%-25.25s]" "no remotes available"
		}
		GIT_STATUS="$(git status 2>&1 )"	# git output
		GIT_EXIT=$?							# git exit code
		#
		if [ $GIT_EXIT -eq 0 ]				# everyithing ok
		then
			#
			#	ok, no errors. let's check if there's something to do
			#
			if echo "${GIT_STATUS}" | tr $'\n' ' ' | "${REGEX_DIR}/regex-tester.sh" "${REGEX_DIR}/up-to-date.regex"
			then
				#
				#	nothing to do, repo up-to-date
				#
				# printf "$TAG	${COLOR_REV_GREEN}%-25.25s${COLOR_OFF}${EXTRA}\n" "ok"
				printf "$TAG	"
				printf -v STATUS "%-25.25s" "ok"
				echo "'$STATUS'"
				printf "$(color rev green "${STATUS}     ")"
				printf "${EXTRA}\n"
				exit
			# else
				#
				#	ok, no errors. let's check if there's something to do
				#
			elif echo "${GIT_STATUS}" | tr $'\n' ' ' | "${REGEX_DIR}/regex-tester.sh" "${REGEX_DIR}/behind-pull.regex"
			then
				#
				#	something to do
				#
				if [ "$PULL_ENABLED" = "true" ]
				then
					printf "$TAG	${COLOR_REV_YELLOW}%-25.25s${COLOR_OFF}${EXTRA}\n" "PULL needed"
					git pull && {
						printf "$TAG	${COLOR_REV_GREEN}%-25.25s${COLOR_OFF}${EXTRA}\n" "PULL OK"
					} || {
						printf "$TAG	${COLOR_REV_RED}%-25.25s${COLOR_OFF}${EXTRA}\n" "PULL ERROR"
					}
				else
					printf "$TAG	${COLOR_REV_YELLOW}%-25.25s${COLOR_OFF}${EXTRA}\n" "PULL needed"
					echo "----------------------------------------------------------------------------"
					git status
					echo "----------------------------------------------------------------------------"
				fi
			elif echo "${GIT_STATUS}" | tr $'\n' ' ' | "${REGEX_DIR}/regex-tester.sh" "${REGEX_DIR}/ahead-push.regex"
			then
				printf "$TAG	${COLOR_REV_YELLOW}%-25.25s${COLOR_OFF}${EXTRA}\n" "PUSH needed"
			else
				#
				#	something to do
				#
				printf "$TAG	${COLOR_REV_YELLOW}%-25.25s${COLOR_OFF}${EXTRA}\n" "check messages"
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
			printf "$TAG	${COLOR_REV_RED}%-25.25s${COLOR_OFF}${EXTRA}\n" "something's wrong"
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

