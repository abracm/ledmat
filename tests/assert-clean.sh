#!/bin/sh
set -eu

if [ ! -e .git ]; then
	echo "Not in a Git repository, skipping \"$0\"" >&2
	exit
fi

if [ -n "$(git status -s)" ]; then
	echo "Repository is already dirty, skipping \"$0\"" >&2
	exit
fi

if [ -n "$(git clean -nffdx)" ]; then
	echo "Already contains untracked files, skipping \"$0\"" >&2
	exit
fi


. tools/lib.sh

R="$(mkdtemp)"
trap 'rm -rf "$R"' EXIT

cp -pR ./ "$R"
cd "$R"


{
	make -s clean

	printf '%s: "clean" target deletes all derived assets...' \
		"$(yellow "$0")"

	if [ -n "$(git status -s)" ]; then
		printf ' ERR.\n'
		echo 'Repository left dirty:'
		git status
		exit 1
	fi

	if [ -n "$(git clean -nffdx)" ]; then
		printf ' ERR.\n'
		echo 'Untracked files left:'
		git clean -ffdx --dry-run
		exit 1
	fi

	printf ' %s\n' "$(green 'OK')"
} >&2
