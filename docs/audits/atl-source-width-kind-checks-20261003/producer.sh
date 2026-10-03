#!/bin/bash
set -u
B=docs/audits/atl-source-width-kind-repair-20261003
python3 "$B/bind.py" > "$B/after-bind.txt" 2>&1 || exit 1
FSMGEN_ATL_WIDTH_KIND_CAPTURE="$B/prior-causes.json" perl "$B/prior.pl" > "$B/prior-red.txt" 2>&1
status=$?;echo "$status" > "$B/prior-red.status";test "$status" -eq 4 || exit 1
prove -Iperl -It/lib t/1947-isf-formal-reusable-products.t t/1330-isf-atl-resolved-child-fixture-coverage.t > "$B/regression.txt" 2>&1 || exit 1
echo 'PASS exact prior guard RED and focused reusable/ATL fixture regression.'
