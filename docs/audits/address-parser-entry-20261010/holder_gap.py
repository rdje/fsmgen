"""Reproduce the first complete oracle's admitted retained-caller holder gap."""
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/address-parser-entry-20261010')


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def reproduce():
    first = json.loads((BASE / 'first-complete-proof.json.txt').read_bytes())
    programmes = {}
    for name, expected in first['programmes'].items():
        path = BASE / ('first-complete-' + name + '.txt' if name in ('model.py', 'oracle.py', 'verify.py') else name)
        programmes[name] = pin(path.read_bytes())
        if programmes[name] != expected:
            raise ValueError('whole first complete parser programme custody')
    outcome = json.loads((BASE / 'checks.json').read_bytes())['complete-independent']
    if (type(outcome['status']) is not int or outcome['status'] != 0
            or outcome['instruments'][str(BASE / 'verify.py')] != programmes['verify.py']
            or outcome['stdout'] != ('PASS complete parser-entry receiver/delegate/caller source bindings and independent '
                                     'normalization graphs; partial actor/context and native identity remain open.\n')):
        raise ValueError('actual first complete parser qualification outcome')
    path = BASE / 'first-complete-oracle.py.txt'
    namespace = {'__name__': 'first_complete_holder_oracle'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    product = json.loads((BASE / 'first-complete-hypotheses.json.txt').read_bytes())
    inputs = json.loads((BASE / 'inputs.json').read_bytes())
    measured = namespace['qualify'](product, inputs)
    if measured != first['measured']:
        raise ValueError('whole first complete admitted source scope')
    gaps = [{'domain': case['domain'], 'missing_held': sorted(set(case['retained_callers']) - set(case['held']))}
            for mode in product['modes'] for case in mode['cases']
            if set(case['retained_callers']) - set(case['held'])]
    if len(gaps) != 3 or any(row['missing_held'] != ['parse:2:caller'] or row['domain'][2] != 3 for row in gaps):
        raise ValueError('genuine admitted earlier-refusal caller holder gap')
    return {'first_programmes': programmes, 'first_measured': measured, 'admitted_missing_holders': gaps,
            'mechanism': 'Retained caller membership was checked separately but omitted from the expected held union and its simultaneous-source distinctions.',
            'scope': 'P2 qualification assurance defect in this source slice; no production parser defect or original native identity claim.'}


def main():
    result = reproduce()
    target = BASE / 'holder-gap.json'
    if target.exists() and json.loads(target.read_bytes()) != result:
        raise ValueError('whole retained holder-gap reproducer product')
    if not target.exists():
        target.write_text(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print('PASS first complete oracle admission of all three earlier-refusal caller holder gaps reproduced.')


if __name__ == '__main__':
    main()
