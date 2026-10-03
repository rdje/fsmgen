#!/bin/bash
set -u
B=docs/audits/prepared-reservation-cause-repair-20261003
C=docs/audits/prepared-reservation-cause-checks-20261003
python3 "$B/verify.py" > "$C/cold.txt" 2>&1 || exit 1
for mode in trust-prior trust-bypass; do
 python3 "$B/verify.py" --"$mode" > "$C/$mode-red.txt" 2>&1
 status=$?;echo "$status" > "$C/$mode-red.status";test "$status" -eq 1 || exit 1
done
prove -Iperl t/1937-isf-formal-reservation-products.t t/1957-isf-formal-domain-reservation-integration.t > "$C/regression.txt" 2>&1 || exit 1
echo 'PASS independent cause repair, actual prior/bypass RED and focused reservation/domain checks.'
