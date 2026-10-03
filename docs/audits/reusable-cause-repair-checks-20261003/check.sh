#!/bin/bash
set -u
B=docs/audits/reusable-cause-repair-20261003
C=docs/audits/reusable-cause-repair-checks-20261003
python3 "$B/verify.py" > "$C/cold.txt" 2>&1 || exit 1
for mode in trust-prior trust-bypass; do
 python3 "$B/verify.py" --"$mode" > "$C/$mode-red.txt" 2>&1
 status=$?;echo "$status" > "$C/$mode-red.status";test "$status" -eq 1 || exit 1
done
prove -Iperl -It/lib t/1945-isf-formal-child-products.t t/2059-isf-atl-source-width-kind-preservation.t > "$C/regression.txt" 2>&1 || exit 1
echo 'PASS independent cause repair, actual prior/bypass RED and focused child/caller-kind regressions.'
