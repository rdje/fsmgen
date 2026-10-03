#!/bin/bash
set -u
B=docs/audits/reservation-coverage-cause-repair-20261003
C=docs/audits/reservation-coverage-cause-repair-checks-20261003
prove -Iperl "$C/prior-desired.pl" > "$B/prior.txt" 2>&1
result=$?; printf '%s\n' "$result" > "$B/prior.status"
test "$result" -eq 1 || exit 1
FSMGEN_COVERAGE_OBSERVER_MODE=ordinary prove -Iperl "$B/observe.pl" > "$B/ordinary.txt" 2>&1
result=$?; printf '%s\n' "$result" > "$B/ordinary.status"
test "$result" -eq 0 || exit 1
FSMGEN_COVERAGE_OBSERVER_MODE=bypass prove -Iperl "$B/observe.pl" > "$B/bypass.txt" 2>&1
result=$?; printf '%s\n' "$result" > "$B/bypass.status"
test "$result" -eq 1 || exit 1
printf 'PASS exact prior desired-safety RED, current whole observations and actual declaration-only bypass RED captured.\n'
