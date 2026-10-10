"""Dated source-only replay and genuine whole-hypothesis separating controls."""
import copy
import json
from pathlib import Path

BASE = Path('docs/audits/address-source-boundaries-20261010')


def module(name):
    path = BASE / name
    namespace = {'__name__': 'address_source_qualification'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


def load(name):
    return json.loads((BASE / name).read_bytes())


def main():
    source = module('derive.py')
    inputs, custody = source['rebuild']()
    if inputs != load('inputs.json') or custody != load('binding.json'):
        raise ValueError('complete independently rebuilt source inputs and fixed Git custody')
    actual = load('hypotheses.json')
    if actual != module('model.py')['derive'](inputs):
        raise ValueError('complete deterministic source hypotheses')
    oracle = module('oracle.py')['qualify']
    measured = oracle(actual, inputs)
    controls = []
    def reject(name, mutate, expected):
        candidate = copy.deepcopy(actual)
        mutate(candidate)
        try:
            oracle(candidate, inputs)
        except ValueError as error:
            if str(error) != expected:
                raise ValueError('unintended control refusal: ' + name + ': ' + str(error)) from error
            controls.append({'name': name, 'refusal': str(error),
                             'whole_candidate_identity': source['identity'](json.dumps(candidate, sort_keys=True).encode())})
        else:
            raise ValueError('genuine whole-hypothesis control admitted: ' + name)
    def first(p):
        return p['cases'][0]['operations'][0]
    reject('lost-case', lambda p: p['cases'].pop(), 'complete source case membership')
    reject('lost-operation', lambda p: p['cases'][0]['operations'].pop(), 'complete source operation membership')
    reject('lost-reference-slot', lambda p: first(p)['occurrences'].pop(), 'every reference operand source slot exactly once')
    reject('wrong-reference-kind', lambda p: first(p)['bindings']['node:/1'].update(reference_kind='ARRAY'),
           'source binding origin and reference kind')
    reject('borrowed-root-address-role', lambda p: first(p)['occurrences'][0].update(binding='node:/3'),
           'source binding origin and reference kind')
    def split(p):
        row = first(p); row['bindings']['split'] = copy.deepcopy(row['bindings']['node:/1'])
        next(r for r in row['occurrences'] if r['binding'] == 'node:/1')['binding'] = 'split'
    reject('split-one-forwarded-binding', split, 'exact forwarded source alias equivalence')
    reject('lost-live-distinction', lambda p: first(p)['simultaneously_live_distinct'].pop(),
           'complete simultaneous-live distinction and explicitly unresolved allocation')
    reject('borrowed-capture-domain', lambda p: first(p)['domain'].__setitem__(0, 'storable'),
           'exact per-capture per-phase active-call domain')
    reject('borrowed-phase-domain', lambda p: first(p)['domain'].__setitem__(3, 1),
           'exact per-capture per-phase active-call domain')
    reject('numerical-reuse-is-identity', lambda p: first(p).update(lifetime='same hex means same object across calls'),
           'no inferred numerical cross-domain identity')
    reject('invented-receiver-census', lambda p: p.update(scope='Original receiver identities measured'), 'source-only open scopes')
    def nested(p):
        row = next(o for c in p['cases'] for o in c['operations'] if o['input_topology'] == 'nested successor-owned')
        row['input_topology'] = 'qualified source graph'
    reject('invented-nested-source-topology', nested, 'source graph authority versus nested open scope')
    proof = {'source': custody, 'measured': measured, 'controls': controls,
             'programmes': {name: source['identity']((BASE / name).read_bytes()) for name in
                            ('derive.py', 'model.py', 'oracle.py', 'verify.py')},
             'legs': {'re_derivation': 'complete source_model replay and qualified input graphs before raw intake',
                      'falsification': 'separate source-slot/alias relation oracle and genuine whole-product controls',
                      'durability': 'fixed whole Git input custody and tracked programmes/inputs/hypotheses/proof'},
             'missing_legs': 'Original numeric addresses; nested/core/helper/parser-internal/private/framework/provider/formatter identities; current canonical/native publication.'}
    path = BASE / 'proof.json'
    if path.exists() and load('proof.json') != proof:
        raise ValueError('whole retained dated source proof')
    if not path.exists():
        path.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS source-only operation-boundary lifetime hypotheses, independent alias/slot oracle and separating controls; raw address joins remain open.')


if __name__ == '__main__':
    main()
