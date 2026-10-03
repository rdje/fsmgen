#!/bin/bash
set -e
C=docs/audits/reservation-coverage-cause-repair-checks-20261003
knowledge-map/scripts/gen_knowledge_map.sh > "$C/knowledge-generate.txt" 2>&1
mdbook build docs/book > "$C/book.txt" 2>&1
python3 "$C/rendered_verify.py" > "$C/rendered.txt" 2>&1
prove -Iperl -It/lib t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t > "$C/focused.txt" 2>&1
knowledge-map/scripts/check_knowledge_map.sh > "$C/knowledge.txt" 2>&1
printf 'PASS book build, rendered text, public-book checks and Knowledge Map.\n'
