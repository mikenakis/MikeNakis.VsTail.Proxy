#!/bin/bash

if ! source $(dirname "$0")/definitions.bash > /dev/null; then exit 1; fi

declare -r version_file_pathname=$(dirname "$0")/version.txt

function run()
{
	declare branch
	branch=$(git branch --show-current)
	if [[ $branch == master ]]; then
		branch=""
	fi

	if [[ ! -f $version_file_pathname ]]; then
		error "File not found: '$version_file_pathname'"
		exit 1
	fi

	declare version
	version=$(cat "$version_file_pathname")
	declare -r version
	declare prefix
	declare pre_release
	IFS=- read -r prefix pre_release <<< "$version"

	join "-" "$prefix" "$branch" "$pre_release"
}

run $@
