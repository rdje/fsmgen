#!/bin/bash
set -u
B=docs/audits/reusable-projection-kind-repair-20261003
C=docs/audits/reusable-projection-kind-checks-20261003
python3 "$C/authenticated_readback.py" > "$C/prior-archive.txt" 2>&1 || exit 1
python3 "$B/verify.py" > "$C/cold.txt" 2>&1 || exit 1
python3 "$B/verify.py" --trust-prior-kinds > "$C/prior-kind-red.txt" 2>&1
status=$?;echo "$status" > "$C/prior-kind-red.status";test "$status" -eq 1 || exit 1
prove -Iperl -It/lib t/1945-isf-formal-child-products.t t/2059-isf-atl-source-width-kind-preservation.t > "$C/regression.txt" 2>&1 || exit 1
echo 'PASS projection finite cold/source/kind models, exact prior RED and focused regressions.'
