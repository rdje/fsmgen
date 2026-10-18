"""Preserve the original complete census with bounded comparison/control storage."""
import argparse
import gzip
import hashlib
import json
import resource
import sys

import execute
import prepare
import runtime_inventory as original

PATH = execute.AUDIT / 'runtime-source-inventory-bounded.json.gz'
CONTROLS = execute.AUDIT / 'runtime-source-inventory-bounded-controls.json.gz'


def strict_equal(value, expected):
    """Compare the full JSON domain without materializing either serialization."""
    assert type(value) is type(expected), 'JSON value kind'
    if isinstance(expected, dict):
        assert value.keys() == expected.keys(), 'complete object membership'
        for key in expected:
            strict_equal(value[key], expected[key])
    elif isinstance(expected, list):
        assert len(value) == len(expected), 'complete array membership'
        for left, right in zip(value, expected):
            strict_equal(left, right)
    else:
        assert value == expected, 'exact scalar'
    return True


def canonical_chunks(value):
    encoder = json.JSONEncoder(sort_keys=True, separators=(',', ':'), allow_nan=False)
    for chunk in encoder.iterencode(value):
        yield chunk.encode()
    yield b'\n'


def identity(value):
    digest, size = hashlib.sha256(), 0
    for chunk in canonical_chunks(value):
        digest.update(chunk)
        size += len(chunk)
    return dict(bytes=size, sha256=digest.hexdigest())


def save(path, value):
    # Preserve exclusive publication and canonical JSON bytes; gzip framing is
    # a storage detail. Failed partial outputs are retained, never overwritten.
    with execute.safe(path).open('xb') as raw:
        with gzip.GzipFile(filename='', mode='wb', fileobj=raw, mtime=0) as compressed:
            for chunk in canonical_chunks(value):
                compressed.write(chunk)


def changed(value, path, transform):
    if not path:
        return transform(value)
    result = value.copy()
    key, *tail = path
    result[key] = changed(value[key], tail, transform)
    return result


def controls(value):
    before = identity(value)
    member = next(name for name, row in value['records'].items() if row['sites'] and row['sites']['calls'])
    row = ('records', member)
    mutations = [
        ('missing_source', ('records',), lambda rows: {key: item for key, item in rows.items() if key != member}),
        ('extra_source', ('records',), lambda rows: dict(rows, **{'undeclared.py': rows[member]})),
        ('source_bytes', (*row, 'source'), lambda _: prepare.blob(b'changed source')),
        ('source_mode', (*row, 'mode'), lambda mode: '100755' if mode != '100755' else '100644'),
        ('missing_site', (*row, 'sites', 'calls'), lambda rows: rows[:-1]),
        ('coordinate', (*row, 'sites', 'calls', 0, 'column'), lambda column: column + 1),
        ('role', (*row, 'roles'), lambda roles: [*roles, 'executed']),
        ('kind', ('census', 'source_members'), float),
        ('permission', ('runtime_permission',), lambda _: True),
        ('scope', ('scope',), lambda _: 'complete default runtime permission'),
        ('nested_kind', (*row, 'sites', 'calls', 0, 'line'), float),
    ]
    outcomes = []
    for label, path, transform in mutations:
        candidate = changed(value, path, transform)
        try:
            strict_equal(candidate, value)
        except AssertionError:
            outcomes.append(label)
        else:
            raise AssertionError('invalid complete census admitted: ' + label)
    assert identity(value) == before, 'all original bytes/sites/roles conserve through controls'
    return outcomes


def maximum_rss():
    assert sys.platform == 'darwin', 'explicit Darwin ru_maxrss byte units'
    return resource.getrusage(resource.RUSAGE_SELF).ru_maxrss


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    if args.write:
        assert not execute.safe(PATH).exists() and not execute.safe(CONTROLS).exists()
    expected = original.build()
    phases = dict(after_complete_build_maxrss_bytes=maximum_rss())
    if args.write:
        value = expected
    else:
        with gzip.open(execute.safe(PATH), 'rt', encoding='utf-8') as stream:
            value = json.load(stream)
    assert strict_equal(value, expected)
    phases['after_complete_comparison_maxrss_bytes'] = maximum_rss()
    outcomes = controls(value)
    phases['after_controls_maxrss_bytes'] = maximum_rss()
    if args.write:
        save(PATH, value)
        phases['after_publication_maxrss_bytes'] = maximum_rss()
        execute.save(CONTROLS, dict(outcomes=outcomes, canonical_inventory=identity(value), phases=phases,
                                   programme=prepare.blob(execute.read(execute.AUDIT / 'bounded_runtime_inventory.py')),
                                   parser=sys.version,
                                   scope='Same complete prototype census and original corruptions with strict recursive comparison, '
                                         'branch-only candidate copies and streamed canonical publication. '
                                         'Separate diagnostic comparison; no attribution of the original failed process, '
                                         'execution/data role closure, expanded dynamic-code completeness or runtime permission.'))
    else:
        saved = json.loads(gzip.decompress(execute.read(CONTROLS)))
        assert saved['outcomes'] == outcomes and saved['canonical_inventory'] == identity(value)
    print('Complete unchanged fixed-source census and bounded strict corruption controls pass; runtime roles remain unresolved.')
