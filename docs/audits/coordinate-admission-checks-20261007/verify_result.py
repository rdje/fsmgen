"""Independently consume the complete sealed admission and actual outer results."""
import copy
import json
import re
from pathlib import Path

BASE = Path('docs/audits/coordinate-admission-checks-20261007')
AUDIT = Path('docs/audits/record-value-coordinate-admission-20261007')
namespace = {'__name__': 'independent_coordinate_result', '__file__': str(AUDIT / 'verify.py')}
exec(compile((AUDIT / 'verify.py').read_bytes(), str(AUDIT / 'verify.py'), 'exec'), namespace)
require, same, load = (namespace[k] for k in ('require', 'same', 'load'))
GUARD = r'ram-guard: PID [0-9]+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n'


def process(actual, flags, stdout):
    command = ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(AUDIT / 'verify.py'), *flags]
    require(type(actual) is dict and set(actual) == {'command', 'status', 'stdout', 'stderr'},
            'closed actual coordinate outer execution')
    require(type(actual['status']) is int and actual['status'] == 0, 'actual coordinate outer integer success')
    require(actual['command'] == command and actual['stdout'] == stdout
        and re.fullmatch(GUARD, actual['stderr']) is not None,
        'whole actual coordinate outer command streams and unchanged guard')


def main():
    manifest = load(AUDIT / 'manifest.json')
    require(same(manifest, namespace['members']()), 'whole coordinate admission sealed member corpus')
    bound, source = namespace['binding'](), namespace['snapshot']()
    namespace['check_binding'](load(AUDIT / 'binding.json'), bound)
    namespace['check_snapshot'](load(AUDIT / 'source-snapshot.json'), source)
    require(same(load(AUDIT / 'result-proof.json'), namespace['replays'](bound, source, False)),
            'whole independent saved coordinate actual child proof')
    require(same(load(AUDIT / 'controls.json'), namespace['controls'](bound, source)),
            'whole independent regenerated coordinate custody/source/result controls')
    epoch = namespace['module'](AUDIT / 'verify_epoch.py')
    epoch['main']()
    native = namespace['module'](BASE / 'qualify_native.py')
    require(same(native['construct']((BASE / 'qualified-native-input.html').read_text()),
        load(BASE / 'qualified-native-proof.json')), 'whole independently regenerated qualified native admission scope and input')
    fresh = ''.join('Retained actual coordinate prerequisite: ' + spec['name'] + '\n'
        for spec in namespace['specs']()) + namespace['FRESH']
    process(load(BASE / 'fresh-replays.json'), ['--replay'], fresh)
    process(load(BASE / 'seal.json'), ['--seal'], namespace['SUCCESS'])
    original = load(BASE / 'saved-reader.json')
    process(original, [], namespace['SUCCESS'])
    controls = []
    def refuse(name, candidate, predicate, cause):
        try:
            predicate(candidate)
        except ValueError as error:
            require(str(error) == cause, 'intended independent coordinate result refusal: ' + name)
            controls.append(dict(control=name, cause=cause))
        else:
            raise ValueError('false-green independent coordinate result: ' + name)
    for status in (True, 0.0, 1):
        changed = copy.deepcopy(original); changed['status'] = status
        refuse('outer-status-' + repr(status), changed, lambda r:process(r, [], namespace['SUCCESS']),
               'actual coordinate outer integer success')
    changed = copy.deepcopy(original); changed['stdout'] = load(AUDIT / 'actual-current.json')['stdout']
    require(changed != original, 'genuine successful current-only stream intervention')
    refuse('borrowed-current-success', changed, lambda r:process(r, [], namespace['SUCCESS']),
           'whole actual coordinate outer command streams and unchanged guard')
    changed = copy.deepcopy(manifest); changed.pop('source-snapshot.json')
    refuse('lost-complete-source-snapshot', changed,
        lambda r:require(same(r, namespace['members']()), 'whole coordinate admission sealed member corpus'),
        'whole coordinate admission sealed member corpus')
    changed = copy.deepcopy(manifest); changed['verify.py']['sha256'] = '0' * 64
    refuse('changed-whole-admission-programme', changed,
        lambda r:require(same(r, namespace['members']()), 'whole coordinate admission sealed member corpus'),
        'whole coordinate admission sealed member corpus')
    print(json.dumps(dict(role=namespace['ROLE'], roots=len(bound['inputs']),
        members=sum(len(rows) for rows in bound['inputs'].values()), done_owners=len(bound['owners']),
        actual_readers=len(namespace['specs']()), controls=controls), sort_keys=True))


if __name__ == '__main__':
    main()
