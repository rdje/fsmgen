"""Consume the actual resource-safe seal; regenerate all current finite roles."""
import copy
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-public-boundary-join-20261006')
CHECKS = Path('docs/audits/public-boundary-join-checks-20261006')
ns = {'__name__': 'independent_actual_public_boundary_seal'}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
require, same, load, identity = (ns[k] for k in ('require', 'same', 'load', 'identity'))
COMMAND = ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / 'verify.py'),
           '--checkpoint-prerequisites', '--seal']
SUCCESS = ('Prerequisites: authenticated saved full executions at af4999e7; current source/header/control/guide checks rerun.\n'
           + ns['SUCCESS'])


def header(receipt):
    require(type(receipt['status']) is int and receipt['status'] == 0,
            'actual public boundary seal integer success')
    require(receipt['command'] == COMMAND and receipt['stdout'] == SUCCESS,
            'exact actual checkpoint public boundary seal command/result')
    require(re.fullmatch(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n',
                         receipt['stderr']) is not None, 'whole successful default-guard seal diagnostics')
    require(all(type(pin['bytes']) is int and pin['bytes'] >= 0
                for pin in receipt['whole_sealed_members'].values()),
            'actual public boundary discrete member byte-count kind')
    actual = {p.name: identity(p.read_bytes()) for p in BASE.iterdir()
              if p.is_file() and not p.is_symlink()}
    require(set(actual) == {p.name for p in BASE.iterdir()}, 'whole regular sealed boundary member population')
    require(same(receipt['whole_sealed_members'], actual), 'whole actual public boundary sealed byte population')
    require(same(load(BASE / 'manifest.json'), ns['members']()), 'whole immutable public boundary manifest')
    return actual


def check(receipt):
    before = header(receipt)
    ns['authenticate'](checkpoint_prerequisites=True)
    checkpoint = ns['module'](BASE / 'checkpoint.py')
    require(same(load(BASE / 'checkpoint-proof.json'), checkpoint['controls'](ns)),
            'regenerated checkpoint input and actual prerequisite receipt controls')
    expected = ns['models']()
    original = load(ns['context']['RAW'] / 'proofs.json')['inventories']
    nested = ns['context']['nested_records'](expected['own'])
    saved = load(BASE / 'proofs.json')
    require(same(saved['models'], expected), 'regenerated complete public boundary source model')
    require(same(saved['observations'], ns['check'](expected, expected, original, original, nested)),
            'regenerated complete original public header observations')
    require(same(saved['controls'], ns['controls'](expected, original, nested)),
            'regenerated all genuine public header separating controls')
    guide = ns['module'](BASE / 'book.py')
    require(same(load(BASE / 'book-proof.json'), guide['proof']((BASE / 'book-input.html').read_text())),
            'regenerated current native public boundary guide and controls')
    retained_names = {'book.py': 'checkpoint-book.py.txt', 'book-input.html': 'checkpoint-book-input.html',
                      'book-proof.json': 'checkpoint-book-proof.json', 'scope.txt': 'checkpoint-scope.txt.txt',
                      'publish_book.py': 'checkpoint-publish-book.py.txt'}
    for name, retained_name in retained_names.items():
        retained = BASE / retained_name
        committed = subprocess.check_output(['git', 'show', checkpoint['REVISION'] + ':' + str(BASE / name)])
        require(retained.read_bytes() == committed, 'whole retained committed checkpoint guide/scope/producer: ' + name)
    checkpoint_guide = ns['module'](BASE / 'checkpoint-book.py.txt')
    require(same(load(BASE / 'checkpoint-book-proof.json'), checkpoint_guide['proof']((BASE / 'checkpoint-book-input.html').read_text())),
            'regenerated whole qualified checkpoint native guide')
    initial = ns['module'](BASE / 'initial-book.py.txt')
    require(same(load(BASE / 'initial-book-proof.json'), initial['proof']((BASE / 'initial-book-input.html').read_text())),
            'regenerated actual first scoped guide success')
    try:
        guide['check']((BASE / 'initial-book-input.html').read_text())
    except ValueError as error:
        require(str(error) == 'native completed public join deferrals retired', 'real initial stale profile deferral refuses')
    else:
        raise ValueError('false-green initial stale chapter')
    require(same(before, header(receipt)), 'every sealed public boundary byte conserved after independent verification')


def main():
    receipt = load(CHECKS / 'sealed-replay.json')
    check(receipt)
    controls = []

    def refuse(name, candidate, cause):
        try:
            header(candidate)
        except ValueError as error:
            require(str(error) == cause, 'intended public boundary result refusal: ' + name)
            controls.append(dict(control=name, status=1, cause=str(error)))
        else:
            raise ValueError('false-green public boundary receipt: ' + name)

    for status in (True, 0.0, 1):
        refuse('status-' + repr(status), {**receipt, 'status': status}, 'actual public boundary seal integer success')
    for count in (True, 0.0):
        changed = copy.deepcopy(receipt)
        next(iter(changed['whole_sealed_members'].values()))['bytes'] = count
        refuse('member-count-' + repr(count), changed, 'actual public boundary discrete member byte-count kind')
    changed = copy.deepcopy(receipt); changed['whole_sealed_members'].pop(next(iter(changed['whole_sealed_members'])))
    refuse('lost-sealed-member', changed, 'whole actual public boundary sealed byte population')
    refuse('invented-guard-threshold', {**receipt, 'stderr': receipt['stderr'].replace('cutoff 88%', 'cutoff 99%')},
           'whole successful default-guard seal diagnostics')
    borrowed = load(ns['FIXTURE_CHECKS'] / 'sealed-replay.json')
    require(type(borrowed['status']) is int and borrowed['status'] == 0, 'genuine prior public-fixture-only seal success')
    refuse('borrowed-public-fixture-success', borrowed, 'exact actual checkpoint public boundary seal command/result')
    print('PASS actual checkpoint public boundary seal, complete independent source/header/control/guide regeneration and typed/member/borrowed-result refusals.')
    for row in controls:
        print(row['control'] + ': refused at ' + row['cause'])


if __name__ == '__main__':
    main()
