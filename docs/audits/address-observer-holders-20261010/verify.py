"""Complete source-only caller membership and genuine separating controls."""
import copy
import json
import sys
from pathlib import Path

BASE = Path('docs/audits/address-observer-holders-20261010')
SUCCESS = 'PASS complete observer caller source membership; full graph/role integration and original native identity remain open.\n'


def module(name):
    path = BASE / name
    namespace = {'__name__': 'complete_observer_source_qualification'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


def load(name):
    return json.loads((BASE / name).read_bytes())


def main():
    source, oracle = module('source.py'), module('oracle.py')
    inputs, supplement = load('inputs.json'), load('supplement.json')
    witnesses = {r['mode']: load(r['mode'] + '.json') for r in inputs['modes']}
    product = module('model.py')['derive'](inputs, witnesses, supplement)
    target = BASE / 'hypotheses.json'
    if target.exists() and not oracle['exact'](product, load('hypotheses.json')):
        raise ValueError('whole retained deterministic caller product')
    if not target.exists():
        target.write_text(json.dumps(product, sort_keys=True, indent=2) + '\n')
    product = load('hypotheses.json')
    qualify = oracle['qualify']
    # Independent enumeration of every caller origin from the complete qualified
    # predecessors. Do not reuse the supplemental producer's selector.
    prior_callers = {mode: [] for mode in witnesses}
    for label, path in [('helper', 'docs/audits/address-helper-bindings-20261010/hypotheses.json'),
                        ('parser-context', 'docs/audits/address-parser-context-closure-20261010/hypotheses.json')]:
        for mode in json.loads(Path(path).read_bytes())['modes']:
            for key, descriptor in mode['bindings'].items():
                origin = descriptor['origin']
                if descriptor['reference_kind'] != 'ARRAY' or origin.get('holder') not in ('@helpers', '@api', '@copies', '@parses'):
                    continue
                table = origin['holder'][1:]
                index = origin['helper'] if table == 'helpers' else origin.get('api', origin.get('index', origin.get('parse_index')))
                prior_callers[mode['mode']].append({'model': label, 'binding': key, 'table': table, 'index': index})
    measured = qualify(product, inputs, witnesses, supplement, prior_callers)
    replay = load('replay.json')
    if [r['mode'] for r in replay['modes']] != list(witnesses):
        raise ValueError('whole actual fresh replay mode population')
    for outcome in replay['modes']:
        mode = outcome['mode']
        if type(outcome['status']) is not int or outcome['status'] != supplement['results'][mode]['status']:
            raise ValueError('actual historical mode status; never promote nonzero outcomes')
        if (outcome['programme'] != source['identity']((BASE / 'probe.pl').read_bytes())
                or outcome['product'] != source['identity']((BASE / (mode + '.json')).read_bytes())
                or '1..10\n' not in outcome['stdout']):
            raise ValueError('whole fresh programme/product and completed test receipt')
    first = load('first-replay.json.txt')
    if (replay['first_programme'] != source['identity']((BASE / 'first-replay.py.txt').read_bytes())
            or not oracle['exact'](first, replay['modes'][:2]) or first[1]['status'] == 0):
        raise ValueError('whole actual first runner false-zero requirement failure retained')
    if (BASE / 'probe.pl').read_text() != module('probe_source.py')['build']():
        raise ValueError('complete exact source-prefix instrumentation')
    controls = []
    def rejects(name, change, expected, part='product'):
        candidate, fresh, actual = copy.deepcopy(product), copy.deepcopy(witnesses), copy.deepcopy(replay)
        changed = candidate if part == 'product' else fresh if part == 'witness' else actual
        previous = json.dumps(changed, sort_keys=True)
        change(changed)
        if json.dumps(changed, sort_keys=True) == previous:
            raise ValueError('genuine complete caller control setup: ' + name)
        try:
            if part == 'receipt':
                for r in actual['modes']:
                    if type(r['status']) is not int or r['status'] != supplement['results'][r['mode']]['status']:
                        raise ValueError('actual historical mode status; never promote nonzero outcomes')
            else:
                qualify(candidate, inputs, fresh, supplement, prior_callers)
        except ValueError as error:
            if str(error) != expected:
                raise ValueError('unintended caller control refusal: ' + name + ': ' + str(error)) from error
            controls.append({'name': name, 'refusal': str(error),
                'candidate': source['identity'](json.dumps(changed, sort_keys=True).encode())})
        else:
            raise ValueError('complete caller control admitted: ' + name)
    def view(p, m=0, v=-1):
        return p['modes'][m]['views'][v]
    population = 'complete simultaneous retained caller membership'
    family = 'whole caller family origins/kinds/values and capture membership'
    rejects('lost-capture', lambda p: p['modes'].pop(), 'complete retained caller mode population')
    rejects('borrowed-other-capture', lambda p: p['modes'].__setitem__(0, copy.deepcopy(p['modes'][1])), 'exact retained caller capture domain')
    rejects('lost-caller-family', lambda p: p['modes'][0]['declarations'].pop('consumers'), 'complete caller allocation family population')
    rejects('lost-earliest-api-caller', lambda p: p['modes'][0]['declarations']['api']['callers'].pop(0), family)
    rejects('borrowed-other-copy-caller', lambda p: p['modes'][0]['declarations']['copies']['callers'].__setitem__(0,
        copy.deepcopy(p['modes'][0]['declarations']['copies']['callers'][1])), family)
    rejects('wrong-caller-reference-kind', lambda p: p['modes'][0]['declarations']['api'].update(reference_kind='HASH'), family)
    rejects('test-copy-lexical-allocation-erased', lambda p: p['modes'][0]['declarations']['copies']['lexical_caller_indices'].clear(), family)
    rejects('wrong-caller-global-holder', lambda p: p['modes'][0]['declarations']['helpers'].update(holder='@api'), family)
    rejects('lost-refusal-view', lambda p: p['modes'][0]['views'].pop(), 'complete retained caller source-view population')
    rejects('borrowed-earlier-phase', lambda p: view(p).update(domain=copy.deepcopy(view(p,v=0)['domain'])), 'exact retained caller throw/capture/phase domain')
    rejects('Boolean-refusal-phase', lambda p: view(p)['domain'].__setitem__(3, False), 'exact retained caller throw/capture/phase domain')
    rejects('borrowed-earlier-catcher', lambda p: view(p).update(checkpoint=copy.deepcopy(view(p,v=0)['checkpoint'])), 'complete inner caught and outer source checkpoint bridge')
    rejects('earlier-unrelated-api-callers-lost', lambda p: view(p)['held_prefixes'][0].update(first=8990), population)
    rejects('bounded-context-population-substituted', lambda p: view(p)['held_prefixes'][0].update(end=293), population)
    rejects('earlier-private-and-test-copy-callers-lost', lambda p: view(p)['held_prefixes'][1].update(first=646), population)
    rejects('assertion-callers-omitted', lambda p: view(p)['held_prefixes'].pop(), population)
    rejects('prior-helper-callers-omitted', lambda p: view(p)['held_prefixes'][2].update(first=41), population)
    rejects('prior-parser-caller-omitted', lambda p: view(p)['held_prefixes'][3].update(first=2), population)
    rejects('Boolean-prefix-end', lambda p: view(p)['held_prefixes'][0].update(end=True), population)
    rejects('duplicate-prefix-family', lambda p: view(p)['held_prefixes'].append(copy.deepcopy(view(p)['held_prefixes'][0])), population)
    rejects('held-population-recount-erased', lambda p: view(p).update(population=344), 'exact retained caller population')
    rejects('Boolean-population', lambda p: view(p).update(population=True), 'exact retained caller population')
    rejects('missing-source-distinction', lambda p: view(p)['source_distinct'].update(pairs=view(p)['source_distinct']['pairs']-1), 'complete simultaneous fresh caller source distinction relation')
    rejects('trial-caller-alias-omitted', lambda p: view(p,m=2)['trial_aliases'].pop(), 'trial records reuse test-copy caller arrays without fresh allocation')
    rejects('trial-caller-aliased-to-other-copy', lambda p: view(p,m=2)['trial_aliases'][0]['member'].__setitem__(2,
        view(p,m=2)['trial_aliases'][-1]['member'][2]), 'trial records reuse test-copy caller arrays without fresh allocation')
    rejects('trial-promoted-to-fresh-caller', lambda p: view(p,m=2)['held_prefixes'].append({'table':'trials','first':0,'end':34}), population)
    rejects('lost-inherited-caller-bridge', lambda p: p['modes'][0]['inherited_caller_bridges'].pop(), 'complete inherited caller origin bridge population')
    rejects('lost-conserved-Value-model', lambda p: p['conserved_models'].pop('docs/audits/address-value-core-20261010/hypotheses.json'), 'every complete predecessor source model conserved')
    rejects('encoded-carrier-promoted-to-holder', lambda p: p['excluded'].remove('encoded source graph carriers'), 'observer carriers and inactive payload exclusion')
    rejects('native-source-scope-promoted', lambda p: p.update(scope='All original native identities measured'), 'observer caller source-only scope')
    rejects('lost-fresh-caller-header', lambda w: w['ordinary']['headers']['api'].pop(), 'every original caller-bearing header joins the fresh source execution', 'witness')
    rejects('missing-fresh-refusal-snapshot', lambda w: w['ordinary']['snapshots'].pop(), 'every failed original catcher snapshot exactly once', 'witness')
    rejects('duplicated-fresh-refusal-snapshot', lambda w: w['ordinary']['snapshots'].append(copy.deepcopy(w['ordinary']['snapshots'][0])), 'every failed original catcher snapshot exactly once', 'witness')
    rejects('wrong-fresh-retention-bound', lambda w: w['ordinary']['snapshots'][-1]['prefixes'].update(copies=0), 'independent original ordering and fresh prefix witness agree', 'witness')
    rejects('historical-nonzero-promoted', lambda r: r['modes'][1].update(status=0), 'actual historical mode status; never promote nonzero outcomes', 'receipt')
    if '--local' in sys.argv:
        print('PASS complete local caller model and', len(controls), 'genuine controls; fresh predecessor custody remains required.')
        return
    binding = load('binding.json')
    durability = module('durability.py')['qualify'](inputs, binding)
    extra, pins = module('intake.py')['rebuild']()
    if not oracle['exact'](extra, supplement) or not oracle['exact'](pins, load('supplement-binding.json')):
        raise ValueError('whole supplemental original result/trial/bridge custody')
    proof = {'binding': binding, 'durability': durability, 'supplement_binding': pins, 'measured': measured, 'controls': controls,
             'fresh_replay': source['identity']((BASE / 'replay.json').read_bytes()),
             'first_runner_failure': {'programme': replay['first_programme'],
                'receipt': source['identity']((BASE / 'first-replay.json.txt').read_bytes()),
                'repair': 'Conserve actual historical mode statuses; storable4 and controls5 are not promoted to passing tests.'},
             'programmes': {name: source['identity']((BASE / name).read_bytes()) for name in
                ('source.py', 'intake.py', 'model.py', 'oracle.py', 'probe_source.py', 'probe.pl', 'replay.py', 'verify.py', 'durability.py')},
             'scope': product['scope']}
    target = BASE / 'proof.json'
    if target.exists() and not oracle['exact'](proof, load('proof.json')):
        raise ValueError('whole immutable complete source caller proof')
    if not target.exists():
        target.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
