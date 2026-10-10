"""Independent complete context boundary qualification, custody and controls."""
import copy
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/address-parser-contexts-20261010')
SUCCESS = ('PASS complete fresh context construction and exact typed public observations; '
           'original context-slot closure and native flags remain open.\n')


def module(name):
    path = BASE / name
    namespace = {'__name__': 'context_boundary_qualification'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


def load(name):
    return json.loads((BASE / name).read_bytes())


def main():
    source, oracle = module('source.py'), module('oracle.py')
    inputs = load('inputs.json')
    product = module('model.py')['derive'](inputs)
    target = BASE / 'hypotheses.json'
    if target.exists() and not oracle['exact'](product, load('hypotheses.json')):
        raise ValueError('whole retained deterministic context product')
    if not target.exists():
        target.write_text(json.dumps(product, sort_keys=True, indent=2) + '\n')
    product = load('hypotheses.json')
    qualify = oracle['qualify']
    measured = qualify(product, inputs)
    checks = load('checks.json')
    failed = checks['probe-gap']
    if (type(failed['status']) is not int or failed['status'] != 1
            or 'ValueError: whole nested source graph topology/value/alias' not in failed['stderr']
            or failed['instruments'][str(BASE / 'probe_gap.py')]
                != source['identity']((BASE / 'draft-probe_gap.py.txt').read_bytes())):
        raise ValueError('actual first strict representation failure custody')
    scalar = checks['scalar-representation']
    command = ['perl', str(BASE / 'scalar_representation.pl')]
    result = subprocess.run(command, capture_output=True, text=True)
    if (type(scalar['status']) is not int or scalar['status'] != 0
            or result.returncode != 0 or result.stderr or result.stdout != scalar['stdout']
            or scalar['instruments'][command[1]] != source['identity'](Path(command[1]).read_bytes())):
        raise ValueError('whole fresh public scalar representation reproducer')
    observed = json.loads(result.stdout)
    if not oracle['exact'](observed['before'], {'left': {'width': 1}, 'right': {'width': 1}}) or not oracle['exact'](
            observed['copies'], {'left': {'width': 1}, 'right': {'width': '1'}}):
        raise ValueError('actual validation-dependent published scalar representation')
    gap = module('probe_gap.py')['reproduce']()
    if not oracle['exact'](gap, load('probe-gap.json')):
        raise ValueError('whole actual first graph alias admission reproduction')
    controls = []
    def rejects(name, mutate, expected):
        candidate = copy.deepcopy(product)
        mutate(candidate)
        if oracle['exact'](candidate, product):
            raise ValueError('genuine context candidate setup: ' + name)
        try:
            qualify(candidate, inputs)
        except ValueError as error:
            if str(error) != expected:
                raise ValueError('unintended context control refusal: ' + name + ': ' + str(error)) from error
            controls.append({'name': name, 'refusal': str(error),
                'whole_candidate': source['identity'](json.dumps(candidate, sort_keys=True).encode())})
        else:
            raise ValueError('context control admitted: ' + name)
    def encode(root):
        seen = {}
        def visit(node, path):
            if not isinstance(node, oracle['Node']):
                return node
            if node in seen:
                return ['reference', seen[node]]
            seen[node] = path
            def at(key):
                return visit(node.edges[key], path + '/' + str(key).replace('~', '~0').replace('/', '~1'))
            if node.kind == 'HASH':
                return ['hash', {key: at(key) for key in sorted(node.edges)}]
            return ['array', [at(str(i)) for i in range(len(node.edges))]]
        return visit(root, '')
    def final_edit(p, mutate):
        root = oracle['graph'](p['public']['final']['graph'])
        mutate(root)
        p['public']['final']['graph'] = encode(root)
    def args(root, kind, index):
        return next(row.edges['arguments'] for row in oracle['values'](root.edges['9'])
                    if row.edges['kind'] == kind and row.edges['index'] == index)
    topology = 'complete context source topology/value/alias'
    numeric = 'complete context numeric source meaning'
    phase = 'complete context active/source/observer phase contract'
    rejects('missing-construction-step', lambda p: p['public']['steps'].pop(),
            'complete context construction step membership')
    rejects('borrowed-existing-other-construction-step', lambda p: p['public']['steps'].__setitem__(
            0, copy.deepcopy(p['public']['steps'][1])), 'exact context construction step order/domain')
    rejects('Boolean-step-index', lambda p: p['public']['steps'][0].update(index=False),
            'exact context construction step order/domain')
    rejects('Boolean-parse-index', lambda p: p['public'].update(parse_index=True),
            'exact context public source/refusal domain')
    rejects('wrong-primary-refusal', lambda p: p['public'].update(primary='accepted'),
            'exact context public source/refusal domain')
    rejects('borrowed-earlier-phase-final', lambda p: p['public'].update(final={
            k: copy.deepcopy(p['public']['steps'][0][k]) for k in ('graph', 'classes')}), topology)
    rejects('wrong-contained-parser-class', lambda p: p['public']['final']['classes'].update(
            {'/0/parser': 'FSM::Adapter::ISF'}), 'complete context receiver classes')
    rejects('lost-complete-context-member', lambda p: final_edit(p, lambda r:
            r.edges['3'].edges['1'].edges.pop('aggregate_roots')), topology)
    rejects('equal-payload-sample-overlay-argument-alias-split', lambda p: final_edit(p, lambda r:
            args(r, 'scope', 7).edges.update({'3': oracle['record']({})})), topology)
    rejects('equal-payload-overlay-result-alias-split', lambda p: final_edit(p, lambda r:
            r.edges['3'].edges['1'].edges.update(roots=oracle['clone'](r.edges['3'].edges['1'].edges['roots']))), topology)
    rejects('private-copy-detachment-erased', lambda p: final_edit(p, lambda r:
            r.edges['7'].edges['0'].edges.update(result=r.edges['7'].edges['0'].edges['input'])), topology)
    rejects('aggregate-context-private-copy-merged', lambda p: final_edit(p, lambda r:
            r.edges['3'].edges['0'].edges['aggregate_roots'].edges.update(
                value=r.edges['3'].edges['0'].edges['roots'].edges['value'].edges['type_spec'])), topology)
    rejects('equal-payload-contexts-merged', lambda p: final_edit(p, lambda r:
            r.edges['3'].edges.update({'2': r.edges['3'].edges['1']})), topology)
    rejects('lost-constructor-argument-row', lambda p: final_edit(p, lambda r:
            r.edges['9'].edges.pop(str(len(r.edges['9'].edges)-1))), topology)
    def width(root, value):
        root.edges['7'].edges['0'].edges['result'].edges['type_spec'].edges['members'].edges['flag'].edges['width'] = value
    rejects('wrong-numeric-width-value', lambda p: final_edit(p, lambda r: width(r, 2)), numeric)
    rejects('noncanonical-numeric-string', lambda p: final_edit(p, lambda r: width(r, '01')), numeric)
    rejects('negative-numeric-string', lambda p: final_edit(p, lambda r: width(r, '-1')), numeric)
    rejects('Boolean-numeric-width', lambda p: final_edit(p, lambda r: width(r, True)),
            'nested qualified graph grammar')
    rejects('float-numeric-width', lambda p: final_edit(p, lambda r: width(r, 1.0)),
            'nested qualified graph grammar')
    rejects('semantic-equal-typed-observation-altered', lambda p: final_edit(p, lambda r: width(r, 1)),
            'complete exact typed context observations')
    rejects('anchor-width-kind-normalized', lambda p: final_edit(p, lambda r:
            r.edges['2'].edges['interface'].edges['outputs'].edges['0'].edges.update(width='1')), topology)
    rejects('AST-token-kind-normalized', lambda p: final_edit(p, lambda r:
            r.edges['1'].edges['4'].edges['2'].edges.update({'2': 1})), topology)
    rejects('sample-result-reactivated', lambda p: p['phase']['active_roots'].append('/5/0'), phase)
    rejects('observer-argument-promoted-to-original-holder', lambda p: p['phase']['active_roots'].append('/9/0/arguments'), phase)
    rejects('sample-lexical-block-lifetime-erased', lambda p: p['phase'].update(sample_lifetime='active'), phase)
    rejects('lost-inactive-context', lambda p: p['phase']['inactive_contexts'].clear(), phase)
    rejects('lost-numeric-flag-boundary', lambda p: p['phase'].update(numeric_boundary='original flags known'), phase)
    rejects('partial-predecessor-conservation', lambda p: p['preserved_construction']['profiles'].pop(),
            'whole corrected construction conservation')
    rejects('original-native-scope-promotion', lambda p: p.update(scope='Original native identity and scalar flags measured'),
            'context boundary source-only scope')
    fresh, custody = source['rebuild']()
    if not oracle['exact'](fresh, inputs) or not oracle['exact'](custody, load('binding.json')):
        raise ValueError('whole fresh context source epochs, exact typed observations and original protocol custody')
    proof = {'binding': custody, 'measured': measured, 'controls': controls,
        'scalar_boundary': observed, 'first_graph_gap': gap,
        'retained_first_failure': failed,
        'first_products': {name: source['identity']((BASE / name).read_bytes()) for name in (
            'first-source.py.txt', 'first-public_contexts.pl.txt', 'first-oracle.py.txt',
            'first-inputs.json.txt', 'first-binding.json.txt', 'draft-model.py.txt',
            'draft-oracle.py.txt', 'draft-probe_gap.py.txt', 'probe-gap-first-failure.json')},
        'programmes': {name: source['identity']((BASE / name).read_bytes()) for name in (
            'source.py', 'model.py', 'oracle.py', 'verify.py', 'probe_gap.py', 'public_contexts.pl', 'scalar_representation.pl')},
        'scope': 'Exact typed replay and independent complete source semantic/alias qualification are separate legs. No original scalar flags/native identity, original context-slot closure or global object census is claimed.'}
    target = BASE / 'proof.json'
    if target.exists() and not oracle['exact'](proof, load('proof.json')):
        raise ValueError('whole retained boundary proof; never overwrite')
    if not target.exists():
        target.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
