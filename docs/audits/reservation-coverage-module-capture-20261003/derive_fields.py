import argparse
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--write', action='store_true')
options = parser.parse_args()
base = Path('docs/audits/reservation-coverage-module-capture-20261003')
ordinary = json.loads((base / 'ordinary.json').read_text())
pure = json.loads((base / 'pure.json').read_text())
parent = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.2.4.3.3'

def delta(left, right, path=''):
    if type(left) is not type(right):
        return [(path, type(left).__name__, type(right).__name__, left, right)]
    if isinstance(left, dict):
        assert left.keys() == right.keys(), path
        return [d for key in sorted(left) for d in delta(left[key], right[key], path + '/' + key)]
    if isinstance(left, list):
        assert len(left) == len(right), path
        return [d for i, (a, b) in enumerate(zip(left, right)) for d in delta(a, b, path + '/' + str(i))]
    assert left == right, path
    return []

rows = []
assert len(ordinary['copies']) == len(pure['copies']) == 10
for index, (a, b) in enumerate(zip(ordinary['copies'], pure['copies'])):
    assert not delta(a['before'], b['before'])
    assert not delta(b['before'], b['copy'])
    owner = parent + ('.3' if index in (0, 1, 2, 8, 9) else '.4' if index in (3, 4) else '.5')
    rows.append({'ordinal': index, 'actor': a['before'][1]['actor_name'],
                 'field_owner': owner, 'differences': delta(a['before'], a['copy'])})
text = json.dumps(rows, sort_keys=True, indent=2) + '\n'
if options.write:
    (base / 'field-roster.json').write_text(text)
else:
    assert (base / 'field-roster.json').read_text() == text
print('PASS complete original/copy field roster and per-family ownership; field meanings remain unqualified.')
