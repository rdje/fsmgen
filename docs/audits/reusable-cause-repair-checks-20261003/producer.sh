#!/bin/bash
set -u
B=docs/audits/reusable-cause-repair-20261003
perl "$B/prior.pl" > "$B/prior-red.txt" 2>&1
status=$?;echo "$status" > "$B/prior-red.status";test "$status" -eq 22 || exit 1
perl "$B/ordinary.pl" > "$B/ordinary.txt" 2>&1
status=$?;echo "$status" > "$B/ordinary.status";test "$status" -eq 0 || exit 1
echo 'PASS exact prior mixed consumer RED and whole current ordinary observations.'
