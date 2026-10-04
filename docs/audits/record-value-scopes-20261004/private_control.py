"""Find and bind a genuine equal-meaning, wrong-kind private type product."""
import json
from pathlib import Path
from model import source_projection, thaw
from source_recipes import graph

BASE = Path(__file__).parent
native = json.loads(Path('docs/audits/record-value-runtime-20261004/ordinary.json').read_text())
ledger = json.loads((BASE / 'scope-products.json').read_text())
wanted = thaw(next(row['expected_product'] for row in ledger['rows'] if row['label'] == 'resolved-alias'))['held']['type_spec']

def candidates(value, path=(), seen=None):
    if not isinstance(value, (dict, list)):
        return
    seen = set() if seen is None else seen
    if id(value) in seen:
        return
    seen.add(id(value))
    if isinstance(value, dict):
        if value.get('kind') == 'record' and set(value) == set(wanted) and graph(source_projection(value)) == graph(source_projection(wanted)) and graph(value) != graph(wanted):
            yield path, value
        for key in sorted(value):
            yield from candidates(value[key], path + (key,), seen)
    else:
        for i, child in enumerate(value):
            yield from candidates(child, path + (i,), seen)

for index, stage in enumerate(native['copies']):
    if stage['kind'] != 'metadata-private':
        continue
    found = next(candidates(thaw(stage['copy'])), None)
    if found is not None:
        path, value = found
        (BASE / 'private-control.json').write_text(json.dumps({'copy_index': index, 'copy_path': path,
            'original_private_copy': stage, 'candidate': graph(value), 'expected_scope_type': graph(wanted),
            'destination': ['held', 'type_spec']}, sort_keys=True, indent=2) + '\n')
        print('PASS genuine private copy', index, 'path', path, 'retains whole resolved source meaning but differs in original primitive kinds from the independently rebuilt scope product.')
        break
else:
    raise AssertionError('genuine private-stage authority counterexample absent')
