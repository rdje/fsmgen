"""Retain source-owned strict/payload recipes and full native argument checks."""
import json
from pathlib import Path
from model import recipes, exact

BASE = Path('docs/audits/record-value-identities-20261004')
native = json.loads(Path('docs/audits/record-value-runtime-20261004/ordinary.json').read_text())
rows = recipes(native)
assert [row['index'] for row in rows] == [i for i, row in enumerate(native['api']) if row['kind'] in ('identity', 'payload')]
for row in rows:
    actual = native['api'][row['index']]
    assert exact(row['expected_arguments'], actual['before']), 'whole own source/private preparation arguments: ' + str(row['index'])
    assert exact(actual['before'], actual['after'])
    assert actual['caller'] == row['caller'] and actual['helper'] == row['helper'] and actual['parse'] == row['parse']
    assert actual['accepted'] == 1 and not actual['error'] and not actual['primary'] and not actual['warnings']
    assert exact(row['expected_result'], actual['result']), 'whole source-derived strict/payload product: ' + str(row['index'])
(BASE / 'identity-products.json').write_text(json.dumps({'rows': rows}, sort_keys=True, indent=2) + '\n')
print('PASS every original14 strict/four payload whole source/private/context/caller/kind/product recipe; actual results never supply semantic authority.')
