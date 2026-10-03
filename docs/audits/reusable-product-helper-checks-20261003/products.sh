#!/bin/bash
set -u
B=docs/audits/reusable-product-helper-causes-20261003
for producer in ordinary pure_projection; do
 perl "$B/$producer.pl" > "$B/$producer.txt" 2>&1
 status=$?;echo "$status" > "$B/$producer.status";test "$status" -eq 0 || exit 1
done
echo 'PASS complete ordinary observations with declared clone gaps and genuine pure-copy counterfactual.'
