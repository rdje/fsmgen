"""Retain full observer transform, raw native differences and per-call referents."""
import difflib
import json
from pathlib import Path
from native import check_joint, conserved

BASE = Path(__file__).parent
NATIVE = Path('docs/audits/record-value-structured-clones-20261004')
original = Path('docs/audits/record-value-runtime-20261004/observe.pl').read_text().splitlines(keepends=True)
current = (NATIVE / 'observe.pl').read_text().splitlines(keepends=True)
# Retain exact source edits. The independent reader applies them uniquely to the
# sealed predecessor and demands whole producer byte equality.
transform = []
for kind, a, b, c, d in difflib.SequenceMatcher(a=original, b=current, autojunk=False).get_opcodes():
    if kind == 'equal':
        continue
    # Inserts bind the preceding complete line, not an empty search string.
    if a == b:
        a -= 1; c -= 1
    transform.append([''.join(original[a:b]), ''.join(current[c:d])])
(BASE / 'observer-transform.json').write_text(json.dumps(transform, indent=2) + '\n')
old = json.loads(Path('docs/audits/record-value-runtime-20261004/ordinary.json').read_text())
ordinary = json.loads((NATIVE / 'ordinary.json').read_text())
bad = json.loads((NATIVE / 'alias-result.json').read_text())
(BASE / 'legacy-conservation.json').write_text(json.dumps(conserved(old, ordinary, True), sort_keys=True, indent=2) + '\n')
conserved(ordinary, bad, False)
packet = {}
for label, profile in (('ordinary', ordinary), ('alias_result', bad)):
    packet[label] = [{'index': i, **check_joint(row, require_detached=label == 'ordinary')} for i, row in enumerate(profile['api']) if row['kind'] == 'structured-clone']
(BASE / 'referents.json').write_text(json.dumps(packet, sort_keys=True, indent=2) + '\n')
print('Retained complete source transform, raw conservation ledger and whole independent joint referent populations.')
