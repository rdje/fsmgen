import argparse
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--write', action='store_true')
options = parser.parse_args()
base = Path('docs/audits/reservation-coverage-module-join-20261003')
ownership = json.loads((base / 'ownership.json').read_text())
module = Path('docs/audits/reservation-coverage-module-capture-20261003')
source = Path('docs/audits/reservation-coverage-source-copies-20261003')
ordinary = json.loads((module / 'ordinary.json').read_text())
source_before = json.loads((source / 'pure.json').read_text())
source_after = json.loads((source / 'ordinary.json').read_text())


def delta(a, b, path=''):
    if type(a) is not type(b):
        return [path]
    if isinstance(a, dict):
        assert a.keys() == b.keys(), path
        return [p for key in a for p in delta(a[key], b[key], path + '/' + key)]
    if isinstance(a, list):
        assert len(a) == len(b), path
        return [p for i, (x, y) in enumerate(zip(a, b)) for p in delta(x, y, path + '/' + str(i))]
    assert a == b, path
    return []


module_owners = {i: row['name'] for row in ownership['cohorts'] for i in row['module_ordinals']}
preparation_owners = {i: row['name'] for row in ownership['cohorts'] for i in row['preparation_ordinals']}
out = {'modules': [], 'preparations': []}
for i, row in enumerate(ordinary['copies']):
    out['modules'].append({'ordinal': i, 'cohort': module_owners[i],
                           'paths': sorted(delta(row['before'], row['copy']))})
for i, (a, b) in enumerate(zip(source_before['preparations'], source_after['preparations'])):
    paths = sorted(delta(a['result'], b['result']))
    out['preparations'].append({'ordinal': i, 'cohort': preparation_owners[i] if paths else None, 'paths': paths})
text = json.dumps(out, sort_keys=True, indent=2) + '\n'
if options.write:
    (base / 'joined-fields.json').write_text(text)
else:
    assert (base / 'joined-fields.json').read_text() == text
print('PASS full module and actor-only preparation path roster with exact cohort ownership; field meanings require the independent cohort readers.')
