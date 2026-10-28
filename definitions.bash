#!/bin/bash

echo "This script is meant to be sourced from other scripts; it is not meant to be directly executed."

set -o errexit # Fail if any command has a non-zero exit status. Equivalent to `-e`. PEARL: it still won't fail if any of the following `set` commands fails.
set -o nounset # Fail if an undefined variable is referenced. Equivalent to `-u`.
set -o pipefail # Prevent pipelines from masking errors. (Use `command1 | command2 || true` to mask.)
shopt -s inherit_errexit # [Claude] PEARL: without this, `errexit` is off inside `$(…)`, so a failing command in a function called via `$(…)` does not stop that function.
set -C # do not overwrite an existing file when redirecting. use `>|` instead of `>` to override.
shopt -s expand_aliases # Do not ignore aliases. (What kind of idiot made ignoring aliases the default behavior?)
#shopt -s extglob # enable extended pattern matching.

PS4='+ $LINENO: ' # See https://stackoverflow.com/a/17805088/773113
# set -x # enable echoing commands for the purpose of troubleshooting.

alias info='log "${BASH_SOURCE[0]}" $LINENO INFO'
alias warn='log "${BASH_SOURCE[0]}" $LINENO WARN'
alias error='log "${BASH_SOURCE[0]}" $LINENO ERROR'

function log()
{
	local -; set +x
	declare self
	self=$(realpath --relative-to="$PWD" "$1"); shift
	declare -r self
	declare -r line=$1; shift
	declare -r level=$1; shift
	declare -r message=$*
	
	# [Claude] Write to stderr, because a function called via `$(…)` would otherwise capture its own error messages into its result.
	printf "%s(%s): %s: %s\n" "$self" "$line" "$level" "$message" >&2
}

function increment_version()
{
	declare -r version=$1
	declare part_to_increment=${2-}

	if [[ "$part_to_increment" == "" ]]; then
		part_to_increment="patch"
	fi
	
	declare -i major
	declare -i minor
	declare -i patch
	IFS=. read -r major minor patch <<< "$version"
	case "$part_to_increment" in
		"major")
			major=$((major+1))
			minor=0
			patch=0
			;;
		"minor")
			minor=$((minor+1))
			patch=0
			;;
		"patch")
			patch=$((patch+1))
			;;
		*)
			error "Invalid increment: '$part_to_increment'; expected 'major', 'minor', or 'patch' (the default)"
			exit 1
	esac
	printf "%s.%s.%s" "$major" "$minor" "$patch"
}

function assert_no_untracked_files()
{
	declare untracked_files
	untracked_files=$(git ls-files -o --directory --exclude-standard --no-empty-directory)
	declare -r untracked_files
	if [ "$untracked_files" != "" ]; then
		error "You have untracked files!"
		info $untracked_files
		info "Please add, stage, and commit first."
		return 1
	fi
}

function assert_no_tracked_but_unstaged_changes()
{
	declare unstaged_files
	unstaged_files=$(git diff-files --name-only)
	declare -r unstaged_files
	if [ "$unstaged_files" != "" ]; then
		error "You have tracked but unstanged changes!"
		info "$unstaged_files"
		info "Please stage and commit first."
		return 1
	fi
}

function assert_no_staged_but_uncommitted_changes()
{
	declare uncommitted_files
	uncommitted_files=$(git diff-index --name-only --cached HEAD)
	declare -r uncommitted_files
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
	declare value
	value=$(sed -ne "/$element/{s/.*<$element>\(.*\)<\/$element>.*/\1/p;q;}" "$file")

	if [[ -z "$value" ]]; then
		value="$default"
	fi

	printf "%s" "$value"
}

function git_get_last_commit_message()
{
	# PEARL: as the case is with virtually all git commands, the git command that prints the last commit message looks
	#   absolutely nothing like a command that would print the last commit message. Linus Torvalds you are not just a
	#   geek, you are a fucking dork.
	# from https://stackoverflow.com/a/7293026/773113
	# and https://stackoverflow.com/questions/7293008/display-last-git-commit-comment#comment105325732_7293026
	git log -1 --pretty=format:%B
}

function run_this_script_in_its_directory()
{
	declare directory
	directory=$(realpath "$0")
	directory=$(dirname "$directory")
	declare -r directory
	if [[ "$directory" != "$PWD" ]]; then
		(cd "$directory"; bash $(basename $0) "$@")
		exit $?
	fi
}

function join
{
	declare -r delimiter=$1
	shift

	declare result=""
	declare delimiter_to_use=""
	while [ $# -gt 0 ]; do
		if [[ ! -z "$1" ]]; then
			printf "%s%s" "$delimiter_to_use" "$1"
			delimiter_to_use="$delimiter"
		fi
		shift
	done
}
