"""Qualify complete raw/source admission and actual-result separating controls."""
import copy
import json
import re
import runpy
from pathlib import Path

BASE = Path('docs/audits/address-raw-admission-20261010')
SUCCESS = 'PASS complete independent original/raw/source prerequisite admission; operand parsing and numeric role/lifetime meanings remain open.\n'


def main():
    oracle = runpy.run_path(str(BASE / 'oracle.py'))
    need, pin, same = (oracle[k] for k in ('need', 'pin', 'same'))
    original = json.loads((BASE / 'admission.json').read_bytes())
    custody, allocation, owners = (oracle[k]() for k in ('custody', 'allocation', 'owners'))
    qualify = lambda candidate: oracle['qualify'](candidate, custody, allocation, owners)
    measured = qualify(original)
    controls = []

    def reject(name, mutate, cause):
        candidate = copy.deepcopy(original)
        mutate(candidate)
        need(not same(candidate, original), 'genuine whole admission control: ' + name)
        try:
            qualify(candidate)
        except ValueError as error:
            need(str(error) == cause, 'intended admission refusal: ' + name + ': ' + str(error))
            controls.append({'name': name, 'refusal': cause,
                             'whole_candidate': pin(json.dumps(candidate, sort_keys=True).encode())})
        else:
            raise ValueError('false-green complete admission: ' + name)

    reject('unknown-native-identity', lambda p: p.update(original_native_identity='proved'), 'closed complete admission product')
    reject('numeric-reuse-scope', lambda p: p.update(role='Equal hex proves native identity across captures'),
           'exact admission owner and successor scope')
    reject('borrowed-owner', lambda p: p.update(owner='foreign'), 'exact admission owner and successor scope')
    reject('lost-whole-input-root', lambda p: p['custody']['roots'].pop(), 'whole independent admission custody')
    first_member = next(iter(original['custody']['members']))
    other_member = next(p for p in original['custody']['members']
                        if original['custody']['members'][p] != original['custody']['members'][first_member])
    reject('lost-whole-input-member', lambda p: p['custody']['members'].pop(first_member), 'whole independent admission custody')
    reject('borrowed-whole-input-member', lambda p: p['custody']['members'].__setitem__(first_member,
        copy.deepcopy(p['custody']['members'][other_member])), 'whole independent admission custody')
    reject('borrowed-input-revision', lambda p: p['custody'].update(revision='HEAD'), 'whole independent admission custody')
    reject('Boolean-archive-status', lambda p: p['custody']['transport'].update(status=False), 'whole independent admission custody')
    reject('lost-empty-member', lambda p: p['allocation']['modes'][0]['domains']['copies']['empty'].pop(),
           'whole independent original/source allocation')
    reject('lost-nonempty-member', lambda p: p['allocation']['modes'][0]['domains']['api']['nonempty'].pop(),
           'whole independent original/source allocation')
    reject('Boolean-original-population', lambda p: p['allocation']['modes'][0]['domains']['test_run'].update(population=True),
           'whole independent original/source allocation')
    reject('borrowed-raw-body', lambda p: p['allocation']['modes'][0]['domains']['api']['nonempty'][0].update(
        body=copy.deepcopy(p['allocation']['modes'][1]['domains']['api']['nonempty'][0]['body'])),
        'whole independent original/source allocation')
    reject('lost-source-view', lambda p: p['allocation']['source_views'].pop(), 'whole independent original/source allocation')
    reject('borrowed-source-phase', lambda p: p['allocation']['source_views'][0].__setitem__(3, 1),
           'whole independent original/source allocation')
    reject('lost-qualified-product', lambda p: p['allocation']['products'].pop(next(iter(p['allocation']['products']))),
           'whole independent original/source allocation')
    reject('lost-completed-owner', lambda p: p['prerequisite_owners']['completed'].pop(next(iter(p['prerequisite_owners']['completed']))),
           'whole independent completed prerequisite owners')
    reject('lost-reader', lambda p: p['actual_readers'].pop('coordinate'), 'complete actual admission reader population')
    reject('Boolean-reader-status', lambda p: p['actual_readers']['source'].update(status=True), 'actual admission integer success')
    reject('nonzero-reader-status', lambda p: p['actual_readers']['source'].update(status=1), 'actual admission integer success')
    reject('borrowed-success', lambda p: p['actual_readers'].__setitem__('source', copy.deepcopy(p['actual_readers']['class-frame'])),
           'complete actual admission reader command')
    reject('short-reader-output', lambda p: p['actual_readers']['source'].update(stdout='PASS\n'),
           'complete actual admission reader stdout')
    reject('lost-actual-instrument', lambda p: p['actual_readers']['source']['instruments'].pop('scripts/run_with_ram_guard.sh'),
           'complete actual invocation instruments')
    reject('widened-host-cutoff', lambda p: p['actual_readers']['source'].update(
        stderr=p['actual_readers']['source']['stderr'].replace('cutoff 88%', 'cutoff 99%')),
        'complete actual admission guard stream')
    reject('unknown-reader-native-field', lambda p: p['actual_readers']['source'].update(native_identity=True),
           'closed actual admission result')
    actual = json.loads((BASE / 'checks.json').read_bytes())['admission']
    instruments = {str(BASE / 'checks.py'), str(BASE / 'admit.py'), 'scripts/run_with_ram_guard.sh'}
    need(set(actual) == {'command', 'status', 'stdout', 'stderr', 'instruments'}
         and type(actual['status']) is int and actual['status'] == 0
         and actual['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / 'admit.py')]
         and actual['stdout'] == ('PASS complete dated raw/source custody admission produced; independent qualification '
                                  'and operand/address meanings remain required.\n')
         and actual['instruments'] == {p: pin(Path(p).read_bytes()) for p in instruments}
         and re.fullmatch(r'ram-guard: PID [0-9]+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n',
                          actual['stderr']) is not None,
         'actual complete first admission producer')
    proof = {'role': original['role'], 'admission': pin((BASE / 'admission.json').read_bytes()),
        'measured': measured, 'controls': controls,
        'programmes': {name: pin((BASE / name).read_bytes()) for name in ('admit.py', 'oracle.py', 'verify.py', 'checks.py')},
        'legs': {'re_derivation': 'admit.py streams the complete fixed Git archive and conserves whole raw/source products and phases.',
                 'falsification': 'oracle.py separately streams exact Git blobs, reconstructs allocation from original captures and qualifies whole actual results; genuine complete-product controls reject.',
                 'durability': 'Complete fixed committed input/member and task-owner identities, original captures, actual fresh prerequisite outcomes and invocation programmes retain; normal task-scoped commit.'},
        'missing_legs': 'Original numeric reference-role/lifetime joins and lossless operand grammar remain successors; private/native flags/payload/provider/formatter/CODE/Regexp identity, cross-call identity, global heap census, cold replay and governed current publication remain unqualified.'}
    path = BASE / 'proof.json'
    if path.exists():
        need(same(json.loads(path.read_bytes()), proof), 'whole immutable admission qualification')
    else:
        path.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
