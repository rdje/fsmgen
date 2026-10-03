#!/bin/bash
set -u
B=docs/audits/formal-resource-helper-causes-20261003
perl "$B/direct.pl" > "$B/direct.txt" 2>&1
status=$?;echo "$status" > "$B/direct.status"
perl "$B/ordinary.pl" > "$B/ordinary.txt" 2>&1
status=$?;echo "$status" > "$B/ordinary.status";test "$status" -eq 0 || exit 1
echo 'Finished direct cause diagnostic and ordinary whole products; inspect exact direct RED.'
