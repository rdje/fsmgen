#!/bin/bash
set -u
B=docs/audits/prepared-reservation-snapshot-diagnosis-20261003
C=docs/audits/prepared-reservation-snapshot-checks-20261003
python3 "$B/verify.py" > "$C/cold.txt" 2>&1 || exit 1
python3 "$B/verify.py" --trust-mutated > "$C/trust-mutated-red.txt" 2>&1
status=$?;printf '%s\n' "$status" > "$C/trust-mutated-red.status"
test "$status" -eq 1 || exit 1
prove -Iperl -It/lib t/1959-isf-prepared-formal-reservations.t t/2062-isf-prepared-reservation-diagnostic-causes.t > "$C/regression.txt" 2>&1 || exit 1
printf 'PASS cold snapshot diagnosis, real mutation-conservation RED and unchanged checked-reservation regressions.\n'
