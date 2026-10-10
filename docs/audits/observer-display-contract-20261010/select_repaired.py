"""Select every original case plus all root-cause cases before fresh capture."""
import copy
import hashlib
import json
from pathlib import Path
import select_cases
import model_repaired

BASE = Path('docs/audits/observer-display-contract-20261010')


def main():
    value = select_cases.catalogue()
    first = json.loads((BASE / 'qualify-catalogue.json').read_bytes())
    assert value == first, 'no original selected case is removed or edited'
    for name, prefix in [('repair-probe', 'repaired-probe-'), ('regex-suffix', 'repaired-suffix-')]:
        source = json.loads((BASE / (name + '-catalogue.json')).read_bytes())
        for case in source['cases']:
            row = copy.deepcopy(case)
            row['id'] = prefix + row['id']
            value['cases'].append(row)
    for name, record in [('repaired-catalogue.json', value), ('repaired-hypotheses.json', model_repaired.plan(value))]:
        destination = BASE / name
        assert not destination.exists()
        destination.write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
    names = ['select_repaired.py', 'select_cases.py', 'model_repaired.py', 'oracle_repaired.py',
             'fixtures.pl', 'capture_repaired.py', 'repaired-catalogue.json', 'repaired-hypotheses.json',
             'qualify-catalogue.json', 'repair-probe-catalogue.json', 'regex-suffix-catalogue.json']
    pins = {}
    for name in names:
        raw = (BASE / name).read_bytes()
        pins[name] = {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
    (BASE / 'repaired-pre-native.json').write_text(json.dumps(dict(inputs=pins,
        role='Fresh source-only repaired hypotheses before fresh native; all first cases conserve and complete additional root-cause cases are preselected. First failed hypotheses and captures remain immutable.'), sort_keys=True, indent=2) + '\n')
    print('PASS complete original corpus conserved and repaired finite hypotheses selected before fresh native.')


if __name__ == '__main__':
    main()
