#!/bin/bash
set -u
B=docs/audits/formal-resource-cause-repair-20261003
perl "$B/bypass.pl" > "$B/resource-bypass-red.txt" 2>&1
status=$?;echo "$status" > "$B/resource-bypass-red.status";test "$status" -ne 0 || exit 1
perl "$B/bypass_input.pl" > "$B/bypass-input.txt" 2>&1 || exit 1
echo 'PASS actual current-test resource validation bypass RED and whole native input/output capture.'
