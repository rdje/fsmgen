#!/bin/bash
set -u
B=docs/audits/formal-resource-cause-repair-20261003
python3 "$B/bind.py" > "$B/bind.txt" 2>&1 || exit 1
FSMGEN_RESOURCE_CAUSE_CAPTURE="$B/current-causes.json" prove -Iperl -It/lib t/1944-isf-formal-resource-products.t t/2058-isf-formal-resource-diagnostic-causes.t > "$B/current.txt" 2>&1
status=$?;echo "$status" > "$B/current.status";test "$status" -eq 0 || exit 1
perl "$B/prior_helper.pl" > "$B/prior-helper-red.txt" 2>&1
status=$?;echo "$status" > "$B/prior-helper-red.status";test "$status" -eq 12 || exit 1
perl "$B/prior_direct.pl" > "$B/prior-direct-red.txt" 2>&1
status=$?;echo "$status" > "$B/prior-direct-red.status";test "$status" -eq 2 || exit 1
perl "$B/ordinary.pl" > "$B/ordinary.txt" 2>&1
status=$?;echo "$status" > "$B/ordinary.status";test "$status" -eq 0 || exit 1
echo 'PASS current default/control consumers, exact prior helper/direct RED and whole ordinary products.'
