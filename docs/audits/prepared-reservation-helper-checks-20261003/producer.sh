#!/bin/bash
set -u
B=docs/audits/prepared-reservation-helper-causes-20261003
perl "$B/probe.pl" > "$B/probe.txt" 2>&1
status=$?;echo "$status" > "$B/probe.status";test "$status" -eq 0 || exit 1
perl "$B/desired.pl" > "$B/desired-red.txt" 2>&1
status=$?;echo "$status" > "$B/desired-red.status";test "$status" -eq 111 || exit 1
prove -Iperl t/1959-isf-prepared-formal-reservations.t > "$B/default.txt" 2>&1 || exit 1
python3 "$B/bind.py" > "$B/bind.txt"
