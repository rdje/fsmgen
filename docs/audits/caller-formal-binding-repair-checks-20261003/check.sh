#!/bin/bash
set -u
B=docs/audits/caller-formal-binding-cause-repair-20261003
C=docs/audits/caller-formal-binding-repair-checks-20261003
python3 "$B/verify.py" > "$C/cold.txt" 2>&1 || exit 1
for mode in prior-consumer binding-bypass; do
 python3 "$B/verify.py" --"$mode" > "$C/$mode-cold-red.txt" 2>&1
 status=$?;echo "$status" > "$C/$mode-cold-red.status"
 test "$status" -eq 1 || exit 1
done
prove -Iperl -It/lib t/1241-isf-transaction-port-bindings.t t/1243-isf-port-binding-schedule-report.t t/1936-isf-formal-source-context.t t/2056-isf-formal-source-context-diagnostic-causes.t > "$C/regression.txt" 2>&1 || exit 1
echo 'PASS independent current/prior/bypass and focused binding regression.'
