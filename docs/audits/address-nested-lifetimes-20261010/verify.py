"""Complete nested source replay and actual-source hostile controls."""
import copy
import json
from pathlib import Path

BASE = Path('docs/audits/address-nested-lifetimes-20261010')


def load(name):
    return json.loads((BASE / name).read_bytes())


def module(name):
    path = BASE / name
    namespace = {'__name__': 'nested_source_qualification'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


def main():
    source = module('source.py')
    inputs, custody = source['rebuild']()
    if inputs != load('inputs.json') or custody != load('binding.json'):
        raise ValueError('whole rederived nested source cohort and fixed Git custody')
    thaw = source['module'](Path('docs/audits/record-value-original-value-frames-20261005/verify.py'))['primary']['graph']['thaw']
    actual = load('hypotheses.json')
    if actual != module('model.py')['derive'](inputs, thaw):
        raise ValueError('whole retained deterministic nested source hypotheses')
    qualify = module('oracle.py')['qualify']
    measured = qualify(actual, inputs)
    # Retain and reproduce the actual first oracle's Boolean-domain admission.
    first_proof = load('first-proof.json.txt')
    for name, pin in first_proof['programmes'].items():
        retained = 'first-' + name + '.txt' if name in ('oracle.py', 'verify.py') else name
        if source['identity']((BASE / retained).read_bytes()) != pin:
            raise ValueError('whole first nested source qualification programme')
    first_outcome = load('checks.json')['first-independent']
    if type(first_outcome['status']) is not int or first_outcome['status'] != 0:
        raise ValueError('actual first nested qualification outcome')
    if first_outcome['instruments'][str(BASE / 'verify.py')] != first_proof['programmes']['verify.py']:
        raise ValueError('first actual nested programme outcome binding')
    first_candidate = copy.deepcopy(actual)
    domain = first_candidate['cases'][0]['views'][2]['operation_bridges'][0]['domain']
    if type(domain[3]) is not int or domain[3] != 1:
        raise ValueError('actual first later-phase Boolean control setup')
    domain[3] = True
    admission = load('boolean-bridge-first-admission.json')
    if (module('first-oracle.py.txt')['qualify'](first_candidate, inputs) != admission['first_oracle_measured']
            or admission['first_oracle_measured'] != first_proof['measured']
            or source['identity'](json.dumps(first_candidate, sort_keys=True).encode())['sha256'] != admission['candidate_sha256']):
        raise ValueError('whole reproduced first Boolean operation-bridge admission')
    original_operations = source['load'](source['OP'] / 'hypotheses.json')
    pending = {tuple(op['domain']) for case in original_operations['cases'] for op in case['operations']
               if op['input_topology'] == 'nested successor-owned'}
    resolved = {tuple(bridge['domain']) for case in actual['cases'] for view in case['views'] for bridge in view['operation_bridges']
                if bridge['previous_input_topology'] == 'nested successor-owned'}
    if resolved != pending:
        raise ValueError('complete original nested-operation source frontier resolved')
    controls = []
    def rejects(name, mutate, expected):
        candidate = copy.deepcopy(actual)
        mutate(candidate)
        try:
            qualify(candidate, inputs)
        except ValueError as error:
            if str(error) != expected:
                raise ValueError('unintended nested control refusal: ' + name + ': ' + str(error)) from error
            controls.append({'name': name, 'refusal': str(error),
                             'whole_candidate_identity': source['identity'](json.dumps(candidate, sort_keys=True).encode())})
        else:
            raise ValueError('genuine complete nested source control admitted: ' + name)
    def first(product):
        return product['cases'][0]
    def outer(product):
        return first(product)['views'][2]
    def visible(product, pool):
        case = first(product)
        for occurrence in case['views'][0]['occurrences']:
            descriptor = case['bindings'][occurrence['binding']]
            if descriptor['origin'].get('pool') == pool:
                return descriptor
        raise ValueError('actual nested visible pool control setup: ' + pool)
    other = inputs['cases'][1]
    rejects('lost-pair', lambda p: p['cases'].pop(), 'complete nested source pair membership')
    rejects('lost-throw-view', lambda p: first(p)['views'].pop(), 'complete nested source-record/throw views')
    rejects('lost-reference-slot', lambda p: first(p)['views'][0]['occurrences'].pop(), 'every nested core/operation reference slot exactly once')
    rejects('lost-operation-view', lambda p: first(p)['views'][0]['operation_bridges'].pop(), 'complete joined nested operation source bindings/domains')
    rejects('borrowed-actual-capture', lambda p: first(p)['views'][0].update(record_api=other['metadata_input']['pair']['capture_api']),
            'exact nested source record/throw-view domain')
    rejects('borrowed-actual-later-phase', lambda p: first(p)['views'][1].update(phase=outer(p)['phase']),
            'exact nested source record/throw-view domain')
    rejects('boolean-outer-phase', lambda p: outer(p).update(phase=True), 'exact nested source record/throw-view domain')
    def boolean_bridge(product):
        domain = outer(product)['operation_bridges'][0]['domain']
        if type(domain[3]) is not int or domain[3] != 1:
            raise ValueError('actual existing outer operation phase setup')
        domain[3] = True
    rejects('boolean-existing-operation-bridge-phase', boolean_bridge, 'complete joined nested operation source bindings/domains')
    rejects('boolean-returned-holder', lambda p: outer(p)['returned_copy_delegates'][0].update(active_source_holder=1),
            'nested returned-copy holder Boolean kind')
    rejects('borrowed-actual-Value-copy', lambda p: visible(p, 'value_private')['origin'].update(copy_index=other['value_private']['domain'][1]),
            'nested source binding origin and kind')
    rejects('borrowed-actual-Metadata-copy', lambda p: visible(p, 'metadata_private')['origin'].update(copy_index=other['metadata_input']['private']['domain'][1]),
            'nested source binding origin and kind')
    rejects('borrowed-Value-root-for-type', lambda p: visible(p, 'value_private')['origin'].update(node='/1'),
            'nested source binding origin and kind')
    rejects('wrong-reference-kind', lambda p: visible(p, 'metadata_private').update(reference_kind='ARRAY'),
            'nested source binding origin and kind')
    def split_constructed_type(product):
        spec = copy.deepcopy(inputs['cases'][0]['value_private']['result'][1]['type_spec'])
        if '"reference"' in json.dumps(spec):
            raise ValueError('actual acyclic equal-payload constructor control setup')
        port = first(product)['joint_source_graph'][1][2][1]['inputs'][1][0][1]
        if port['type_spec'] != ['reference', '/1/type_spec']:
            raise ValueError('actual checked/spec source alias setup')
        port['type_spec'] = spec
    rejects('split-constructed-type-from-Value-root', split_constructed_type, 'whole nested source graph topology/value/alias')
    rejects('Metadata-copy-aliased-to-Value-type', lambda p: first(p)['joint_source_graph'][1][3][1]['inputs'][1][0][1].update(
            type_spec=['reference', '/1/type_spec']), 'whole nested source graph topology/value/alias')
    def wrong_cycle(product):
        case = next(case for case, src in zip(product['cases'], inputs['cases'], strict=True)
                    if src['metadata_input']['capture']['guard'] == 'metadata_type.2')
        member = case['joint_source_graph'][1][1][1]['type_spec'][1]['members'][1]
        if member['data'] != ['reference', '/1/type_spec']:
            raise ValueError('actual cyclic Value source referent setup')
        member['data'] = ['reference', '/1']
    rejects('cycle-borrowed-existing-root', wrong_cycle, 'whole nested source graph topology/value/alias')
    def split_phase_binding(product, original):
        case = first(product)
        case['bindings']['split-across-source-phases'] = copy.deepcopy(case['bindings'][original])
        changed = False
        for occurrence in case['views'][2]['occurrences']:
            if occurrence['binding'] == original:
                occurrence['binding'] = 'split-across-source-phases'
                changed = True
        if not changed:
            raise ValueError('actual cross-phase source referent setup')
    rejects('split-retained-Scope-caller', lambda p: split_phase_binding(p, 'caller:scope'), 'nested source alias equivalence across views')
    rejects('split-retained-Value-type', lambda p: split_phase_binding(p, 'node:/1/type_spec'), 'nested source alias equivalence across views')
    def split_forwarded_interface(product):
        case = first(product)
        case['bindings']['split-forwarded-interface'] = copy.deepcopy(case['bindings']['node:/2'])
        view = case['views'][0]
        frame = next(i for i, f in enumerate(view['frames']) if f['call_site'] == 'installed_capture_wrapper')
        next(r for r in view['occurrences'] if r['frame'] == frame)['binding'] = 'split-forwarded-interface'
    rejects('split-one-forwarded-interface', split_forwarded_interface, 'nested source alias equivalence across views')
    rejects('borrowed-actual-caller-snapshot', lambda p: first(p)['bindings']['caller:scope']['origin'].update(api=first(p)['capture_api']),
            'nested source binding origin and kind')
    rejects('borrowed-saved-operation-lookup', lambda p: first(p)['bindings']['saved:scope']['origin'].update(expression='$capture'),
            'nested source binding origin and kind')
    rejects('inactive-capture-promoted-to-active', lambda p: outer(p)['active_invocations'].append(['capture', first(p)['capture_api']]),
            'nested active/retained/returned source holders')
    rejects('returned-copy-delegate-reactivated', lambda p: outer(p)['returned_copy_delegates'][0].update(activation='active delegate'),
            'nested active/retained/returned source holders')
    rejects('retained-capture-caller-lost', lambda p: outer(p)['source_retained_bindings'].remove('caller:capture'),
            'nested active/retained/returned source holders')
    rejects('inactive-Metadata-sink-promoted-to-active', lambda p: outer(p)['active_bindings'].append('metadata:sink'),
            'nested active/retained/returned source holders')
    rejects('Value-root-holder-lost', lambda p: outer(p)['returned_copy_delegates'][0].update(active_source_holder=False),
            'nested active/retained/returned source holders')
    rejects('Metadata-result-holder-invented', lambda p: outer(p)['returned_copy_delegates'][1].update(active_source_holder=True),
            'nested active/retained/returned source holders')
    rejects('lost-resolved-operation-binding', lambda p: first(p)['views'][0]['operation_bridges'][0]['bindings'].pop('saved-operation'),
            'complete joined nested operation source bindings/domains')
    rejects('borrowed-actual-other-record-domain', lambda p: first(p)['views'][0]['operation_bridges'][0].update(
            domain=first(p)['views'][1]['operation_bridges'][0]['domain']), 'complete joined nested operation source bindings/domains')
    rejects('lost-live-distinction', lambda p: first(p)['views'][0]['simultaneously_live_distinct'].pop(),
            'complete nested live distinctions and explicit opaque CODE relation')
    rejects('opaque-CODE-relation-promoted', lambda p: first(p)['views'][0]['unresolved_distinctions'].clear(),
            'complete nested live distinctions and explicit opaque CODE relation')
    rejects('borrowed-entire-inner-error-value', lambda p: outer(p)['frames'][0]['arguments'][1].update(
            value=other['inherited']['new_outer_path'][0]['arguments'][1]['value']), 'whole qualified nested source frames')
    rejects('native-identity-promotion', lambda p: p.update(scope='Original numeric and native reference identity measured'), 'nested source-only open scopes')
    proof = {'binding': custody, 'measured': measured, 'controls': controls,
             'Boolean_bridge_repair': {name: source['identity']((BASE / name).read_bytes()) for name in
                 ('first-oracle.py.txt', 'first-verify.py.txt', 'first-proof.json.txt', 'boolean-bridge-first-admission.json')},
             'complete_original_pending_operation_domains': [list(domain) for domain in sorted(pending)],
             'actual_borrowed_witnesses': {'capture_api': other['metadata_input']['pair']['capture_api'],
                 'Value_copy': other['value_private']['domain'][1], 'Metadata_copy': other['metadata_input']['private']['domain'][1],
                 'same_call_later_phase': [actual['cases'][0]['scope_api'], actual['cases'][0]['views'][2]['phase']]},
             'programmes': {name: source['identity']((BASE / name).read_bytes()) for name in ('source.py', 'model.py', 'oracle.py', 'verify.py')},
             'legs': {'re_derivation': 'fresh complete predecessor readers, runtime source constructor alias graph and full core/operation slot join',
                      'falsification': 'independent graph bijections, semantic member walks, source-expression/phase-holder oracle and actual-source hostile controls',
                      'durability': 'whole fixed Git source/catch/forward/prerequisite custody and tracked complete inputs/hypotheses/programmes/proof/results'},
             'missing_legs': 'Original numeric/private/provider/formatter/CODE identity, external/global retention, helper/parser roles, canonical address publication and visual QA.'}
    target = BASE / 'proof.json'
    if target.exists() and load('proof.json') != proof:
        raise ValueError('whole retained dated nested source proof')
    if not target.exists():
        target.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS complete nested source aliases, all throw views, retained snapshots and resolved operation roles; numeric/native identities remain open.')


if __name__ == '__main__':
    main()
