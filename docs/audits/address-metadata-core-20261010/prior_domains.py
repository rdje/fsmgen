"""Actual borrowed phase and returned-copy controls for source prerequisites."""
import copy
import json
from pathlib import Path


def qualify(source):
    results = {}
    operations = Path('docs/audits/address-source-boundaries-20261010')
    private = Path('docs/audits/address-private-topology-20261010')
    for base, kind in ((operations, 'operation'), (private, 'private')):
        inputs = source['load'](base / 'inputs.json')
        product = source['load'](base / 'hypotheses.json')
        oracle = source['module'](base / 'oracle.py')['qualify']
        baseline = oracle(product, inputs)
        candidate = copy.deepcopy(product)
        if kind == 'operation':
            selected = None
            for ci, case in enumerate(product['cases']):
                for oi, original in enumerate(case['operations']):
                    other = next((row for row in case['operations'] if row['kind'] == original['kind']
                                  and row['domain'][:3] == original['domain'][:3]
                                  and row['domain'][3] != original['domain'][3]), None)
                    if other is not None:
                        selected = ci, oi, original, other
                        break
                if selected is not None:
                    break
            if selected is None:
                raise ValueError('actual same-call same-kind other-phase control setup')
            ci, oi, original, other = selected
            candidate['cases'][ci]['operations'][oi]['domain'] = list(other['domain'])
            witness = {'original_domain': original['domain'], 'borrowed_domain': other['domain'],
                       'operation_kind': original['kind']}
            expected = 'exact per-capture per-phase active-call domain'
        else:
            original = product['copies'][0]
            other = next(row for row in product['copies'] if row['domain'][0] == original['domain'][0]
                         and row['kind'] == original['kind'] and row['domain'] != original['domain'])
            candidate['copies'][0]['binding_namespace']['result'] = list(other['binding_namespace']['result'])
            witness = {'original_domain': original['domain'], 'borrowed_domain': other['domain'],
                       'borrowed_result_namespace': other['binding_namespace']['result'], 'copy_kind': other['kind']}
            expected = 'distinct source-private input/result binding domains'
        try:
            oracle(candidate, inputs)
        except ValueError as error:
            if str(error) != expected:
                raise ValueError('unintended actual prior-domain refusal: ' + kind + ': ' + str(error)) from error
        else:
            raise ValueError('actual prior-domain control admitted: ' + kind)
        results[kind] = {'baseline': baseline, 'source_witness': witness, 'refusal': expected,
                         'whole_candidate_identity': source['identity'](json.dumps(candidate, sort_keys=True).encode())}
    return results
