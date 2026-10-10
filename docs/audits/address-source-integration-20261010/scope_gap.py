"""Retain the first oracle's actual admission of an unknown native claim field."""
import copy
import json
from pathlib import Path

BASE = Path('docs/audits/address-source-integration-20261010')


def module(name):
    path = BASE / name
    ns = {'__name__': 'retained_scope_field_admission'}
    exec(compile(path.read_bytes(), str(path), 'exec'), ns)
    return ns


def main():
    source = module('source.py')
    spec = json.loads((BASE / 'inputs.json').read_bytes())
    candidate = copy.deepcopy(json.loads((BASE / 'hypotheses.json').read_bytes()))
    candidate['modes'][0]['views'][0]['original_native_identity'] = 'proved'
    measured = module('corrected-oracle.py.txt')['qualify'](candidate, source['data'](spec), spec)
    target = BASE / 'scope-field-gap.json'
    result = {'actual_status': 0, 'unknown_field': 'original_native_identity', 'value': 'proved',
        'candidate': source['pin'](json.dumps(candidate,sort_keys=True).encode()),
        'oracle': source['pin']((BASE/'corrected-oracle.py.txt').read_bytes()), 'measured': measured,
        'root_cause': 'The first successful oracle checked known view fields but did not enforce a closed view/descriptor/operand grammar. The unknown native assertion was ignored.',
        'repair': 'Require exact source-only field membership at each integrated schema boundary and genuine unknown native-claim controls.'}
    if target.exists():
        raise ValueError('retain each actual first scope-field admission')
    target.write_text(json.dumps(result,sort_keys=True,indent=2)+'\n')
    print('PASS actual first oracle scope-field admission reproduced; corrected field-membership refusal remains required.')


if __name__ == '__main__':
    main()
