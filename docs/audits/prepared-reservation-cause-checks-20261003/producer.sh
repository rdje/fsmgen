#!/bin/bash
set -u
B=docs/audits/prepared-reservation-cause-repair-20261003
perl "$B/prior.pl" > "$B/prior-red.txt" 2>&1
status=$?;echo "$status" > "$B/prior-red.status";test "$status" -eq 111 || exit 1
perl "$B/bypass.pl" > "$B/bypass-red.txt" 2>&1
status=$?;echo "$status" > "$B/bypass-red.status";test "$status" -eq 2 || exit 1
perl "$B/bypass_inputs.pl" > "$B/bypass-inputs.txt" 2>&1 || exit 1
python3 "$B/bind.py" > "$B/bind.txt" || exit 1
echo 'PASS exact prior consumer RED and actual shape-membership bypass RED/input captures.'
