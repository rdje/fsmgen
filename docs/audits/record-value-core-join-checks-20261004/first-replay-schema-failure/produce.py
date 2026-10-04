"""Retain all completed core source/product/private/field/native joins."""
import json
from pathlib import Path
from core_models import records
from source_roots import exact, read

BASE = Path('docs/audits/record-value-core-join-20261004')
native = read('runtime', 'ordinary.json')
rows = records(native)
assert [row['index'] for row in rows] == [i for i, row in enumerate(native['api']) if row['kind'] not in ('scope', 'reference', 'copy')]
for row in rows:
    assert exact(row['expected_product'], row['whole_native']['result'])
(BASE / 'core-products.json').write_text(json.dumps({'rows': rows}, sort_keys=True, indent=2) + '\n')
print('PASS complete original core/native/completed-source/private/field product join retained; child semantic oracles remain the product authority.')
