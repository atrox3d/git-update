#!/usr/bin/env bash

# for repo in */.git;do repo=${repo%/.git};echo $repo;git -C $repo status ;done

# repos=( */.git ) && repos=( "${repos[@]%/.git}" )
repos=( */.git ) && repos=( "${repos[@]%/.git}" );printf '%s\n' "${repos[@]}"

options=(
	--a # test
	--b # x
	--c #
)
echo ${options[@]}
