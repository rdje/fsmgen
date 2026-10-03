#!/bin/bash
set -u
B=docs/audits/prepared-reservation-snapshot-repair-20261003
for mode in ordinary mutate prior-copy; do
 FSMGEN_PREPARED_SNAPSHOT_MODE="$mode" prove -Iperl -It/lib "$B/observe.pl" > "$B/$mode.txt" 2>&1
 status=$?;printf '%s\n' "$status" > "$B/$mode.status"
 expected=1;test "$mode" != ordinary || expected=0
 test "$status" -eq "$expected" || exit 1
done
printf 'PASS ordinary source copies and genuine kind-mutation/prior-Storable consumer failures.\n'
