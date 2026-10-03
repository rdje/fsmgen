#!/bin/bash
set -u
B=docs/audits/prepared-reservation-snapshot-repair-20261003
C=docs/audits/prepared-reservation-snapshot-repair-checks-20261003
python3 "$B/verify.py" > "$C/cold.txt" 2>&1 || exit 1
for mode in trust-prior-copy trust-mutation; do
 python3 "$B/verify.py" --"$mode" > "$C/$mode-red.txt" 2>&1
 status=$?;printf '%s\n' "$status" > "$C/$mode-red.status"
 test "$status" -eq 1 || exit 1
done
prove -Iperl t/1937-isf-formal-reservation-products.t t/1957-isf-formal-domain-reservation-integration.t > "$C/regression.txt" 2>&1 || exit 1
printf 'PASS independent whole snapshot repair, genuine prior/mutation safety RED and focused reservation/domain regressions.\n'
