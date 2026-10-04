"""Bind independently authored scope recipes to every complete original call."""
import hashlib
import json
from pathlib import Path
from model import scope_model, source_projection, thaw
from source_recipes import graph, recipes

BASE = Path(__file__).parent
native_path = Path('docs/audits/record-value-runtime-20261004/ordinary.json')
raw = native_path.read_bytes()
native = json.loads(raw)
expected = recipes()
assert expected == json.loads((BASE / 'source-recipes.json').read_text())
selected = [(i, row) for i, row in enumerate(native['api']) if row['kind'] == 'scope']
assert len(selected) == len(expected) == 40
rows = []
for (index, actual), recipe in zip(selected, expected):
    assert graph(source_projection(thaw(actual['before']))) == recipe['arguments'], 'complete source recipe argument identity: ' + recipe['label']
    assert actual['caller'] == recipe['caller'] and actual['helper'] == recipe['helper']
    private = [dict(row, index=i) for i, row in enumerate(native['copies']) if row['api'] == index
        and row['kind'] == 'value-private' and row['caller'] == ['FSM::Support::ISFRecordPortValues', 'perl/FSM/Support/ISFRecordPortValues.pm', 29]]
    product, stages = scope_model(recipe, private, graph)
    rows.append({'index': index, 'label': recipe['label'], 'recipe': recipe,
        'original': actual, 'private': private, 'stages': stages, 'expected_product': product})
(BASE / 'scope-products.json').write_text(json.dumps({'native_input': {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}, 'rows': rows}, sort_keys=True, indent=2) + '\n')
print('PASS complete original forty source/caller/argument/private-stage scope models built without reading any actual result as model authority. Whole native products remain for the separate reader.')
