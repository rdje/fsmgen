#!/bin/bash
set -u
B=docs/audits/caller-formal-binding-cause-repair-20261003
python3 "$B/bind.py" > "$B/bind.txt" 2>&1 || exit 1
FSMGEN_CALLER_BINDING_CAUSE_CAPTURE="$B/current-causes.json" prove -Iperl -It/lib t/1933-isf-caller-formal-binding-scope.t t/2057-isf-caller-formal-binding-diagnostic-causes.t > "$B/current.txt" 2>&1
status=$?;echo "$status" > "$B/current.status";test "$status" -eq 0 || exit 1
perl "$B/prior_probe.pl" > "$B/prior-consumer-red.txt" 2>&1
status=$?;echo "$status" > "$B/prior-consumer-red.status";test "$status" -eq 28 || exit 1
perl "$B/ordinary.pl" > "$B/ordinary.txt" 2>&1
status=$?;echo "$status" > "$B/ordinary.status";test "$status" -eq 0 || exit 1
echo 'PASS current helper, exact prior RED and ordinary products.'
