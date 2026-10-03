import argparse
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--write', action='store_true')
options = parser.parse_args()
base = Path('docs/audits/reservation-coverage-atl-module-fields-20261003')
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
roster = {'modules': [{'ordinal': i, 'paths': sorted(delta(ordinary['copies'][i]['before'], ordinary['copies'][i]['copy']))}
                      for i in (5, 6, 7)]}
before = json.loads((source / 'pure.json').read_text())['preparations'][7]['result']
after = json.loads((source / 'ordinary.json').read_text())['preparations'][7]['result']
roster['preparation'] = {'ordinal': 7, 'paths': sorted(delta(before, after))}
text = json.dumps(roster, sort_keys=True, indent=2) + '\n'
if options.write:
    (base / 'qualified-fields.json').write_text(text)
else:
    assert (base / 'qualified-fields.json').read_text() == text
print('PASS complete ATL module and vector preparation field-instance roster; semantic models are independent.')
