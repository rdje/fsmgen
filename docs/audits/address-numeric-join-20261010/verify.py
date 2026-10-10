"""Qualify the complete original numerical join with genuine whole-product controls."""
import copy
import json
import re
import runpy
from pathlib import Path

BASE = Path('docs/audits/address-numeric-join-20261010')
SUCCESS = ('PASS complete independent original numerical source join; genuine alias/distinction/kind/domain '
           'controls reject; full parent acceptance and native identity remain open.\n')


def main():
    oracle = runpy.run_path(str(BASE / 'oracle.py'))
    need, same, pin = (oracle[k] for k in ('need', 'same', 'pin'))
    intake = runpy.run_path(str(BASE / 'source.py'))
    spec, binding = intake['rebuild']()
    need(same(spec, json.loads((BASE / 'inputs.json').read_bytes()))
         and same(binding, json.loads((BASE / 'binding.json').read_bytes())), 'complete immutable numerical source intake')
    registry, data = oracle['fixed_inputs']()
    allocation, views, counts = oracle['reconstruct'](data)
    product = json.loads((BASE / 'joining.json').read_bytes())
    qualify = lambda p: oracle['qualify'](p, registry, allocation, views)
    qualify(product)
    controls = []

    def reject(name, mutate, cause, numerical_only=False):
        candidate = copy.deepcopy(product)
        mutate(candidate)
        need(not same(candidate, product), 'genuine complete numerical control: ' + name)
        if numerical_only:
            # Prior complete products stay identical, as do all nonnumerical
            # source/domain/slot/holder/shape meanings in this interpretation.
            conserved = copy.deepcopy(candidate)
            for changed, original in zip(conserved['views'], product['views']):
                for row, wanted in zip(changed['references'], original['references']):
                    for field in ('hex', 'numeric_key', 'raw'):
                        row[field] = wanted[field]
                changed['source_alias_classes'] = original['source_alias_classes']
                changed['pairs'] = original['pairs']
            need(same(conserved, product), 'complete nonnumerical meaning conservation: ' + name)
        try:
            qualify(candidate)
        except ValueError as error:
            need(str(error) == cause, 'intended numerical refusal: ' + name + ': ' + str(error))
            controls.append({'name': name, 'refusal': cause,
                             'whole_candidate': pin(json.dumps(candidate, sort_keys=True).encode()),
                             'conserved': ('Complete prior input products and nonnumerical source/holder/domain/slot/shape meanings. '
                                           'Only derived numerical interpretation and its aggregates change; no mutated original capture is admitted.'
                                           if numerical_only else 'Fixed original inputs; targeted derived product contract is changed.')})
        else:
            raise ValueError('false-green complete numerical control: ' + name)

    def first(p):
        return p['views'][0]

    reject('unknown-native-field', lambda p: p.update(original_native_identity=True), 'closed complete numerical join')
    reject('native-identity-promotion', lambda p: p.update(scope='Equal numbers prove native objects'), 'exact numerical owner and native/reuse scope')
    reject('borrowed-owner', lambda p: p.update(owner='foreign'), 'exact numerical owner and native/reuse scope')
    reject('lost-holder-input', lambda p: p['inputs'].pop('holders'), 'whole fixed numerical input identity')
    reject('borrowed-binding', lambda p: p.update(binding=p['inputs']['source']['identity']), 'whole fixed numerical input identity')
    reject('lost-mode', lambda p: p['allocation'].pop(), 'complete original parsed allocation and opaque operand conservation')
    reject('lost-empty-record', lambda p: p['allocation'][0]['domains']['api']['empty'].pop(),
           'complete original parsed allocation and opaque operand conservation')
    reject('lost-record-body', lambda p: p['allocation'][0]['domains']['api']['records'][0].pop('body_identity'),
           'complete original parsed allocation and opaque operand conservation')
    forwarded = next((mi, name, ri) for mi, mode in enumerate(product['allocation']) for name, domain in mode['domains'].items()
                     for ri, record in enumerate(domain['records']) if record['forwarded'] is not None)
    opaque_at = next((mi, name, ri) for mi, mode in enumerate(product['allocation']) for name, domain in mode['domains'].items()
                     for ri, record in enumerate(domain['records']) if record['opaque_reference_operands'])

    def record_at(p, location):
        mi, name, ri = location
        return p['allocation'][mi]['domains'][name]['records'][ri]

    reject('lost-nested-forwarding', lambda p: record_at(p, forwarded).update(forwarded=None),
           'complete original parsed allocation and opaque operand conservation')
    reject('lost-opaque-external-reference', lambda p: record_at(p, opaque_at)['opaque_reference_operands'].pop(),
           'complete original parsed allocation and opaque operand conservation')
    reject('lost-view', lambda p: p['views'].pop(), 'complete numerical view population')
    reject('unknown-view-field', lambda p: first(p).update(global_identity=True), 'closed complete numerical source view')
    reject('borrowed-whole-source-view', lambda p: first(p).update(whole_source_view=p['views'][1]['whole_source_view']),
           'exact original simultaneous numerical source domain')
    reject('borrowed-whole-holder-view', lambda p: first(p).update(whole_holder_view=p['views'][1]['whole_holder_view']),
           'exact original simultaneous numerical source domain')
    reject('lost-reference-slot', lambda p: first(p)['references'].pop(), 'complete own numerical reference slot population')
    reject('unknown-reference-field', lambda p: first(p)['references'][0].update(native_address=True), 'closed original numerical reference operand')
    reject('lost-provenance', lambda p: first(p)['references'][0]['source']['provenance'].pop(), 'exact original source slot binding and provenance')
    reject('borrowed-source-binding', lambda p: first(p)['references'][0]['source'].update(binding=first(p)['references'][1]['source']['binding']),
           'exact original source slot binding and provenance')
    reject('wrong-physical-frame', lambda p: first(p)['references'][0].update(frame_index=0), 'exact original source slot binding and provenance')
    reject('wrong-reference-kind', lambda p: first(p)['references'][0].update(reference_kind='ARRAY'), 'exact original source numerical reference kind')
    reject('wrong-blessed-class', lambda p: first(p)['references'][0].update(display_class='Foreign'), 'exact original source numerical reference kind')
    reject('decimal-address', lambda p: first(p)['references'][0].update(hex='12345'), 'complete numerical hexadecimal grammar')
    reject('Boolean-address', lambda p: first(p)['references'][0].update(hex=True), 'complete numerical hexadecimal grammar')
    reject('wrong-hex-interpretation', lambda p: first(p)['references'][0].update(numeric_key='0x0'), 'exact numerical hexadecimal interpretation')
    reject('lost-original-byte-span', lambda p: first(p)['references'][0]['span'].__setitem__(0, 0),
           'complete original reference operand byte and number association')
    regex_view = next(i for i, v in enumerate(product['views']) if v['unaddressed_source_operands'])
    hidden_view = next(i for i, v in enumerate(product['views']) if v['hidden_arguments'])
    reject('lost-regex-display', lambda p: p['views'][regex_view]['unaddressed_source_operands'].pop(),
           'complete unaddressed regex and hidden source conservation')
    reject('invented-hidden-address', lambda p: p['views'][hidden_view]['hidden_arguments'][0].update(native_address='0x1'),
           'complete unaddressed regex and hidden source conservation')
    reject('external-reference-promotion', lambda p: first(p)['references'].append(record_at(p, opaque_at)['opaque_reference_operands'][0]),
           'complete own numerical reference slot population')
    reject('lost-alias-class', lambda p: first(p)['source_alias_classes'].pop(), 'complete source alias class allocation')
    reject('lost-pair', lambda p: first(p)['pairs'].pop(), 'complete numerical pair relation and opaque CODE partition')
    opaque_view, opaque_pair = next((vi, pi) for vi, v in enumerate(product['views']) for pi, pair in enumerate(v['pairs'])
                                  if pair['source_relation'] == 'opaque_CODE')
    reject('CODE-distinction-promotion', lambda p: p['views'][opaque_view]['pairs'][opaque_pair].update(source_relation='distinct'),
           'complete numerical pair relation and opaque CODE partition')

    def set_number(view, members, lexeme):
        for index in members:
            row = view['references'][index]
            row['raw'] = row['raw'].replace(row['hex'], lexeme)
            row['hex'] = lexeme
            row['numeric_key'] = oracle['number'](lexeme)
        for group in view['source_alias_classes']:
            group['numeric_key'] = view['references'][group['members'][0]]['numeric_key']
        for pair in view['pairs']:
            pair['numeric_equal'] = view['references'][pair['left']]['numeric_key'] == view['references'][pair['right']]['numeric_key']

    for mode in ('ordinary', 'storable', 'controls'):
        # Use actual original HASH displays, explicit aliases, distinct source
        # objects and different captures. No invented number supplies these controls.
        vi, group, distinct = next((vi, a, b) for vi, v in enumerate(product['views']) if v['domain'][0] == mode
                                   for a in v['source_alias_classes'] if len(a['members']) > 1
                                   and v['references'][a['members'][0]]['reference_kind'] == 'HASH'
                                   for b in v['source_alias_classes'] if b['binding'] != a['binding']
                                   and v['references'][b['members'][0]]['reference_kind'] == 'HASH'
                                   and b['numeric_key'] != a['numeric_key'])
        view = product['views'][vi]
        row = view['references'][group['members'][0]]
        sibling = view['references'][distinct['members'][0]]
        other = next(r for v in product['views'] if v['domain'][0] != mode for r in v['references']
                     if r['reference_kind'] == 'HASH' and len(r['hex']) == len(row['hex'])
                     and r['numeric_key'] not in {x['numeric_key'] for x in view['references']})
        external = next(o['token'] for m in product['allocation'] for d in m['domains'].values() for r in d['records']
                        for o in r['opaque_reference_operands'] if o['token']['hex'] != row['hex'])
        reject(mode + '-borrowed-source-number', lambda p: set_number(p['views'][vi], group['members'][:1], sibling['hex']),
               'numerical agreement for explicit source aliases', True)
        reject(mode + '-aliased-distinct-source-class', lambda p: set_number(p['views'][vi], group['members'], sibling['hex']),
               'numerical separation for simultaneous source distinctions', True)
        reject(mode + '-borrowed-other-capture-number', lambda p: set_number(p['views'][vi], group['members'][:1], other['hex']),
               'numerical agreement for explicit source aliases', True)
        reject(mode + '-borrowed-external-number', lambda p: set_number(p['views'][vi], group['members'][:1], external['hex']),
               'numerical agreement for explicit source aliases', True)
        reject(mode + '-consistent-other-capture-rename', lambda p: set_number(p['views'][vi], group['members'], other['hex']),
               'complete original reference operand byte and number association', True)
        reject(mode + '-wrong-source-domain', lambda p: p['views'][vi]['domain'].__setitem__(0, 'foreign'),
               'exact original simultaneous numerical source domain')

    actual = json.loads((BASE / 'checks.json').read_bytes())['joining']
    instruments = [str(BASE / name) for name in ('checks.py', 'join.py')] + ['scripts/run_with_ram_guard.sh']
    need(set(actual) == {'command', 'status', 'stdout', 'stderr', 'instruments'} and type(actual['status']) is int
         and actual['status'] == 0 and actual['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / 'join.py')]
         and actual['stdout'] == 'PASS complete finite original source/numerical join produced; independent qualification and full parent acceptance remain required.\n'
         and actual['instruments'] == {p: pin(Path(p).read_bytes()) for p in instruments}
         and re.fullmatch(r'ram-guard: PID [0-9]+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', actual['stderr']),
         'actual complete original numerical join producer')
    proof = {'scope': product['scope'], 'joining': pin((BASE / 'joining.json').read_bytes()), 'measured': counts,
             'controls': controls, 'programmes': {n: pin((BASE / n).read_bytes()) for n in ('source.py', 'join.py', 'oracle.py', 'verify.py', 'checks.py')},
             'legs': {'re_derivation': 'join.py joins complete original parsed reference operands and exact source roles/holders, exhaustively deriving equality/distinction/opaque pairs per simultaneous view.',
                      'falsification': 'oracle.py independently reads fixed original Git bytes and coordinate/source domains, parses original reference spans, manually interprets hex, then checks source-to-number and number-to-source relations; genuine whole-product controls reject.',
                      'durability': 'Whole fixed input registry/custody, original operands, corrected holders, complete numerical product, independent programmes/results and task/book/Git checkpoint retain.'},
             'missing_legs': 'Full unchanged raw-parent acceptance remains N.3. Provider/formatter/native identity/payload/flags, CODE/CODE and Regexp identities, cross-call/capture reuse, global heap census, cold replay, visual QA and governed canonical publication remain open. No fresh original capture or native observation.'}
    target = BASE / 'proof.json'
    if target.exists():
        need(same(json.loads(target.read_bytes()), proof), 'whole immutable numerical qualification')
    else:
        target.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
