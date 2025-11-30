#!/bin/bash

echo "This script is meant to be sourced from other scripts; it is not meant to be directly executed."

set -o errexit # Fail if any command has a non-zero exit status. Equivalent to `-e`. PEARL: it still won't fail if any of the following `set` commands fails.
set -o nounset # Fail if an undefined variable is referenced. Equivalent to `-u`.
set -o pipefail # Prevent pipelines from masking errors. (Use `command1 | command2 || true` to mask.)
set -C # do not overwrite an existing file when redirecting. use `>|` instead of `>` to override.
shopt -s expand_aliases # Do not ignore aliases. (What kind of idiot made ignoring aliases the default behavior?)
#shopt -s extglob # enable extended pattern matching.

PS4='+ $LINENO: ' # See https://stackoverflow.com/a/17805088/773113
# set -x # enable echoing commands for the purpose of troubleshooting.

declare -r global_self=$(realpath --relative-to="$PWD" "$0")

alias info='log "$global_self" $LINENO INFO'
alias warn='log "$global_self" $LINENO WARN'
alias error='log "$global_self" $LINENO ERROR'

function log()
{
	declare -r self=$1; shift
	declare -r line=$1; shift
	declare -r level=$1; shift
	declare -r message=$*
	
	printf "%s(%s): %s: %s\n" "$self" "$line" "$level" "$message"
}

function increment_version()
{
	declare -r part_to_increment=$1
	declare -r version=$2

	declare -i major
	declare -i minor
	declare -i patch
	IFS=. read -r major minor patch <<< "$version"
	case "$part_to_increment" in
		"increment_major")
			major=$((major+1))
			minor=0
			patch=0
			;;
		"increment_minor")
			minor=$((minor+1))
			patch=0
			;;
		"increment_patch")
			patch=$((patch+1))
			;;
		*)
			error "Invalid argument: '$part_to_increment'"
			exit 1
	esac
	printf "%s.%s.%s" "$major" "$minor" "$patch"
}

function assert_no_untracked_files()
{
	declare -r untracked_files=$(git ls-files -o --directory --exclude-standard --no-empty-directory)
	if [ "$untracked_files" != "" ]; then
		error "You have untracked files!"
		info $untracked_files
		info "Please add, stage, and commit first."
		return 1
	fi
}

function assert_no_tracked_but_unstaged_changes()
{
	declare -r unstaged_files=$(git diff-files --name-only)
	if [ "$unstaged_files" != "" ]; then
		error "You have tracked but unstanged changes!"
		info "$unstaged_files"
		info "Please stage and commit first."
		return 1
	fi
}

function assert_no_staged_but_uncommitted_changes()
{
	declare -r uncommitted_files=$(git diff-index --name-only --cached HEAD)
	if [ "$uncommitted_files" != "" ]; then
		error "You have staged but uncommitted changes!"
		info "$uncommitted_files"
		info "Please unstage or commit first."
		return 1
	fi
}

function remove_if_exists()
{
	declare -r pattern=$1

	for i in $pattern; do
		if [ -f "$i" ]; then 
			rm "$i"; 
		fi
	done
}

function get_xml_value()
{
	declare -r file=$1
	declare -r element=$2
	declare -r default=${3-}

	# Voodoo magick from Stack Overflow: "Extract XML Value in bash script" https://stackoverflow.com/a/17334043/773113
	declare -r value=$(cat $file | sed -ne "/$element/{s/.*<$element>\(.*\)<\/$element>.*/\1/p;q;}")

	if [[ -z "$value" ]]; then
		value=default
	fi

	printf $value
}
