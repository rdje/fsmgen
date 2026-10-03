#!/bin/bash
set -u
B=docs/audits/reusable-product-helper-causes-20261003
python3 "$B/bind.py" > "$B/bind.txt" 2>&1 || exit 1
prove -Iperl -It/lib t/1947-isf-formal-reusable-products.t > "$B/default.txt" 2>&1
status=$?;echo "$status" > "$B/default.status";test "$status" -eq 0 || exit 1
perl "$B/probe.pl" > "$B/probe-red.txt" 2>&1
status=$?;echo "$status" > "$B/probe-red.status"
echo "Actual mixed desired-safety observer status:$status (classify only after independent cause review)."
