"""Qualify complete active-operation source retention before numerical joins."""
import copy
import json
import re
import runpy
from pathlib import Path

BASE = Path('docs/audits/address-raw-join-20261010')
SUCCESS = ('PASS complete independent active-operation source holder retention and relation; genuine separating controls reject; '
           'original numerical joins and native meanings remain open.\n')


def main():
    oracle = runpy.run_path(str(BASE / 'oracle.py'))
    need, same, pin = (oracle[k] for k in ('need', 'same', 'pin'))
    intake = runpy.run_path(str(BASE / 'source.py'))
    spec, binding = intake['rebuild']()
    need(same(spec, json.loads((BASE / 'inputs.json').read_bytes()))
         and same(binding, json.loads((BASE / 'binding.json').read_bytes())), 'complete immutable holder source intake')
    registry, data, raw = oracle['fixed_inputs']()
    witness = oracle['retention'](raw)
    expected, counts = oracle['reconstruct'](data, witness)
    product = json.loads((BASE / 'holders.json').read_bytes())
    qualify = lambda p: oracle['qualify'](p, registry, witness, expected)
    qualify(product)
    controls = []

    def reject(name, mutate, cause):
        candidate = copy.deepcopy(product); mutate(candidate)
        need(not same(candidate, product), 'genuine complete holder control: ' + name)
        try:
            qualify(candidate)
        except ValueError as error:
            need(str(error) == cause, 'intended holder refusal: ' + name + ': ' + str(error))
            controls.append({'name': name, 'refusal': cause, 'whole_candidate': pin(json.dumps(candidate, sort_keys=True).encode())})
        else:
            raise ValueError('false-green complete holder control: ' + name)

    def view(p):
        return p['modes'][0]['views'][0]

    def addition(p):
        return view(p)['additional_active_argument_holders'][0]

    original_view = data['source']['modes'][0]['views'][0]
    returned = original_view['lifetime']['successful_returned_api_invocations'][0]
    private = next(k for k in original_view['held_source_bindings'] if 'copy-result:' in k)
    carrier = next(k for k in original_view['graph_groups'] if k not in original_view['held_source_bindings'])
    inactive = next(v for v in data['source']['modes'][0]['views'] if v['no_active_own_holder'])
    inactive_key = inactive['no_active_own_holder'][0]
    reject('unknown-native-field', lambda p: p.update(original_native_identity='proved'), 'closed complete holder supplement')
    reject('native-CODE-promotion', lambda p: p.update(scope='Saved CODE numbers prove native object identity'), 'exact source holder owner and native scope')
    reject('borrowed-owner', lambda p: p.update(owner='foreign'), 'exact source holder owner and native scope')
    reject('lost-source-input', lambda p: p['inputs'].pop('observer_source'), 'whole holder input identity')
    reject('lost-whole-function-byte', lambda p: p['retention_source'].update(function=p['retention_source']['function'][1:]),
           'complete original lexical operation retention witness')
    reject('borrowed-invocation-span', lambda p: p['retention_source'].update(invocation_span=p['retention_source']['declaration_span']),
           'complete original lexical operation retention witness')
    reject('lost-mode', lambda p: p['modes'].pop(), 'complete holder mode population')
    reject('lost-view', lambda p: p['modes'][0]['views'].pop(), 'complete holder view allocation')
    reject('borrowed-capture-phase', lambda p: view(p)['domain'].__setitem__(0, 'storable'), 'whole original holder source phase')
    reject('returned-invocation-phase', lambda p: view(p)['domain'].__setitem__(2, returned), 'whole original holder source phase')
    reject('lost-prior-holder', lambda p: view(p)['prior_held_source_bindings'].pop(), 'complete prior source holder relation conservation')
    reject('lost-caller-prefix', lambda p: view(p)['retained_caller_prefixes'].pop(), 'complete prior source holder relation conservation')
    reject('wrong-prior-distinction', lambda p: view(p)['prior_distinctions'].update(pairs=0), 'complete prior source holder relation conservation')
    reject('lost-active-operation-holder', lambda p: view(p)['additional_active_argument_holders'].pop(), 'complete active saved-operation argument holders')
    reject('wrong-operation-reference-kind', lambda p: addition(p).update(reference_kind='HASH'), 'complete active saved-operation argument holders')
    reject('borrowed-private-result', lambda p: addition(p).update(binding=private), 'complete active saved-operation argument holders')
    reject('borrowed-inactive-root', lambda p: addition(p).update(binding=inactive_key), 'complete active saved-operation argument holders')
    reject('wrong-operation-argument', lambda p: addition(p)['source_slots'][0].__setitem__(1, 2), 'complete active saved-operation argument holders')
    reject('borrowed-source-origin', lambda p: addition(p).update(source_origins=original_view['bindings'][private]['origins']),
           'complete active saved-operation argument holders')
    reject('invent-native-parameter-field', lambda p: addition(p).update(native_identity='proved'), 'complete active saved-operation argument holders')
    reject('lost-supplemented-held-member', lambda p: view(p)['held_source_bindings'].remove(addition(p)['binding']),
           'complete supplemented source held members')
    reject('symbolic-carrier-as-holder', lambda p: view(p)['held_source_bindings'].append(carrier), 'complete supplemented source held members')
    reject('Boolean-population', lambda p: view(p)['source_distinctions'].update(population=True), 'complete supplemented source distinction and opaque CODE relation')
    reject('lost-new-distinction-pairs', lambda p: view(p).update(additional_distinction_pairs=0), 'complete supplemented source distinction and opaque CODE relation')
    reject('CODE-CODE-distinction-promotion', lambda p: view(p)['source_distinctions'].update(relation='all distinct held member pairs including CODE/CODE'),
           'complete supplemented source distinction and opaque CODE relation')
    reject('lost-opaque-CODE-member', lambda p: view(p)['source_distinctions']['opaque_CODE_members'].pop(),
           'complete supplemented source distinction and opaque CODE relation')
    actual = json.loads((BASE / 'checks.json').read_bytes())['holders']
    instruments = {str(BASE / 'checks.py'), str(BASE / 'holders.py'), 'scripts/run_with_ram_guard.sh'}
    need(set(actual) == {'command', 'status', 'stdout', 'stderr', 'instruments'} and type(actual['status']) is int
         and actual['status'] == 0 and actual['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / 'holders.py')]
         and actual['stdout'] == 'PASS complete active-operation source holder supplement produced; independent qualification and numerical joins remain required.\n'
         and actual['instruments'] == {p: pin(Path(p).read_bytes()) for p in instruments}
         and re.fullmatch(r'ram-guard: PID [0-9]+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', actual['stderr']),
         'actual complete source holder producer')
    proof = {'scope': product['scope'], 'holder_product': pin((BASE / 'holders.json').read_bytes()),
             'measured': counts, 'controls': controls,
             'programmes': {name: pin((BASE / name).read_bytes()) for name in ('source.py', 'holders.py', 'oracle.py', 'verify.py', 'checks.py')},
             'legs': {'re_derivation': 'holders.py conserves whole qualified source views and adds only explicit active call_api saved-operation parameter holders from the complete original source.',
                      'falsification': 'oracle.py separately reads fixed Git bytes, scans whole named source lines, enumerates complete caller sets and reconstructs all prior/new holders and pair relations; genuine complete product controls reject.',
                      'durability': 'Whole fixed original/source/parsed inputs, prior namespaces/products, full function witness and supplement, actual programmes/results, defect ownership and task/book/Git checkpoint retain.'},
             'missing_legs': 'Source retention and allocation hypothesis only. Numerical reference-role joins remain J.3.2; full raw parent closure is J.3.3. Native payload/flags/provider/formatter/CODE/Regexp identity, cross-call reuse, global heap, cold replay, visual QA and governed current publication remain open.'}
    path = BASE / 'proof.json'
    if path.exists():
        need(same(json.loads(path.read_bytes()), proof), 'whole immutable source holder qualification')
    else:
        path.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
