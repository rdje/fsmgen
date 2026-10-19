"""Qualify saved cache-source replay while retaining strict current checks."""
import argparse
import contextlib
import copy
import gzip
import hashlib
import json
from pathlib import Path
import subprocess

import prepare
import verify_runtime_cache as reader

ROOT, AUDIT = prepare.ROOT, prepare.AUDIT
SELF = AUDIT / 'qualify_runtime_cache_roles.py'
PATH = AUDIT / 'runtime-cache-source-roles-qualified.json.gz'
SAVED_LINE = ('Full unchanged public cache matrix and closed fixed derived-output evidence pass; '
              'permissive consumer shapes and default roles stay explicit.\n')
SCOPE = ('Saved runtime-cache source identities only. Original instruments and the original saved '
         'reader programme reconstruct from native Git; every original compressed input remains exact. '
         'Actual saved CLI passes, current/write CLIs retain strict instrument refusal, and original '
         'data stays unchanged. Source-predicate image, denied-read, type/member/body and native '
         'interventions are inert controls, not new producer or semantic execution. Original consumer '
         'permissiveness, operational admission, spent intakes, native/private/HIAL and full-CI gates retain.')


def sources():
    return {name: prepare.blob((ROOT / AUDIT / name).read_bytes()) for name in
            ('verify_runtime_cache.py', 'qualify_runtime_cache_roles.py')}


def unblob(value):
    raw = prepare.unblob(value)
    reader.typed.strict_equal(value, prepare.blob(raw))
    return raw


def reference():
    names = ['runtime-cache-producer-final-qualified.json.gz']
    names += ['runtime-cache-producer-' + suffix + '.json.gz' for suffix in
              ('started', 'actual', 'instrument-refusal', *reader.producer.LABELS)]
    result = {}
    for name in names:
        path = str(AUDIT / name)
        entry = reader.execute.command(['git', '--no-replace-objects', 'ls-tree', '--full-tree',
                                        '-l', '-z', reader.SOURCE_REVISION, '--', path])
        assert entry.count(b'\0') == 1
        header, actual_path = entry[:-1].split(b'\t')
        mode, kind, oid, size = header.decode().split()
        assert mode == '100644' and kind == 'blob' and actual_path.decode() == path
        raw = reader.execute.command(['git', '--no-replace-objects', 'show', reader.SOURCE_REVISION + ':' + path])
        assert size.isdecimal() and len(raw) == int(size)
        assert raw == reader.execute.command(['git', '--no-replace-objects', 'cat-file', 'blob', oid])
        assert hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest() == oid
        assert (ROOT / path).read_bytes() == raw, 'original runtime-cache data unchanged: ' + path
        result[path] = dict(revision=reader.SOURCE_REVISION, mode=mode, oid=oid,
                            identity=prepare.identity(raw), retention_contract='fsmgen_required_history')
    instruments = {name: prepare.blob(reader.captured_source(name)) for name in
                   (*reader.producer.NAMES, reader.SELF)}
    return dict(data=result, instruments=instruments)


def outcome(action):
    try:
        action()
    except AssertionError as error:
        return dict(accepted=False, error=str(error))
    return dict(accepted=True, error=None)


@contextlib.contextmanager
def supplied_sources(images, denied=False):
    original = reader.execute.read
    names = {str(AUDIT / name): name for name in reader.producer.NAMES}
    attempted = []

    def supplied(path):
        name = names.get(str(path))
        if name is None:
            return original(path)
        attempted.append(name)
        if denied:
            raise AssertionError('deliberately denied current instrument')
        return images[name]

    try:
        reader.execute.read = supplied
        yield attempted
    finally:
        reader.execute.read = original


