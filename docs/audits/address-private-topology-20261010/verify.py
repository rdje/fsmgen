"""Whole dated private-source topology qualification and hostile controls."""
import copy
import json
from pathlib import Path

BASE = Path('docs/audits/address-private-topology-20261010')


def load(name):
    return json.loads((BASE / name).read_bytes())


def module(name):
    path = BASE / name
    ns = {'__name__': 'private_topology_qualification'}
    exec(compile(path.read_bytes(), str(path), 'exec'), ns)
    return ns


def main():
    source = module('source.py')
    inputs, binding = source['rebuild']()
    if inputs != load('inputs.json') or binding != load('binding.json'):
        raise ValueError('whole independently rebuilt fixed private source graph inputs')
    hypotheses = load('hypotheses.json')
    if hypotheses != module('model.py')['derive'](inputs):
        raise ValueError('whole retained deterministic private topology hypotheses')
    oracle = module('oracle.py')['qualify']
    measured = oracle(hypotheses, inputs)
    controls = []
    def rejects(name, mutate, expected, change_inputs=False):
        candidate = copy.deepcopy(inputs if change_inputs else hypotheses)
        mutate(candidate)
        try:
            oracle(hypotheses if change_inputs else candidate, candidate if change_inputs else inputs)
        except ValueError as error:
            if str(error) != expected:
                raise ValueError('unintended private control refusal: ' + name + ': ' + str(error)) from error
            controls.append({'name': name, 'refusal': str(error), 'target': 'actual graph inputs' if change_inputs else 'hypotheses',
                             'whole_candidate_identity': source['identity'](json.dumps(candidate, sort_keys=True).encode())})
        else:
            raise ValueError('genuine private topology control admitted: ' + name)
    def first(p):
        return p['copies'][0]
    rejects('lost-private-copy', lambda p: p['copies'].pop(), 'complete private copy membership')
    rejects('borrowed-private-call-domain', lambda p: first(p)['domain'].__setitem__(1, first(p)['domain'][1] + 1),
            'exact per-copy per-capture source domain')
    rejects('borrowed-capture-domain', lambda p: first(p)['domain'].__setitem__(0, 'storable'),
            'exact per-copy per-capture source domain')
    rejects('boolean-private-call-domain', lambda p: first(p)['domain'].__setitem__(1, True),
            'exact per-copy per-capture source domain')
    rejects('input-is-returned-copy', lambda p: first(p)['binding_namespace'].update(result=first(p)['binding_namespace']['input']),
            'distinct source-private input/result binding domains')
    rejects('borrowed-returned-copy-binding', lambda p: first(p)['binding_namespace']['result'].__setitem__(2, 999999),
            'distinct source-private input/result binding domains')
    rejects('false-post-return-liveness', lambda p: first(p).update(post_return='every copy remains live in every later trace'),
            'no inferred source-private post-return liveness')
    rejects('cross-call-simultaneous-lifetime', lambda p: first(p).update(simultaneously_live='all calls share one object pool'),
            'source-private simultaneous active-copy lifetime')
    rejects('wrong-reference-kind', lambda p: first(p)['result_pool']['nodes'][''].update(kind='ARRAY'),
            'private reference kind')
    rejects('lost-node-correspondence', lambda p: first(p)['bijection'].pop(next(iter(first(p)['bijection']))),
            'complete declared private node correspondence')
    def split_alias(p):
        for row in p['copies']:
            nodes = row['input_pool']['nodes']
            incoming = {name: [] for name in nodes}
            for name, node in nodes.items():
                for key, edge in node['edges'].items():
                    if 'node' in edge:
                        incoming[edge['node']].append((name, key))
            for name, edges in incoming.items():
                if len(edges) >= 2:
                    fresh = 'split-live-alias'
                    nodes[fresh] = copy.deepcopy(nodes[name])
                    parent, key = edges[0]
                    nodes[parent]['edges'][key] = {'node': fresh}
                    return
        raise ValueError('actual private shared alias control setup')
    rejects('split-shared-private-node', split_alias, 'private alias equivalence')
    def joint_alias(rows):
        rows[0]['qualified_original_joint'][1]['result'] = ['reference', '/input']
    rejects('actual-joint-aliases-input', joint_alias, 'whole original private input/result detachment', True)
    rejects('promoted-native-identity', lambda p: p.update(scope='All original numeric identities and provider behavior measured'),
            'private source-only open scopes')
    proof = {'binding': binding, 'measured': measured, 'controls': controls,
             'programmes': {name: source['identity']((BASE / name).read_bytes()) for name in
                            ('source.py', 'model.py', 'oracle.py', 'verify.py')},
             'legs': {'re_derivation': 'whole source protocol and complete finite memoized clone topology hypotheses from qualified input graphs',
                      'falsification': 'independent graph bijection/joint reachability oracle plus genuine complete-product domain/alias/kind/lifetime controls',
                      'durability': 'fixed complete Git input custody, original typed graph products and tracked first/final programmes/results/proof'},
             'missing_legs': 'Original numeric addresses, native/provider/formatter identity, post-return caller/phase lifetimes and remaining core/helper/parser/nested role joins; canonical publication.'}
    path = BASE / 'proof.json'
    if path.exists() and load('proof.json') != proof:
        raise ValueError('whole retained dated private source proof')
    if not path.exists():
        path.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS complete private source topology, actual qualified joint detachment and independent separating controls; numeric and post-return identities remain open.')


if __name__ == '__main__':
    main()
