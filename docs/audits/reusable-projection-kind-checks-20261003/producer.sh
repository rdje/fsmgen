#!/bin/bash
set -u
B=docs/audits/reusable-projection-kind-repair-20261003
perl "$B/prior.pl" > "$B/prior-red.txt" 2>&1
status=$?;echo "$status" > "$B/prior-red.status";test "$status" -eq 1 || exit 1
prove -Iperl -It/lib t/1947-isf-formal-reusable-products.t t/2060-isf-reusable-diagnostic-causes.t > "$B/current.txt" 2>&1
status=$?;echo "$status" > "$B/current.status";test "$status" -eq 0 || exit 1
perl "$B/before_ordinary.pl" > "$B/before-ordinary.txt" 2>&1
status=$?;echo "$status" > "$B/before-ordinary.status";test "$status" -eq 0 || exit 1
perl "$B/ordinary.pl" > "$B/ordinary.txt" 2>&1
status=$?;echo "$status" > "$B/ordinary.status";test "$status" -eq 0 || exit 1
perl "$B/clone_inputs.pl" > "$B/clone-inputs.txt" 2>&1
status=$?;echo "$status" > "$B/clone-inputs.status";test "$status" -eq 0 || exit 1
python3 "$B/bind.py"
