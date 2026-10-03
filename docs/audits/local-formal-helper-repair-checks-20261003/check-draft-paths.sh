#!/bin/bash
set -u
B=docs/audits/local-formal-helper-cause-repair-20261003
C=docs/audits/local-formal-helper-repair-checks-20261003
run() {
 name=$1
 wanted=$2
 shift 2
 "$@" > "$C/$name.txt" 2>&1
 actual=$?
 echo "$actual" > "$C/$name.status"
 echo "$name: $actual (expected $wanted)"
 test "$actual" -eq "$wanted"
}
run cold 0 python3 "$B/verify.py" || exit 1
run cold-prior-red 1 python3 "$B/verify.py" --prior-helper || exit 1
run cold-bypass-red 1 python3 "$B/verify.py" --source-bypass || exit 1
run regression 0 prove -Iperl -It/lib t/2043-isf-conditional-origin-parser.t t/2044-isf-conditional-origin-source-authority.t t/2045-isf-conditional-origin-file-parser.t t/2046-isf-file-origin-authority.t t/2047-isf-library-document-origin-authority.t t/2048-isf-library-document-origin-forgeries.t t/2049-path-search-autoload-after-chdir.t t/2052-isf-local-formal-origin-authority.t t/2053-isf-origin-constructor-diagnostic-causes.t t/2054-isf-origin-validator-diagnostic-causes.t t/2055-isf-local-formal-helper-diagnostic-causes.t || exit 1
