"""Consume the actual admission seal and fresh execution without role borrowing."""
import copy
import re
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-admission-20261006')
CHECKS = Path('docs/audits/class-frame-admission-checks-20261006')
ns = {'__name__': 'independent_class_frame_admission', '__file__': str(BASE / 'verify.py')}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
require, same, identity, load = (ns[k] for k in ('require', 'same', 'identity', 'load'))
COMMAND = ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / 'verify.py'), '--seal']


def process_header(record, command, stdout, source=None):
    require(type(record['status']) is int and record['status'] == 0, 'actual admission integer process success')
    require(record['command'] == command and record['stdout'] == stdout, 'exact actual admission command and complete output role')
    require(re.fullmatch(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', record['stderr']) is not None,
            'actual admission default guard diagnostics')
    require(set(record['instruments']) == {str(CHECKS / 'run.py'), str(BASE / 'verify.py'), 'scripts/run_with_ram_guard.sh'}
            and all(same(pin, identity((source if source and p == str(BASE / 'verify.py') else Path(p)).read_bytes()))
                    for p, pin in record['instruments'].items()),
            'whole invocation-time actual admission instruments')


def header(receipt):
    process_header(receipt, COMMAND, ns['SUCCESS'])
    require(all(type(pin['bytes']) is int and pin['bytes'] >= 0 for pin in receipt['whole_members'].values()),
            'actual admission discrete member byte-count kinds')
    actual = {str(Path(p).relative_to(BASE)): pin for p, pin in ns['whole'](BASE).items()}
    require(same(receipt['whole_members'], actual), 'complete actual admission sealed member conservation')
    original = load(CHECKS / 'seal-command.json')
    require(same({k: receipt[k] for k in original}, original) and same(receipt['actual_result_identity'], identity((CHECKS / 'seal-command.json').read_bytes())),
            'whole original actual admission result identity')
    require(same(load(BASE / 'manifest.json'), ns['members']()), 'whole immutable admission manifest')
    return actual


def check(receipt):
    before = header(receipt)
    binding = load(BASE / 'binding.json')
    ns['check_binding'](binding, ns['derive_binding']())
    require(same(ns['raw_product'](), load(BASE / 'raw-product.json')), 'complete independently regenerated original raw product and controls')
    require(same(ns['replays'](binding, False), load(BASE / 'replay-proof.json')), 'complete actual scoped reader result population')
    require(same(ns['controls'](binding), load(BASE / 'controls.json')), 'complete independently regenerated admission source/result controls')
    book = ns['module'](BASE / 'book.py')
    require(same(book['proof']((BASE / 'book-input.html').read_text()), load(BASE / 'book-proof.json')), 'complete regenerated native admission guide and controls')
    fresh = load(CHECKS / 'fresh-replay.json')
    output = ''.join('Admitted actual prerequisite: ' + spec['name'] + '\n' for spec in ns['replay_specs']()) + ns['REPLAY_SUCCESS']
    old_source = CHECKS / 'fresh-reader.py.txt'
    process_header(fresh, COMMAND[:-1] + ['--replay'], output, old_source)
    import ast
    def execution_source(path):
        tree = ast.parse(path.read_bytes())
        tree.body = [node for node in tree.body if not (isinstance(node, ast.FunctionDef) and node.name == 'members')]
        return ast.dump(tree, include_attributes=False)
    require(execution_source(old_source) == execution_source(BASE / 'verify.py'),
            'whole fresh invocation source conserves all execution semantics; only unused unsealed manifest addressing changes')
    initial = ns['module'](CHECKS / 'first-flat-reader.py.txt')
    failure = load(CHECKS / 'qualified-preparation.json')
    require(type(failure['status']) is int and failure['status'] == 1
        and 'ValueError: complete regular same-volume admission input population' in failure['stderr']
        and same(failure['instruments'][str(BASE / 'verify.py')], identity((CHECKS / 'first-flat-reader.py.txt').read_bytes())),
        'whole actual first flat-population refusal and invocation programme')
    try:
        initial['whole'](Path('docs/audits/record-value-core-join-checks-20261004'))
    except ValueError as error:
        require(str(error) == 'complete regular same-volume admission input population', 'independently reproduced nested retained-member root cause')
    else:
        raise ValueError('false-green initial flat member census')
    publication = ns['module'](CHECKS / 'verify_publication.py')
    paths = publication['subprocess'].check_output(['git', 'ls-tree', '-r', '--name-only', ns['REVISION'], 'docs/book/src'], text=True).splitlines()
    books = {p:publication['original'](p) for p in paths if Path(p).parent == publication['chapter'].parent and p.endswith('.md')}
    registry = publication['original'](publication['registry']).decode().splitlines()
    row = next(publication['json'].loads(s) for s in registry if publication['json'].loads(s).get('surface_id') == 'shipped_behavior')
    publication['check'](load(BASE / 'book-change.json'), books, row)
    actual = load(CHECKS / 'publication-check.json')
    command = ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(CHECKS / 'verify_publication.py')]
    require(type(actual['status']) is int and actual['status'] == 0 and actual['command'] == command
        and actual['stdout'] == 'PASS complete independent admission-guide aggregate and controls; every physical fact and collection authority unchanged.\n'
        and all(same(pin, identity(Path(p).read_bytes())) for p, pin in actual['instruments'].items()),
        'whole actual independent guide publication result and invocation source')
    member_control = ns['module'](CHECKS / 'qualify_member_paths.py')
    member_control['main']()
    actual = load(CHECKS / 'member-path-result.json')
    require(type(actual['status']) is int and actual['status'] == 0
        and actual['command'] == ['python3', '-B', str(CHECKS / 'qualify_member_paths.py')]
        and actual['stdout'] == 'PASS actual nested same-basename insertion separates old false-green and repaired full-path seal; flat manifest bytes retain.\n'
        and actual['stderr'] == '' and all(same(pin, identity(Path(p).read_bytes())) for p, pin in actual['instruments'].items()),
        'whole actual nested-member separating result and invocation programme')
    require(same(before, header(receipt)), 'every admission seal byte conserved after independent consumption')


