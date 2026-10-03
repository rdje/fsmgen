#!/bin/bash
set -u
B=docs/audits/atl-source-width-kind-repair-20261003
C=docs/audits/atl-source-width-kind-checks-20261003
python3 "$C/authenticated_readback.py" > "$C/prior-archive-authentication.txt" 2>&1 || exit 1
python3 "$B/verify.py" > "$C/cold.txt" 2>&1 || exit 1
python3 "$B/verify.py" --trust-prior-kinds > "$C/prior-kind-red.txt" 2>&1
status=$?;echo "$status" > "$C/prior-kind-red.status";test "$status" -eq 1 || exit 1
echo 'PASS finite independent repair readback and actual prior caller-kind promotion RED.'
