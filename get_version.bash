#!/bin/bash

source $(dirname "$0")/definitions.bash > /dev/null

declare -r version_file_pathname=$(dirname "$0")/version.txt

function concatenate_with_dash
{
	declare result=""
	declare delimiter=""
	while [ $# -gt 0 ]; do
		if [[ ! -z "$1" ]]; then
			printf "%s%s" "$delimiter" "$1"
			delimiter="-"
		fi
		shift
	done
}

function run()
{
	declare branch=$(git branch --show-current)
	if [[ $branch == master ]]; then
		branch=""
	fi

	if [[ ! -f $version_file_pathname ]]; then
		error "File not found: '%s'" "$version_file_pathname"
		exit 1
	fi

	declare -r version=$(cat "$version_file_pathname")
	declare prefix
	declare pre_release
	IFS=- read -r prefix pre_release <<< "$version"

	concatenate_with_dash "$prefix" "$branch" "$pre_release"
}

run $@
