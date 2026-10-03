#!/bin/bash
set -u
B=docs/audits/reusable-product-helper-causes-20261003
perl "$B/probe.pl" > "$B/probe-red.txt" 2>&1
status=$?;echo "$status" > "$B/probe-red.status";test "$status" -eq 22 || exit 1
perl "$B/ordinary.pl" > "$B/ordinary.txt" 2>&1
status=$?;echo "$status" > "$B/ordinary.status";test "$status" -eq 0 || exit 1
echo 'PASS exact literal consumers and direct serialized original snapshots; mixed safety RED retained.'
