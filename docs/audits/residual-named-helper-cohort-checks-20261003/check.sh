#!/bin/bash
set -u
B=docs/audits/residual-named-helper-cohorts-20261003
C=docs/audits/residual-named-helper-cohort-checks-20261003
python3 "$B/verify.py" > "$C/cold.txt" 2>&1 || exit 1
for mode in trust-prior-sources trust-prior-row-owners; do
 python3 "$B/verify.py" --"$mode" > "$C/$mode-red.txt" 2>&1
 status=$?;echo "$status" > "$C/$mode-red.status"
 test "$status" -eq 1 || exit 1
done
echo 'PASS independent current ownership and real prior-source/row-owner counterfactuals.'