def controls():
    start = dict(sources=reader.load('started')['sources'])
    images = {name: reader.captured_source(name) for name in reader.producer.NAMES}
    changed = dict(images, **{'prepare.py': b'x' + images['prepare.py'][1:]})
    rows = []
    for label, supplied, denied in (('historical-image', images, False),
                                    ('changed-image', changed, False), ('denied-image', images, True)):
        for current in (False, True):
            with supplied_sources(supplied, denied) as attempted:
                result = outcome(lambda: reader.validate_sources(start, current=current))
            assert result['accepted'] is (not current or label == 'historical-image')
            assert bool(attempted) is current
            rows.append(dict(label=label, current=current, reads=attempted, result=result))
    # These candidates exercise only the captured-source predicate. Actual
    # complete saved/current/write commands are recorded separately below.
    for label in ('float-bytes', 'boolean-bytes', 'missing-member', 'extra-member', 'rehashed-body', 'borrowed-body'):
        candidate = copy.deepcopy(start)
        if label == 'float-bytes':
            candidate['sources']['prepare.py']['bytes'] = float(candidate['sources']['prepare.py']['bytes'])
        elif label == 'boolean-bytes':
            candidate['sources']['prepare.py']['bytes'] = True
        elif label == 'missing-member':
            del candidate['sources']['prepare.py']
        elif label == 'extra-member':
            candidate['sources']['extra.py'] = prepare.blob(b'extra instrument')
        elif label == 'rehashed-body':
            candidate['sources']['prepare.py'] = prepare.blob(changed['prepare.py'])
        else:
            candidate['sources']['prepare.py'] = prepare.blob(images['epoch_constraints.py'])
        result = outcome(lambda: reader.validate_sources(candidate))
        assert not result['accepted'], label
        rows.append(dict(label=label, candidate=candidate, result=result))
    rows.append(dict(label='closed-member', result=outcome(lambda: reader.captured_source('../prepare.py'))))
    assert not rows[-1]['result']['accepted']
    command = reader.execute.command
    try:
        def changed_show(argv):
            raw = command(argv)
            return b'x' + raw[1:] if argv[2] == 'show' else raw
        reader.execute.command = changed_show
        result = outcome(lambda: reader.captured_source('prepare.py'))
        assert not result['accepted']
        rows.append(dict(label='changed-native-show', result=result))
    finally:
        reader.execute.command = command
    return rows


def collect():
    before = reference()
    actual = []
    for flags in ([], ['--current'], ['--write']):
        command = ['python3', '-B', str(AUDIT / reader.SELF), *flags]
        result = subprocess.run(command, cwd=ROOT, stdin=subprocess.DEVNULL, capture_output=True)
        actual.append(dict(command=command, status=result.returncode,
                           stdout=prepare.blob(result.stdout), stderr=prepare.blob(result.stderr)))
    after = reference()
    reader.typed.strict_equal(before, after)
    return dict(schema='fsmgen.runtime_cache_source_roles.v1', scope=SCOPE, sources=sources(),
                reference=before, controls=controls(), actual=actual, original_data_unchanged=True)


def review(value):
    assert set(value) == {'schema', 'scope', 'sources', 'reference', 'controls', 'actual', 'original_data_unchanged'}
    equal = reader.typed.strict_equal
    equal(value['schema'], 'fsmgen.runtime_cache_source_roles.v1')
    equal(value['scope'], SCOPE)
    equal(value['sources'], sources())
    equal(value['reference'], reference())
    equal(value['controls'], controls())
    equal(value['original_data_unchanged'], True)
    assert type(value['actual']) is list and len(value['actual']) == 3
    for row, flags in zip(value['actual'], ([], ['--current'], ['--write'])):
        assert set(row) == {'command', 'status', 'stdout', 'stderr'}
        equal(row['command'], ['python3', '-B', str(AUDIT / reader.SELF), *flags])
        equal(row['status'], 1 if flags else 0)
        equal(unblob(row['stdout']), b'' if flags else SAVED_LINE.encode())
        stderr = unblob(row['stderr'])
        if flags:
            assert b'current producer instrument: prepare.py' in stderr and stderr.endswith(b'\n')
            assert b'ram-guard:' not in stderr
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
    print('Saved runtime-cache sources and data qualify; actual current/write roles retain strict refusal and original data stays exact.')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    main()
