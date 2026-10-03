#!/bin/bash
set -u
B=docs/audits/formal-resource-helper-causes-20261003
python3 "$B/bind.py" > "$B/bind.txt" 2>&1 || exit 1
prove -Iperl -It/lib t/1944-isf-formal-resource-products.t > "$B/current.txt" 2>&1
status=$?;echo "$status" > "$B/current.status";test "$status" -eq 0 || exit 1
perl "$B/probe.pl" > "$B/probe.txt" 2>&1
status=$?;echo "$status" > "$B/probe.status"
echo "Actual desired-cause probe status $status; inspect complete causes before classification."
