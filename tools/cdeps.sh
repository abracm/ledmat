#!/bin/sh
set -eu

. tools/lib.sh

usage() {
	cat <<-'EOF'
		Usage:
		  tools/cdeps.sh FILE...
		  tools/cdeps.sh -h
	EOF
}

help() {
	cat <<-'EOF'


		Options:
		  -h, --help    show this message

		  FILE          toplevel entrypoint file


		Given a list of C FILEs, generate the Makefile dependencies
		between them.

		We have 3 types of object files:
		- .o: plain object files;
		- .lo: object files compiled as relocatable so it can be
		  included in a shared library;
		- .to: compiled with -DTEST so it can expose its embedded unit
		  tests;

		We also have 2 aggregate files:
		- .ta: an ar(1)-chive that includes all the .o dependencies the
		  $NAME.ta, plus the $NAME.to object.  The goal is to have
		  "dep1.o", "dep2.o", ... "depN.o" included in the archive,
		  alongside "$NAME.to", so that recompiling "depN.o" would
		  replace only this file in the archive;
		- .t: an executable "$NAME.t" derived from just linking together
		  all the objects inside a ".ta".  Since the "main()" function
		  was only exposed in the "$NAME.to" via the -DTEST flag, this
		  executable is the runnable instance of all unit tests present
		  in "$NAME.c".  Its exit code determines if its test suite
		  execution is successful.

		Also in order to run the unit tests without having to relink
		them on each run, we have:
		- .t-run: a dedicated virtual target that does nothing but
		  execute the tests.  In order to assert the binaries exist,
		  each "$NAME.t-run" virtual target depends on the equivalent
		  "$NAME".t physical target.

		There are 2 types of dependencies that are generated:
		1. self dependencies;
		2. inter dependencies.

		The self dependencies are the ones across different
		manifestations of the same file so all derived assets are
		correctly kept up-to-date:
		- $NAME.o $NAME.lo $NAME.to: $NAME.h

		  As the .SUFFIXES rule already covers the dependency to the
		  orinal $NAME.c file, all we do is say that whenever the public
		  interface of these binaries change, they need to be
		  recompiled;
		- $NAME.ta: $NAME.to

		  We make sure to include in each test archive (ta) file its own
		  binary with unit tests.  We include the "depN.o" dependencies
		  later;
		- $NAME.t-run: $NAME.t

		  Enforce that the binary exists before we run them.

		After we establish the self dependencies, we scrub each file's
		content looking for `#include "..."` lines that denote
		dependency to other C file.  Once we do that we'll have:
		- $NAME.o $NAME.lo $NAME.to: dep1.h dep2.h ... depN.h

		  We'll recompile our file when its public header changes.  When
		  only the body of the code changes we don't recompile, only
		  later relink;
		- $NAME.ta: dep1.o dep2.o ... depN.o

		  Make sure to include all required dependencies in the $NAME.t
		  binary so that the later linking works properly.

		So if we have file1.c, file2.c and file3.c with their respective
		headers, where file2.c and file3.c depend of file1.c, i.e. they
		have `#include "file.h"` in their code, and file3.c depend of
		file2.c, the expected output is:

		  file1.o file1.lo file1.to: file1.h
		  file2.o file2.lo file2.to: file2.h
		  file3.o file3.lo file3.to: file3.h

		  file1.ta: file1.to
		  file2.ta: file2.to
		  file3.ta: file3.to

		  file1.t-run: file1.t
		  file2.t-run: file2.t
		  file3.t-run: file3.t


		  file1.o file1.lo file1.to:
		  file2.o file2.lo file2.to: file1.h
		  file3.o file3.lo file3.to: file1.h file2.h

		  file1.ta:
		  file2.ta: file1.o
		  file3.ta: file1.o file2.o

		This ensures that only the minimal amount of files need to get
		recompiled, but no less.


		Examples:

		  Get deps for all files in 'src/' but 'src/main.c':

		    $ sh tools/cdeps.sh `find src/*.c -not -name 'main.c'`


		  Emit dependencies for all C files in a Git repository:

		    $ sh tools/cdeps.sh `git ls-files | grep '\.c$'`
	EOF
}


for flag in "$@"; do
	case "$flag" in
		(--)
			break
			;;
		(--help)
			usage
			help
			exit
			;;
		(*)
			;;
	esac
done

while getopts 'h' flag; do
	case "$flag" in
		(h)
			usage
			help
			exit
			;;
		(*)
			usage >&2
			exit 2
			;;
	esac
done
shift $((OPTIND - 1))

FILE="${1:-}"
eval "$(assert_arg "$FILE" 'FILE')"



each_f() {
	fn="$1"
	shift
	for file in "$@"; do
		f="${file%.c}"
		"$fn" "$f"
	done
	printf '\n'
}

self_header_deps() {
	printf '%s.o\t%s.lo\t%s.to:\t%s.h\n' "$1" "$1" "$1" "$1"
}

self_ta_deps() {
	printf '%s.ta:\t%s.to\n' "$1" "$1"
}

self_trun_deps() {
	printf '%s.t-run:\t%s.t\n' "$1" "$1"
}

deps_for() {
	ext="$2"
	for file in $(awk -F'"' '/^#include "/ { print $2 }' "$1.c"); do
		if [ "$file" = 'config.h' ]; then
			continue
		fi
		if [ "$(basename "$file")" = 'tests-lib.h' ]; then
			continue
		fi
		f="$(dirname "$1")/$file"
		if [ "$f" = "$1.h" ]; then
			continue
		fi
		printf '%s\n' "${f%.h}$2"
	done
}

rebuild_deps() {
	printf '\n'
	printf '%s.o\t%s.lo\t%s.to:' "$1" "$1" "$1"
	printf ' %s' $(deps_for "$1" .h) | sed 's| *$||'
}

archive_deps() {
	printf '\n'
	printf '%s.ta:' "$1"
	printf ' %s' $(deps_for "$1" .o) | sed 's| *$||'
}


each_f self_header_deps "$@"
each_f self_ta_deps     "$@"
each_f self_trun_deps   "$@"

each_f rebuild_deps     "$@"
each_f archive_deps     "$@"
