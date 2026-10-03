#!/bin/bash
set -u
B=docs/audits/caller-formal-binding-helper-causes-20261003
python3 "$B/bind.py" > "$B/bind.txt" 2>&1 || exit 1
perl "$B/probe.pl" > "$B/probe.txt" 2>&1
status=$?
echo "$status" > "$B/probe.status"
echo "probe: $status (consume raw causes before classification)"
exit 0
