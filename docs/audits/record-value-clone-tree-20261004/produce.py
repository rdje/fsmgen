"""Retain every source-derived complete recursive clone operation product."""
import json
from pathlib import Path
from tree_model import products

BASE = Path('docs/audits/record-value-clone-tree-20261004')
native = json.loads(Path('docs/audits/record-value-structured-clones-20261004/ordinary.json').read_text())
rows = products()
assert [row['index'] for row in rows] == [i for i, row in enumerate(native['api']) if row['kind'] == 'structured-clone']
(BASE / 'tree-products.json').write_text(json.dumps({'rows': rows}, sort_keys=True, indent=2) + '\n')
print('PASS complete recursive clone products derived from whole qualified source roots without actual clone input/result values as semantic authority.')