def main():
    receipt = load(CHECKS / 'sealed-replay.json'); check(receipt)
    controls = []
    def refuse(name, candidate, cause):
        require(not same(candidate, receipt), 'genuine actual admission result intervention: ' + name)
        try:
            header(candidate)
        except ValueError as error:
            require(str(error) == cause, 'intended actual admission refusal: ' + name)
            controls.append(dict(control=name, status=1, cause=cause))
        else:
            raise ValueError('false-green actual admission result: ' + name)
    for status in (True, 0.0, 1):
        refuse('status-' + repr(status), {**receipt, 'status': status}, 'actual admission integer process success')
    for count in (True, 0.0):
        changed = copy.deepcopy(receipt); next(iter(changed['whole_members'].values()))['bytes'] = count
        refuse('member-count-' + repr(count), changed, 'actual admission discrete member byte-count kinds')
    changed = copy.deepcopy(receipt); changed['whole_members'].pop(next(iter(changed['whole_members'])))
    refuse('lost-sealed-member', changed, 'complete actual admission sealed member conservation')
    refuse('widened-guard', {**receipt, 'stderr': receipt['stderr'].replace('cutoff 88%', 'cutoff 99%')}, 'actual admission default guard diagnostics')
    for name, borrowed in (
        ('borrowed-public-success', load(Path('docs/audits/public-boundary-join-checks-20261006/sealed-replay.json'))),
        ('borrowed-preparation-success', load(CHECKS / 'complete-preparation.json'))):
        require(type(borrowed['status']) is int and borrowed['status'] == 0, 'genuine narrower successful actual process: ' + name)
        refuse(name, borrowed, 'exact actual admission command and complete output role')
    for row in controls:
        print(row['control'] + ': refused at ' + row['cause'])
    print('PASS independently consumed whole actual admission and fresh scoped executions, regenerated products and typed/member/borrowed-result refusals.')


if __name__ == '__main__':
    main()
