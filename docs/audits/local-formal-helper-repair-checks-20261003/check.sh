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
run regression 0 prove -Iperl -It/lib t/2043-isf-conditional-origin-parser.t t/2044-isf-conditional-origin-source-authority.t t/2045-isf-same-source-library-origins.t t/2046-isf-library-document-origin-authority.t t/2047-isf-atl-document-origin-authority.t t/2048-isf-file-document-origin-authority.t t/2049-pathsearch-module-origin.t t/2052-isf-local-formal-origin-authority.t t/2053-isf-constructor-diagnostic-causes.t t/2054-isf-validator-finalizer-diagnostic-causes.t t/2055-isf-local-formal-helper-diagnostic-causes.t || exit 1
run docs 0 prove -Iperl -It/lib t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t || exit 1
run knowledge 0 knowledge-map/scripts/check_knowledge_map.sh || exit 1
