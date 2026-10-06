"""Independently consume complete actual publication-admission semantics."""
import copy
import json
import re
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-publication-admission-20261006')
CHECKS = Path('docs/audits/class-frame-publication-admission-checks-20261006')
ns = {'__name__': 'independent_publication_admission', '__file__': str(BASE / 'verify.py')}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
require, same, identity, load = (ns[k] for k in ('require', 'same', 'identity', 'load'))
COMMAND = ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / 'verify.py'), '--seal']
GUARD = r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n'


def process(actual, command, stdout):
    require(type(actual['status']) is int and actual['status'] == 0, 'actual publication-admission integer process success')
    require(actual['command'] == command and actual['stdout'] == stdout,
            'exact actual publication-admission command and complete output role')
    require(re.fullmatch(GUARD, actual['stderr']) is not None, 'actual publication-admission default guard diagnostics')
    expected = {str(CHECKS / 'run.py'), command[4], 'scripts/run_with_ram_guard.sh'}
    require(set(actual['instruments']) == expected and all(same(pin, identity(Path(p).read_bytes())) for p,pin in actual['instruments'].items()),
            'whole actual publication-admission invocation programmes')


def header(receipt):
    process(receipt, COMMAND, ns['SUCCESS'])
    require(all(type(pin['bytes']) is int and pin['bytes'] >= 0 for pin in receipt['whole_members'].values()),
            'actual publication-admission discrete sealed byte-count kinds')
    whole = {str(Path(p).relative_to(BASE)):pin for p,pin in ns['whole'](BASE).items()}
    require(same(receipt['whole_members'], whole), 'every actual publication-admission sealed member conserves')
    original = load(CHECKS / 'seal-command.json')
    require(same({k:receipt[k] for k in original}, original)
        and same(receipt['actual_result_identity'], identity((CHECKS / 'seal-command.json').read_bytes())),
        'whole untouched actual publication-admission result identity')
    require(set(receipt) == set(original) | {'whole_members','actual_result_identity'}, 'closed whole actual publication-admission result')
    require(same(load(BASE / 'manifest.json'), ns['members']()), 'whole immutable publication-admission seal')
    return whole


