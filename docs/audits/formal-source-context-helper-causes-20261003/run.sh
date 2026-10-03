#!/bin/bash
set -u
B=docs/audits/formal-source-context-helper-causes-20261003
python3 "$B/bind.py" > "$B/bind.txt" 2>&1 || exit 1
prove -Iperl -It/lib t/1936-isf-formal-source-context.t > "$B/current.txt" 2>&1
current=$?
echo "$current" > "$B/current.status"
echo "current: $current"
test "$current" -eq 0 || exit 1
perl "$B/probe.pl" > "$B/probe.txt" 2>&1
probe=$?
echo "$probe" > "$B/probe.status"
echo "desired-cause probe: $probe"
test "$probe" -eq 13 || exit 1
