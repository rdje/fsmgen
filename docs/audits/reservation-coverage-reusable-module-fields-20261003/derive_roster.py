import argparse
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--write', action='store_true')
options = parser.parse_args()
base = Path('docs/audits/reservation-coverage-reusable-module-fields-20261003')
module = Path('docs/audits/reservation-coverage-module-capture-20261003')
source = Path('docs/audits/reservation-coverage-source-copies-20261003')


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


ordinary = json.loads((module / 'ordinary.json').read_text())
original = ordinary['copies'][4]['before']
copied = ordinary['copies'][4]['copy']
before = json.loads((source / 'pure.json').read_text())['preparations'][4]['result']
after = json.loads((source / 'ordinary.json').read_text())['preparations'][4]['result']
roster = {'module': {'ordinal': 4, 'paths': sorted(delta(original, copied))},
          'preparation': {'ordinal': 4, 'paths': sorted(delta(before, after))}}
text = json.dumps(roster, sort_keys=True, indent=2) + '\n'
if options.write:
    (base / 'qualified-fields.json').write_text(text)
else:
    assert (base / 'qualified-fields.json').read_text() == text
print('PASS complete storage-module and FIFO preparation field-instance roster; semantic verification is independent.')
