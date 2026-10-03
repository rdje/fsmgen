#!/bin/bash
set -u
B=docs/audits/prepared-reservation-helper-causes-20261003
C=docs/audits/prepared-reservation-helper-checks-20261003
python3 "$B/verify.py" > "$C/cold.txt" 2>&1 || exit 1
python3 "$B/verify.py" --trust-current > "$C/current-consumer-red.txt" 2>&1
status=$?;echo "$status" > "$C/current-consumer-red.status";test "$status" -eq 1 || exit 1
prove -Iperl t/1937-isf-formal-reservation-products.t t/1957-isf-formal-domain-reservation-integration.t > "$C/regression.txt" 2>&1 || exit 1
echo 'PASS independent current diagnosis, actual current-consumer RED and focused reservations/domains.'
