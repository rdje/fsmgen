#!/bin/bash
set -u
B=docs/audits/formal-resource-cause-repair-20261003
C=docs/audits/formal-resource-repair-checks-20261003
python3 "$B/verify.py" > "$C/cold.txt" 2>&1 || exit 1
for mode in prior-helper prior-direct resource-bypass; do
 python3 "$B/verify.py" --"$mode" > "$C/$mode-cold-red.txt" 2>&1
 status=$?;echo "$status" > "$C/$mode-cold-red.status"
 test "$status" -eq 1 || exit 1
done
prove -Iperl -It/lib t/1218-isf-rule-slot-resource-arbitration.t t/1943-isf-formal-point-products.t t/1948-isf-formal-arbitration-namespace.t > "$C/regression.txt" 2>&1 || exit 1
echo 'PASS independent current/prior/bypass closure and focused resource regression.'
