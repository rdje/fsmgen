#!/bin/bash
set -u
B=docs/audits/formal-resource-helper-causes-20261003
C=docs/audits/formal-resource-helper-checks-20261003
python3 "$B/verify.py" > "$C/cold.txt" 2>&1 || exit 1
for mode in trust-helper trust-first-line-code trust-direct; do
 python3 "$B/verify.py" --"$mode" > "$C/$mode-red.txt" 2>&1
 status=$?;echo "$status" > "$C/$mode-red.status"
 test "$status" -eq 1 || exit 1
done
echo 'PASS independent finite closure and three actual cause-consumer counterfactuals.'
