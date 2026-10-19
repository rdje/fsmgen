"""Qualify original dispatch metadata without changing its fixed graph proof."""
import argparse
import contextlib
import copy
import gzip
import json
from pathlib import Path
import subprocess

import default_dispatch as dispatch
import saved_reader_sources as source

ROOT, AUDIT = dispatch.prepare.ROOT, dispatch.execute.AUDIT
PATH = AUDIT / 'default-dispatch-source-roles-qualified.json.gz'
SOURCES = ('default_dispatch.py', 'saved_reader_sources.py', 'qualify_default_dispatch_roles.py')
LINE = ('Fixed default dispatch and direct dynamic-source edges pass; transitive effects and '
        'runtime custody remain unqualified.\n')
SCOPE = ('Saved dispatch source metadata only. Complete original programme/premise bytes and original '
         'proof/inventory data bind to native Git. Actual saved CLI passes the original full graph/'
         'control/scope proof; explicit current CLI retains strict metadata refusal. Historical, '
         'changed and denied metadata images are predicate controls, never historical module execution. '
         'Original write mode still selects current metadata and exclusive publication. No original '
         'producer/model/recipe/cohort or spent intake runs, and no transitive effects, operational '
         'custody, native/private/HIAL or full-CI acceptance follows.')


def equal(left, right):
    return dispatch.bounded.strict_equal(left, right)


def unblob(row):
    raw = dispatch.prepare.unblob(row)
    equal(row, dispatch.prepare.blob(raw))
    return raw


def current_sources():
    return {name: dispatch.prepare.blob((ROOT / AUDIT / name).read_bytes()) for name in SOURCES}


def reference():
    native = {}
    for name in (dispatch.SELF, *dispatch.PREMISES):
        row = source.original(name)
        assert row['revision'] == source.REVISION and row['path'] == str(AUDIT / name)
        native[name] = row
    data = {}
    for path in (dispatch.PATH, AUDIT / 'runtime-source-inventory-bounded.json.gz'):
        raw = dispatch.epoch.read(source.REVISION, str(path))
        assert raw == dispatch.execute.read(path), 'complete original static evidence unchanged'
        data[str(path)] = dict(revision=source.REVISION, identity=dispatch.prepare.identity(raw),
                              retention_contract='fsmgen_required_history')
    saved = json.loads(gzip.decompress(dispatch.execute.read(dispatch.PATH)))
    metadata = dict(programme=saved['programme'], premises=saved['premises'])
    equal(metadata, dispatch.source_metadata())
    equal(metadata['programme'], native[dispatch.SELF]['body'])
    equal(metadata['premises'], {name: native[name]['body'] for name in dispatch.PREMISES})
    return dict(original=native, data=data, metadata=metadata)


@contextlib.contextmanager
def supplied_images(images, denied=False):
    read = dispatch.execute.read
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
        dispatch.execute.read = supplied
        yield attempted
    finally:
        dispatch.execute.read = read


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
                                    ('changed-image', changed, False), ('denied-image', images, True)):
        for current in (False, True):
            with supplied_images(supplied, denied) as attempted:
                result = outcome(lambda: equal(dispatch.source_metadata(current=current), fixed['metadata']))
            assert result['accepted'] is (not current or label == 'historical-image')
            assert bool(attempted) is current
            rows.append(dict(label=label, current=current, reads=attempted, result=result))
    for label in ('float-bytes', 'missing-premise', 'rehashed-body', 'borrowed-programme'):
        candidate = copy.deepcopy(fixed['metadata'])
        if label == 'float-bytes':
            candidate['premises']['prepare.py']['bytes'] = float(candidate['premises']['prepare.py']['bytes'])
        elif label == 'missing-premise':
            del candidate['premises']['prepare.py']
        elif label == 'rehashed-body':
            candidate['premises']['prepare.py'] = dispatch.prepare.blob(changed['prepare.py'])
        else:
            candidate['programme'] = candidate['premises']['prepare.py']
        result = outcome(lambda: equal(candidate, dispatch.source_metadata()))
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


def collect():
    fixed = reference()
    actual = []
    for flags in ([], ['--current']):
        command = ['python3', '-B', str(AUDIT / dispatch.SELF), *flags]
        result = subprocess.run(command, cwd=ROOT, stdin=subprocess.DEVNULL, capture_output=True)
        actual.append(dict(command=command, status=result.returncode,
                           stdout=dispatch.prepare.blob(result.stdout), stderr=dispatch.prepare.blob(result.stderr)))
    equal(reference(), fixed)
    return dict(schema='fsmgen.default_dispatch_source_roles.v1', scope=SCOPE, sources=current_sources(),
                reference=fixed, controls=controls(fixed), actual=actual, original_data_unchanged=True)


def review(value):
    assert set(value) == {'schema', 'scope', 'sources', 'reference', 'controls', 'actual', 'original_data_unchanged'}
    equal(value['schema'], 'fsmgen.default_dispatch_source_roles.v1')
    equal(value['scope'], SCOPE)
    equal(value['sources'], current_sources())
    fixed = reference()
    equal(value['reference'], fixed)
    equal(value['controls'], controls(fixed))
    equal(value['original_data_unchanged'], True)
    assert type(value['actual']) is list and len(value['actual']) == 2
    for row, flags in zip(value['actual'], ([], ['--current'])):
        assert set(row) == {'command', 'status', 'stdout', 'stderr'}
        equal(row['command'], ['python3', '-B', str(AUDIT / dispatch.SELF), *flags])
        equal(row['status'], 1 if flags else 0)
        equal(unblob(row['stdout']), b'' if flags else LINE.encode())
        stderr = unblob(row['stderr'])
        if flags:
            assert stderr.endswith(b'AssertionError: exact scalar\n') and b'ram-guard:' not in stderr
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
    print('Original dispatch metadata and complete saved graph proof qualify; explicit current metadata remains refused and original data stays exact.')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    main()
