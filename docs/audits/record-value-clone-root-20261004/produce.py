"""Retain source-owned whole root recipes; actual results never supply authority."""
import json
from pathlib import Path
from source_roots import recipes, exact, thaw, graph

BASE = Path('docs/audits/record-value-clone-root-20261004')
native = json.loads(Path('docs/audits/record-value-structured-clones-20261004/ordinary.json').read_text())
rows = recipes(native)
for row in rows:
    actual = native['api'][row['index']]
    arguments = thaw(actual['before'])
    assert arguments[0] == 'FSM::Package::AggregatePathSupport' and len(arguments) == 2
    assert exact(graph(arguments[1]), row['expected_input']), 'whole source-owned original root preparation input: ' + str(row['index'])
    parent = native['api'][row['source_parent_index']]
    assert actual['helper'] == parent['helper'] and actual['parse'] == parent['parse']
(BASE / 'root-recipes.json').write_text(json.dumps({'rows': rows}, sort_keys=True, indent=2) + '\n')
print('PASS complete source-owned original root clone recipes built without reading any actual structured clone result.')
