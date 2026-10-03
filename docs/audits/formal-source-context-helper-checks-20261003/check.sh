#!/bin/bash
set -u
B=docs/audits/formal-source-context-helper-causes-20261003
C=docs/audits/formal-source-context-helper-checks-20261003
python3 "$B/verify.py" > "$C/cold.txt" 2>&1 || exit 1
python3 "$B/verify.py" --trust-current > "$C/trust-current-red.txt" 2>&1
status=$?
echo "$status" > "$C/trust-current-red.status"
test "$status" -eq 1 || exit 1
prove -Iperl -It/lib t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t > "$C/focused.txt" 2>&1 || exit 1
knowledge-map/scripts/check_knowledge_map.sh > "$C/knowledge.txt" 2>&1 || exit 1
echo 'PASS cold, actual current-consumer RED1, focused book and Knowledge Map.'
