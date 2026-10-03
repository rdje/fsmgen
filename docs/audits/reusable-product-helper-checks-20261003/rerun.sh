#!/bin/bash
set -u
B=docs/audits/reusable-product-helper-causes-20261003
perl "$B/probe.pl" > "$B/probe-red.txt" 2>&1
status=$?;echo "$status" > "$B/probe-red.status"
echo "Exact literal pattern observer status:$status; classify from complete actual traces."
