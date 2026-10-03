#!/bin/bash
set -u
B=docs/audits/reusable-product-helper-causes-20261003
C=docs/audits/reusable-product-helper-checks-20261003
python3 "$B/verify.py" > "$C/cold.txt" 2>&1 || exit 1
for mode in trust-helper trust-primary trust-direct trust-projection-kinds trust-caller-kinds; do
 python3 "$B/verify.py" --"$mode" > "$C/$mode-red.txt" 2>&1
 status=$?;echo "$status" > "$C/$mode-red.status";test "$status" -eq 1 || exit 1
done
prove -Iperl -It/lib t/1945-isf-formal-child-products.t t/1231-isf-library-generated-top.t > "$C/regression.txt" 2>&1 || exit 1
echo 'PASS finite independent readback, five genuine safety promotions RED and focused child/library regression.'
