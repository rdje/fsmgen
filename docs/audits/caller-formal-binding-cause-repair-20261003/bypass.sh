#!/bin/bash
set -u
B=docs/audits/caller-formal-binding-cause-repair-20261003
perl "$B/bypass.pl" > "$B/binding-bypass-red.txt" 2>&1
status=$?;echo "$status" > "$B/binding-bypass-red.status"
test "$status" -ne 0 || exit 1
perl "$B/bypass_input.pl" > "$B/bypass-input.txt" 2>&1 || exit 1
echo 'PASS genuine current-test binding bypass RED and full input capture.'
