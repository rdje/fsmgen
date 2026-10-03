#!/bin/bash
set -u
C=docs/audits/reservation-coverage-cause-repair-checks-20261003
python3 "$C/verify.py" > "$C/cold.txt" 2>&1 || exit 1
for mode in trust-prior trust-bypass; do
    python3 "$C/verify.py" --"$mode" > "$C/$mode-red.txt" 2>&1
    result=$?; printf '%s\n' "$result" > "$C/$mode-red.status"
    test "$result" -eq 1 || exit 1
done
prove -Iperl t/1937-isf-formal-reservation-products.t t/1957-isf-formal-domain-reservation-integration.t > "$C/regression.txt" 2>&1 || exit 1
printf 'PASS complete cause repair/whole ordinary conservation, genuine prior/bypass safety RED and focused reservation/domain regressions.\n'
