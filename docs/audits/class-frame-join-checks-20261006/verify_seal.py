"""Independently consume the full actual finite class/frame semantic seal."""
import copy
import re
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-join-20261006')
CHECKS = Path('docs/audits/class-frame-join-checks-20261006')
ns = {'__name__': 'independent_class_frame_join', '__file__': str(BASE / 'verify.py')}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
require, same, identity, load = (ns[k] for k in ('require', 'same', 'identity', 'load'))
COMMAND = ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / 'verify.py'), '--seal']


def header(receipt):
    require(type(receipt['status']) is int and receipt['status'] == 0, 'actual class/frame integer process success')
    require(receipt['command'] == COMMAND and receipt['stdout'] == ns['SUCCESS'], 'exact actual class/frame semantic command and complete output role')
    require(re.fullmatch(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', receipt['stderr']) is not None,
            'actual class/frame default guard diagnostics')
    require(set(receipt['instruments']) == {str(CHECKS / 'run.py'), str(BASE / 'verify.py'), 'scripts/run_with_ram_guard.sh'}
        and all(same(pin, identity(Path(p).read_bytes())) for p,pin in receipt['instruments'].items()),
        'whole actual class/frame invocation programmes')
    require(all(type(pin['bytes']) is int and pin['bytes'] >= 0 for pin in receipt['whole_members'].values()), 'actual class/frame discrete sealed byte-count kinds')
    whole = {str(Path(p).relative_to(BASE)):pin for p,pin in ns['whole'](BASE).items()}
    require(same(receipt['whole_members'], whole), 'every actual class/frame sealed member conserves')
    original = load(CHECKS / 'seal-command.json')
    require(same({k:receipt[k] for k in original}, original)
        and same(receipt['actual_result_identity'], identity((CHECKS / 'seal-command.json').read_bytes())), 'whole untouched actual class/frame result identity')
    require(same(load(BASE / 'manifest.json'), ns['members']()), 'whole immutable class/frame semantic seal')
    return whole


def check(receipt):
    before = header(receipt)
    require(same(ns['binding'](), load(BASE / 'binding.json')), 'whole independently regenerated fixed-Git input member task and completed-owner custody')
    expected = ns['source_models']()
    require(same(ns['prerequisite_replay'](False), load(BASE / 'prerequisite-proof.json')), 'whole independently consumed actual prerequisite admission replay')
    raw = ns['admission']['raw_product']()
    require(same(raw, load(BASE / 'raw-product.json')), 'whole independently regenerated raw allocations bodies contexts and controls')
    native = raw['inventories']
    nested = ns['public']['context']['nested_records'](expected['frame_model']['own'])
    require(same(ns['check'](expected, expected, native, native, nested), load(BASE / 'proofs.json')), 'whole independently regenerated source class/frame body phase and operand meanings')
    require(same(ns['controls'](expected, native, nested), load(BASE / 'controls.json')), 'whole independently regenerated genuine class/frame separating controls')
    book = ns['module'](BASE / 'book.py')
    require(same(book['proof']((BASE / 'book-input.html').read_text()), load(BASE / 'book-proof.json')), 'whole regenerated native semantic guide and controls')
    initial = load(CHECKS / 'preparation.json')
    require(type(initial['status']) is int and initial['status'] == 1
        and initial['command'] == COMMAND[:-1] + ['--prepare']
        and initial['stderr'].endswith('ValueError: complete source-derived own API frame order\n')
        and same(initial['instruments'][str(BASE / 'verify.py')], identity((CHECKS / 'first-verify.py.txt').read_bytes())),
        'complete actual first association-alias failure and invocation source')
    legacy_model = ns['module'](CHECKS / 'first-qualified-model.py.txt')
    legacy = legacy_model['derive'](ns['classes'], ns['public'], require, same)
    require(same(legacy, expected), 'retained pre-intake source values unchanged by association object isolation')
    changed = copy.deepcopy(legacy)
    changed['modes'][0]['cases'][0]['phases'][0]['own']['core'].reverse()
    require(not same(changed['frame_model'], legacy['frame_model']), 'genuine first bridge mutation aliases predecessor oracle')
    try:
        ns['prior_predicates'](changed, native, nested)
    except ValueError as error:
        require(str(error) == 'complete source-derived own API frame order', 'independently reproduced association alias root cause')
    else:
        raise ValueError('false-green first aliased bridge separation')
    source_actual = load(CHECKS / 'source-derivation.json')
    prepared = load(CHECKS / 'qualified-preparation.json')
    require(type(prepared['status']) is int and prepared['status'] == 0
        and prepared['command'] == COMMAND[:-1] + ['--prepare'] and prepared['stdout'] == ns['SUCCESS']
        and same(prepared['instruments'][str(BASE / 'verify.py')], identity((CHECKS / 'qualified-reader.py.txt').read_bytes())),
        'whole actual qualified preparation and retained invocation programme')
    initial_source_model = ns['module'](CHECKS / 'initial-model.py.txt')
    retained_source = load(BASE / 'pre-original-models.json')
    require(same(initial_source_model['derive'](ns['classes'], ns['public'], require, same), retained_source)
        and same({k:v for k,v in expected.items() if k != 'scope'}, {k:v for k,v in retained_source.items() if k != 'scope'}),
        'whole first source contract values conserve; inherited operands remain declared opaque evidence')
    source_stdout = ''
    for mode in expected['modes']:
        signatures = sorted({(r['domain'],r['exception']['source_family'],tuple(p['family'] for p in r['phases'])) for r in mode['cases']})
        source_stdout += str(mode['mode']) + ' complete source cases ' + str(len(mode['cases'])) + ' class/phase signatures ' + str(signatures) + '\n'
    source_stdout += 'PASS qualified source associations retained before new original intake; predecessor serialized operands are opaque evidence and the initial terminal has no invented receipt.\n'
    require(source_actual['stdout'] == source_stdout, 'complete actual source-derivation output regenerates independently')
    legacy_book = ns['module'](CHECKS / 'first-book.py.txt')
    try:
        legacy_book['proof']((BASE / 'book-input.html').read_text())
    except ValueError as error:
        require(str(error) == 'native complete class/frame scope and retained gaps', 'independently reproduced finite renderer apostrophe mismatch')
    else:
        raise ValueError('false-green first finite guide glyph check')
    actual_legacy = load(CHECKS / 'legacy-native-result.json')
    require(type(actual_legacy['status']) is int and actual_legacy['status'] == 1
        and actual_legacy['command'] == ['scripts/run_with_ram_guard.sh','--','python3','-B',str(CHECKS / 'native_guide.py'),'--legacy']
        and actual_legacy['stderr'].endswith('ValueError: native complete class/frame scope and retained gaps\n')
        and all(same(pin,identity(Path(p).read_bytes())) for p,pin in actual_legacy['instruments'].items()),
        'actual independently reproduced legacy native guide refusal')
    publication = ns['module'](CHECKS / 'verify_publication.py')
    paths = publication['subprocess'].check_output(['git','ls-tree','-r','--name-only',ns['REVISION'],'docs/book/src'], text=True).splitlines()
    books = {p:publication['original'](p) for p in paths if Path(p).parent == publication['chapter'].parent and p.endswith('.md')}
    registry = publication['original'](publication['registry']).decode().splitlines()
    prior_row = next(publication['json'].loads(s) for s in registry if publication['json'].loads(s).get('surface_id') == 'shipped_behavior')
    publication['check'](load(BASE / 'book-change.json'), books, prior_row)
    actual = load(CHECKS / 'publication-check.json')
    require(type(actual['status']) is int and actual['status'] == 0
        and actual['command'] == ['scripts/run_with_ram_guard.sh','--','python3','-B',str(CHECKS / 'verify_publication.py')]
        and actual['stdout'] == 'PASS complete independent class/frame-guide aggregate and controls; every physical fact and collection authority unchanged.\n'
        and all(same(pin,identity(Path(p).read_bytes())) for p,pin in actual['instruments'].items()),
        'whole actual independent finite guide and unchanged fact authority result')
    require(same(before, header(receipt)), 'every class/frame semantic seal byte conserves after independent consumption')


def main():
    receipt = load(CHECKS / 'sealed-replay.json'); check(receipt)
    controls = []
    def refuse(name, changed, cause):
        require(not same(changed, receipt), 'genuine actual class/frame result intervention: ' + name)
        try:
            header(changed)
        except ValueError as error:
            require(str(error) == cause, 'intended actual class/frame result refusal: ' + name)
            controls.append(dict(control=name, status=1, cause=cause))
        else:
            raise ValueError('false-green actual class/frame result: ' + name)
    for status in (True,0.0,1):
        refuse('status-' + repr(status), {**receipt,'status':status}, 'actual class/frame integer process success')
    for count in (True,0.0):
        changed = copy.deepcopy(receipt); next(iter(changed['whole_members'].values()))['bytes'] = count
        refuse('member-count-' + repr(count), changed, 'actual class/frame discrete sealed byte-count kinds')
    changed = copy.deepcopy(receipt); changed['whole_members'].pop(next(iter(changed['whole_members'])))
    refuse('lost-sealed-member', changed, 'every actual class/frame sealed member conserves')
    refuse('widened-guard', {**receipt,'stderr':receipt['stderr'].replace('cutoff 88%', 'cutoff 99%')}, 'actual class/frame default guard diagnostics')
    for name, borrowed in (
        ('borrowed-admission-success',load(Path('docs/audits/class-frame-admission-checks-20261006/sealed-replay.json'))),
        ('borrowed-preparation-success',load(CHECKS / 'qualified-preparation.json'))):
        require(type(borrowed['status']) is int and borrowed['status'] == 0, 'genuine narrower actual success: ' + name)
        refuse(name, borrowed, 'exact actual class/frame semantic command and complete output role')
    for control in controls:
        print(control['control'] + ': refused at ' + control['cause'])
    print('PASS independently consumed complete actual class/frame semantic join, regenerated every product and qualified typed/member/guard/real borrowed-result refusals.')


if __name__ == '__main__':
    main()
