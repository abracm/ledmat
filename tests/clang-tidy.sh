#!/bin/sh
set -eu

. tools/lib.sh

FILE="$1"
shift
shift  # drop the '--'
{
	printf '%s: linting of C files...' "$(yellow "$0")"
	clang-tidy "$FILE" -- "$@"
	printf ' %s\n' "$(green 'OK')"
} >&2
