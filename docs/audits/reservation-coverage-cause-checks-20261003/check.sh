#!/bin/bash
set -u
B=docs/audits/reservation-coverage-cause-diagnosis-20261003
C=docs/audits/reservation-coverage-cause-checks-20261003
python3 "$C/verify.py" > "$C/cold.txt" 2>&1 || exit 1
python3 "$C/verify.py" --trust-current-consumer > "$C/trust-current-red.txt" 2>&1
result=$?
printf '%s\n' "$result" > "$C/trust-current-red.status"
test "$result" -eq 1 || exit 1
python3 "$C/trace_coordinates.py" > "$C/trace-coordinates.txt" || exit 1
prove -Iperl t/1937-isf-formal-reservation-products.t t/1957-isf-formal-domain-reservation-integration.t t/1960-isf-formal-reservation-coverage.t > "$C/regression.txt" 2>&1 || exit 1
printf 'PASS native cause/source closure, real consumer safety falsification and focused final-coverage/reservation/domain regressions.\n'
