#!/bin/bash
set -u
B=docs/audits/prepared-reservation-snapshot-diagnosis-20261003
for mode in ordinary mutate; do
 FSMGEN_PREPARED_SNAPSHOT_MODE="$mode" prove -Iperl -It/lib "$B/observe.pl" > "$B/$mode.txt" 2>&1
 status=$?; printf '%s\n' "$status" > "$B/$mode.status"
 test "$status" -eq 0 || exit 1
done
printf 'PASS actual ordinary and kind-only mutation consumer runs. Mutation admission is a deliberate falsifier.\n'
