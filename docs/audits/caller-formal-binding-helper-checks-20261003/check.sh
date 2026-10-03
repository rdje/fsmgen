#!/bin/bash
set -u
B=docs/audits/caller-formal-binding-helper-causes-20261003
C=docs/audits/caller-formal-binding-helper-checks-20261003
python3 "$B/verify.py" > "$C/cold.txt" 2>&1 || exit 1
python3 "$B/verify.py" --trust-current > "$C/trust-current-red.txt" 2>&1
status=$?
echo "$status" > "$C/trust-current-red.status"
test "$status" -eq 1 || exit 1
echo 'PASS cold and actual current-consumer RED1.'
