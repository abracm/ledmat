#!/bin/sh
set -eu

awk '
BEGIN {
	ret = 0
	msg = "function not on the start of the line:"
}

/^[a-zA-Z0-9_]+ [^=]+\(/ {
	if (ret == 0) {
		print msg
	}
	printf "%s:%s:%s\n", FILENAME, FNR, $0
	ret = 1
}

END {
	exit ret
}
' "$@"


awk '
BEGIN {
	ret = 0
	static = 1
	msg = "non-static function is not declared in a header:"
}

/^[a-zA-Z0-9_]+\(.*$/ && static == 0 {
	split($0, line, /\(/)
	fn_name = line[1]
	if (fn_name != "main" && fn_name != "LLVMFuzzerTestOneInput") {
		header = substr(FILENAME, 0, length(FILENAME) - 2)  ".h"
		if (system("grep -q ^\"" fn_name "\" \"" header "\"")) {
			if (ret == 0) {
				print msg
			}
			printf "%s:%s:%s\n", FILENAME, FNR, $0
			ret = 1
		}
	}
}

/^static / {
	static = 1
}

!/^static / {
	static = 0
}

END {
	exit ret
}
' "$@"


RE='[a-z]+\(\) {'
if grep -Eq "$RE" "$@"; then
	echo 'Functions with no argument without explicit "void" parameter:' >&2
	grep -En "$RE" "$@"
	exit 1
fi
