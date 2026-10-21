"""Deliver the exact payload route archive through fixed, authenticated byte parts."""
import argparse
import hashlib
import json
import os
from pathlib import Path

import rollover_source_card as card

AUDIT = 'docs/audits/original-join-parent-acceptance-20261018/'
SELF = AUDIT + 'payload_proof_parts.py'
RAW = AUDIT + 'payload-live-route-qualified.json.gz'
MANIFEST = AUDIT + 'payload-live-route-parts.json'
CHUNK = 40 * 1024 * 1024
SCHEMA = 'fsmgen.payload_route_byte_parts.v1'
EXPECTED = {'bytes': 117304563, 'sha256': 'f475258680a567c1966ac840c0db4bd771db8a606170f9fd2a5c4341c399594a'}


def identity(body):
    return dict(bytes=len(body), sha256=hashlib.sha256(body).hexdigest())


def read_regular(path):
    target = card.safe(path)
    assert target.is_file() and not target.is_symlink(), 'regular same-volume part'
    assert target.stat().st_dev == card.ROOT.stat().st_dev, 'regular same-volume part'
    return target.read_bytes()


def integer(value):
    assert type(value) is int and value >= 0, 'integer size or index'


def digest(value):
    assert type(value) is str and len(value) == 64 and all(c in '0123456789abcdef' for c in value), 'SHA256 text'


def recover(value, read=read_regular):
    assert type(value) is dict and set(value) == {'schema', 'logical_path', 'identity', 'chunk_bytes', 'parts'}, 'manifest fields'
    assert value['schema'] == SCHEMA and value['logical_path'] == RAW, 'fixed logical archive'
    integer(value['chunk_bytes'])
    assert value['chunk_bytes'] == CHUNK, 'fixed part capacity'
    whole = value['identity']
    assert type(whole) is dict and set(whole) == {'bytes', 'sha256'}, 'whole identity fields'
    integer(whole['bytes']); digest(whole['sha256'])
    assert whole == EXPECTED, 'fixed original archive identity'
    count = (whole['bytes'] + CHUNK - 1) // CHUNK
    assert type(value['parts']) is list and len(value['parts']) == count, 'complete part membership'
    bodies = []
    for i, row in enumerate(value['parts']):
        assert type(row) is dict and set(row) == {'index', 'path', 'bytes', 'sha256'}, 'part fields'
        integer(row['index']); integer(row['bytes']); digest(row['sha256'])
        assert row['index'] == i, 'part order'
        assert row['path'] == AUDIT + f'payload-live-route.part-{i:03d}.bin', 'fixed part path'
        assert row['bytes'] == min(CHUNK, whole['bytes'] - i * CHUNK), 'complete part extent'
        body = read(row['path'])
        assert type(body) is bytes and identity(body) == {k: row[k] for k in ('bytes', 'sha256')}, 'part identity'
        bodies.append(body)
    body = b''.join(bodies)
    assert identity(body) == whole, 'complete compressed archive identity'
    return body


def read():
    return recover(json.loads(read_regular(MANIFEST)))


def pack():
    """Write exclusively; leave the original untouched for separate verified custody."""
    raw = read_regular(RAW)
    value = dict(schema=SCHEMA, logical_path=RAW, identity=identity(raw), chunk_bytes=CHUNK, parts=[])
    for i, offset in enumerate(range(0, len(raw), CHUNK)):
        path = AUDIT + f'payload-live-route.part-{i:03d}.bin'
        body = raw[offset:offset + CHUNK]
        with card.safe(path).open('xb') as stream:
            stream.write(body); stream.flush(); os.fsync(stream.fileno())
        value['parts'].append(dict(index=i, path=path, **identity(body)))
    encoded = (json.dumps(value, sort_keys=True, separators=(',', ':'), allow_nan=False) + '\n').encode()
    with card.safe(MANIFEST).open('xb') as stream:
        stream.write(encoded); stream.flush(); os.fsync(stream.fileno())
    assert read() == raw, 'exact original compressed bytes'


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pack', action='store_true')
    args = parser.parse_args()
    if args.pack:
        pack()
    else:
        read()
    print('Fixed payload route byte parts recover the complete original compressed archive.')
