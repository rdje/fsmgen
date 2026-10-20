"""Qualify saved fixed-gap metadata while retaining its complete stopped proof."""
import argparse
import contextlib
import copy
import gzip
import json
import subprocess

import qualify_fixed_module_gap as gap
import saved_reader_sources as source

ROOT, AUDIT = gap.prepare.ROOT, gap.execute.AUDIT
PATH = AUDIT / 'fixed-gap-source-roles-qualified.json.gz'
SOURCES = (gap.SELF, 'saved_reader_sources.py', 'qualify_fixed_gap_roles.py')
MODES = ('saved', 'current', 'assertions-disabled')
LINE = ('Stopped fixed-module candidate diagnostic reconstructs exactly; '
        'source closure and default effects remain unqualified.\n')
SCOPE = ('Saved fixed-gap programme metadata only. Native original sources and the entire '
         'immutable stopped graph/control/scope proof retain. Actual saved CLI passes; '
         'explicit current metadata and disabled assertions refuse. Historical, changed '
         'and denied images are metadata controls, never historical module execution. '
         'Write mode still selects current metadata and exclusive publication. Source '
         'closure, default reachability, effects, custody, original semantic/cohort, '
         'native/private/HIAL and full-CI acceptance remain separately gated.')


def equal(left, right):
    return gap.bounded.strict_equal(left, right)


def unblob(row):
    raw = gap.prepare.unblob(row)
    equal(row, gap.prepare.blob(raw))
    return raw


def current_sources():
    return {name: gap.prepare.blob((ROOT / AUDIT / name).read_bytes()) for name in SOURCES}


def reference():
    original = {name: source.original(name) for name in gap.PREMISES}
    raw = gap.execute.read(gap.PATH)
    equal(raw, gap.epoch.read(source.REVISION, str(gap.PATH)))
    proof = json.loads(gzip.decompress(raw))
    metadata = {name: row['body'] for name, row in original.items()}
    equal(proof['programmes'], metadata)
    equal(gap.source_metadata(), metadata)
    return dict(original=original, metadata=metadata,
                proof=dict(revision=source.REVISION, path=str(gap.PATH),
                           identity=gap.prepare.identity(raw),
                           retention_contract='fsmgen_required_history'))


@contextlib.contextmanager
def supplied_images(images, denied=False):
    read = gap.execute.read
    paths = {str(AUDIT / name): name for name in images}
    attempted = []

    def supplied(path):
        name = paths.get(str(path))
        if name is None:
            return read(path)
        attempted.append(name)
        if denied:
            raise AssertionError('deliberately denied current metadata')
        return images[name]

    try:
        gap.execute.read = supplied
        yield attempted
    finally:
        gap.execute.read = read


def outcome(action):
    try:
        action()
    except AssertionError as error:
        return dict(accepted=False, error=str(error))
    return dict(accepted=True, error=None)


def controls(fixed):
    images = {name: unblob(row['body']) for name, row in fixed['original'].items()}
    changed = dict(images, **{'prepare.py': b'x' + images['prepare.py'][1:]})
    rows = []
    for label, supplied, denied in (('historical-image', images, False),
                                    ('changed-image', changed, False),
                                    ('denied-image', images, True)):
        for current in (False, True):
            with supplied_images(supplied, denied) as attempted:
                result = outcome(lambda: equal(gap.source_metadata(current=current), fixed['metadata']))
            assert result['accepted'] is (not current or label == 'historical-image')
            assert bool(attempted) is current
            rows.append(dict(label=label, current=current, reads=attempted, result=result))
    for label in ('float-bytes', 'boolean-bytes', 'missing-member', 'rehashed-body', 'borrowed-reader'):
        candidate = copy.deepcopy(fixed['metadata'])
        if label == 'float-bytes':
            candidate['prepare.py']['bytes'] = float(candidate['prepare.py']['bytes'])
        elif label == 'boolean-bytes':
            candidate['prepare.py']['bytes'] = True
        elif label == 'missing-member':
            del candidate['prepare.py']
        elif label == 'rehashed-body':
            candidate['prepare.py'] = gap.prepare.blob(changed['prepare.py'])
        else:
            candidate[gap.SELF] = candidate['prepare.py']
        result = outcome(lambda: equal(candidate, gap.source_metadata()))
        assert not result['accepted']
        rows.append(dict(label=label, candidate=candidate, result=result))
    for name in ('../prepare.py', 'inventory.json.gz', 'missing-source-control.py'):
        result = outcome(lambda: source.original(name))
        assert not result['accepted']
        rows.append(dict(label='closed-native-member', name=name, result=result))
    command = source.execute.command
    try:
        def changed_show(argv):
            raw = command(argv)
            return b'x' + raw[1:] if argv[2] == 'show' else raw
        source.execute.command = changed_show
        result = outcome(lambda: source.original('prepare.py'))
        assert not result['accepted']
        rows.append(dict(label='changed-native-show', result=result))
    finally:
        source.execute.command = command
    return rows


def command(mode):
    assert mode in MODES
    argv = ['python3', '-B']
    if mode == 'assertions-disabled':
        argv.append('-O')
    argv.append(str(AUDIT / gap.SELF))
    if mode == 'current':
        argv.append('--current')
    return argv


def collect():
    fixed = reference()
    actual = []
    for mode in MODES:
        argv = command(mode)
        result = subprocess.run(argv, cwd=ROOT, stdin=subprocess.DEVNULL, capture_output=True)
        actual.append(dict(command=argv, status=result.returncode,
                           stdout=gap.prepare.blob(result.stdout), stderr=gap.prepare.blob(result.stderr)))
    equal(reference(), fixed)
    return dict(schema='fsmgen.fixed_gap_source_roles.v1', scope=SCOPE,
                sources=current_sources(), reference=fixed,
                controls=controls(fixed), actual=actual)


def review(value):
    assert set(value) == {'schema', 'scope', 'sources', 'reference', 'controls', 'actual'}
    equal(value['schema'], 'fsmgen.fixed_gap_source_roles.v1')
    equal(value['scope'], SCOPE)
    equal(value['sources'], current_sources())
    fixed = reference()
    equal(value['reference'], fixed)
    equal(value['controls'], controls(fixed))
    assert type(value['actual']) is list and len(value['actual']) == 3
    for row, mode in zip(value['actual'], MODES):
        assert set(row) == {'command', 'status', 'stdout', 'stderr'}
        equal(row['command'], command(mode))
        equal(row['status'], 0 if mode == 'saved' else 1)
        equal(unblob(row['stdout']), LINE.encode() if mode == 'saved' else b'')
        stderr = unblob(row['stderr'])
        if mode == 'current':
            assert stderr.endswith(b'AssertionError: exact scalar\n') and b'ram-guard:' not in stderr
        elif mode == 'assertions-disabled':
            equal(stderr, b'Acceptance assertions must be enabled.\n')
        else:
            equal(stderr, b'')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    value = collect() if args.write else json.loads(gzip.decompress((ROOT / PATH).read_bytes()))
    review(value)
    if args.write:
        with (ROOT / PATH).open('xb') as target:
            with gzip.GzipFile(filename='', mode='wb', fileobj=target, mtime=0) as stream:
                for chunk in json.JSONEncoder(sort_keys=True, separators=(',', ':')).iterencode(value):
                    stream.write(chunk.encode())
    print('Native saved fixed-gap metadata and complete original proof qualify; current metadata and disabled assertions refuse.')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    main()