def check(receipt):
    before = header(receipt)
    bound = ns['binding'](); snapshot = ns['source_snapshot']()
    ns['check_binding'](load(BASE / 'binding.json'), bound)
    ns['check_snapshot'](load(BASE / 'source-snapshot.json'), snapshot)
    require(same(ns['semantic_products'](), load(BASE / 'semantic-proof.json')),
            'whole independently reconstructed complete source class/frame raw phase operand and separating-control meanings')
    require(same(ns['replays'](bound,snapshot,False), load(BASE / 'replay-proof.json')),
            'whole independently consumed scoped actual prerequisite executions')
    require(same(ns['controls'](bound,snapshot), load(BASE / 'controls.json')),
            'whole independently reconstructed genuine custody fact question owner scope kind and borrowed-result controls')
    book = ns['module'](BASE / 'book.py')
    require(same(book['proof']((BASE / 'book-input.html').read_text()), load(BASE / 'book-proof.json')),
            'whole independently reconstructed native admission guide and scope controls')
    preparation = load(CHECKS / 'preparation.json')
    process(preparation, COMMAND[:-1] + ['--prepare'],
            'PASS whole committed publication prerequisite preparation and complete semantic regeneration; fresh actual reader executions remain required.\n')
    fresh = load(CHECKS / 'fresh-replay.json')
    stdout = ''.join('Admitted fresh publication prerequisite: ' + spec['name'] + '\n' for spec in ns['replay_specs']()) + ns['FRESH_SUCCESS']
    process(fresh, COMMAND[:-1] + ['--replay'], stdout)
    publication = ns['module'](CHECKS / 'verify_publication.py')
    paths = publication['subprocess'].check_output(['git','ls-tree','-r','--name-only',ns['REVISION'],'docs/book/src'], text=True).splitlines()
    books = {p:publication['original'](p) for p in paths if Path(p).parent == publication['chapter'].parent and p.endswith('.md')}
    rows = publication['original'](publication['registry']).decode().splitlines()
    prior = next(json.loads(s) for s in rows if json.loads(s).get('surface_id') == 'shipped_behavior')
    publication['check'](load(BASE / 'book-change.json'), books, prior)
    actual = load(CHECKS / 'publication-check.json')
    process(actual, ['scripts/run_with_ram_guard.sh','--','python3','-B',str(CHECKS / 'verify_publication.py')],
            'PASS complete independent class/frame-guide aggregate and controls; every physical fact and collection authority unchanged.\n')
    native = load(CHECKS / 'native-phases.json')
    destination = '.artifacts/class-frame-publication-admission-book'
    commands = [
        ['python3','-B','scripts/book_source_references.py','--write'],
        ['mdbook','build','docs/book','-d',destination],
        ['python3','-B','scripts/book_source_references.py','--check','--verify-build',destination],
        ['python3','-B','scripts/check_book_source_index.py'],
        ['python3','-B',str(CHECKS / 'native_guide.py')]]
    require(set(native) == {'destination','phases','role'} and native['destination'] == destination
        and native['role'] == 'Actual repository-local native build, source selection/current/copied-byte/index checks and complete rendered admission guide controls; visual QA remains pending.',
        'whole actual native phase scope and destination')
    require([r['command'] for r in native['phases']] == commands, 'whole ordered actual source native and guide phase population')
    for phase in native['phases']:
        require(type(phase['status']) is int and phase['status'] == 0 and set(phase) == {'command','status','stdout','stderr','instruments'},
                'closed actual native phase integer success')
        paths = {item for item in phase['command'] if item.endswith('.py')}
        require(set(phase['instruments']) == paths and all(same(pin,identity(Path(p).read_bytes())) for p,pin in phase['instruments'].items()),
                'whole actual native phase invocation programmes')
    source_message = 'book-source-references: complete source/role/member/relative-endpoint/current-byte/ignore contracts hold\n'
    require(native['phases'][0]['stdout'] == source_message and native['phases'][2]['stdout'] == source_message
        and native['phases'][3]['stdout'] == 'book-source-index: complete indexed directory and checked source projection agree\n'
        and native['phases'][4]['stdout'] == 'PASS native publication-admission guide and genuine scope controls; complete rendered input retained.\n',
        'complete actual source native index and guide output roles')
    complete = ''.join(r['stdout'] + r['stderr'] for r in native['phases']) + 'PASS actual complete local source/native admission publication phases.\n'
    process(load(CHECKS / 'native-result.json'), ['scripts/run_with_ram_guard.sh','--','python3','-B',str(CHECKS / 'build_native.py')], complete)
    require(same(before, header(receipt)), 'every publication-admission seal byte conserves after independent consumption')


def main():
    receipt = load(CHECKS / 'sealed-replay.json'); check(receipt)
    controls = []
    def refuse(name, changed, cause):
        require(not same(changed, receipt), 'genuine actual publication-admission intervention: ' + name)
        try:
            header(changed)
        except ValueError as error:
            require(str(error) == cause, 'intended actual publication-admission refusal: ' + name)
            controls.append(dict(control=name, status=1, cause=cause))
        else:
            raise ValueError('false-green actual publication-admission result: ' + name)
    for status in (True,0.0,1):
        refuse('status-' + repr(status), {**receipt,'status':status}, 'actual publication-admission integer process success')
    for count in (True,0.0):
        changed = copy.deepcopy(receipt); next(iter(changed['whole_members'].values()))['bytes'] = count
        refuse('member-count-' + repr(count), changed, 'actual publication-admission discrete sealed byte-count kinds')
    changed = copy.deepcopy(receipt); changed['whole_members'].pop(next(iter(changed['whole_members'])))
    refuse('lost-sealed-member', changed, 'every actual publication-admission sealed member conserves')
    refuse('widened-guard', {**receipt,'stderr':receipt['stderr'].replace('cutoff 88%', 'cutoff 99%')}, 'actual publication-admission default guard diagnostics')
    for name, borrowed in (
        ('borrowed-join-success',load(ns['JOIN_CHECKS'] / 'sealed-replay.json')),
        ('borrowed-preparation-success',load(CHECKS / 'preparation.json')),
        ('borrowed-current-tooling-success',load(BASE / 'replay-tooling_current.json'))):
        require(type(borrowed['status']) is int and borrowed['status'] == 0, 'genuine narrower actual success: ' + name)
        refuse(name, borrowed, 'exact actual publication-admission command and complete output role')
    for control in controls:
        print(control['control'] + ': refused at ' + control['cause'])
    print('PASS independently consumed complete actual publication admission, regenerated full semantic and source products and qualified typed/member/guard/real borrowed-result refusals.')


if __name__ == '__main__':
    main()
