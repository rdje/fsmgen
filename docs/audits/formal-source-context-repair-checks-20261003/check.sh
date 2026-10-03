#!/bin/bash
set -u
B=docs/audits/formal-source-context-cause-repair-20261003
C=docs/audits/formal-source-context-repair-checks-20261003
python3 "$B/verify.py" > "$C/cold.txt" 2>&1 || exit 1
for mode in prior-consumer binding-bypass; do
 python3 "$B/verify.py" --"$mode" > "$C/$mode-cold-red.txt" 2>&1
 status=$?
 echo "$status" > "$C/$mode-cold-red.status"
 test "$status" -eq 1 || exit 1
done
prove -Iperl -It/lib t/1933-isf-caller-formal-binding-scope.t t/1935-isf-local-declaration-admission.t t/1936-isf-formal-source-context.t t/1941-isf-formal-preallocation-admission.t t/2056-isf-formal-source-context-diagnostic-causes.t > "$C/regression.txt" 2>&1 || exit 1
prove -Iperl -It/lib t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t > "$C/focused.txt" 2>&1 || exit 1
knowledge-map/scripts/check_knowledge_map.sh > "$C/knowledge.txt" 2>&1 || exit 1
echo 'PASS cold/prior/bypass/focused regression/book/Knowledge Map checks.'
