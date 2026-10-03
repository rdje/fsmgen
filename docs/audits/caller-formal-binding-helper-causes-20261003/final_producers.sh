#!/bin/bash
set -u
B=docs/audits/caller-formal-binding-helper-causes-20261003
prove -Iperl -It/lib t/1933-isf-caller-formal-binding-scope.t > "$B/current.txt" 2>&1
status=$?
echo "$status" > "$B/current.status"
test "$status" -eq 0 || exit 1
perl "$B/ordinary.pl" > "$B/ordinary.txt" 2>&1
status=$?
echo "$status" > "$B/ordinary.status"
test "$status" -eq 0 || exit 1
echo 'PASS unchanged actual T1933 and ordinary source products.'
