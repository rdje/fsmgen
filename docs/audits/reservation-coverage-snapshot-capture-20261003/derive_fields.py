import argparse
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--write', action='store_true')
options = parser.parse_args()
base = Path('docs/audits/reservation-coverage-snapshot-capture-20261003')
ordinary = json.loads((base / 'ordinary.json').read_text())
pure = json.loads((base / 'pure.json').read_text())
selected = {'success_snapshot', 'refusal_snapshot', 'unexpected_module_seed',
            'module_mutation_seed', 'allocation_mutation_seed'}


def delta(a, b, path=''):
    if type(a) is not type(b):
        return [[path, type(a).__name__, type(b).__name__, a, b]]
    if isinstance(a, dict):
        assert a.keys() == b.keys(), path
        return [d for key in sorted(a) for d in delta(a[key], b[key], path + '/' + key)]
    if isinstance(a, list):
        assert len(a) == len(b), path
        return [d for i, (x, y) in enumerate(zip(a, b)) for d in delta(x, y, path + '/' + str(i))]
    assert a == b, path
    return []


rows = []
assert len(ordinary['copies']) == len(pure['copies'])
for ordinal, (a, b) in enumerate(zip(ordinary['copies'], pure['copies'])):
    assert a['site'] == b['site'] and a['line'] == b['line']
    if a['site'] in selected:
        rows.append({'ordinal': ordinal, 'site': a['site'], 'line': a['line'],
                     'differences': delta(a['before'], a['copy']),
                     'pure_differences': delta(b['before'], b['copy'])})
text = json.dumps(rows, sort_keys=True, indent=2) + '\n'
if options.write:
    (base / 'field-roster.json').write_text(text)
else:
    assert (base / 'field-roster.json').read_text() == text
print('PASS complete remaining copy-site typed field roster; source/product meanings and real value-only assertion controls remain owned successors.')
