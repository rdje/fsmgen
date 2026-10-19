"""Recover exact earlier qualification drafts from one lossless byte archive."""
import argparse
import hashlib
import json
import lzma

import execute
import prepare

PATH = execute.AUDIT / 'caller-modules-draft-retention.json'
ARCHIVE = execute.AUDIT / 'caller-modules-drafts.gzip-pair.xz'


def verify(manifest):
    assert manifest['schema'] == 'fsmgen.caller_module_draft_retention.v1'
    encoded = execute.read(ARCHIVE)
    assert prepare.identity(encoded) == manifest['archive']
    offset = 0
    with lzma.open(execute.safe(ARCHIVE), 'rb') as stream:
        for row in manifest['records']:
            assert row['offset'] == offset and type(row['bytes']) is int
            body = stream.read(row['bytes'])
            assert len(body) == row['bytes'] and hashlib.sha256(body).hexdigest() == row['sha256']
            offset += len(body)
        assert not stream.read(1), 'complete byte archive, no trailing draft'
    assert manifest['programme'] == prepare.identity(execute.read(execute.AUDIT / 'verify_caller_drafts.py'))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pack', action='store_true')
    args = parser.parse_args()
    manifest = json.loads(execute.read(PATH))
    if args.pack:
        assert isinstance(manifest, list) and len(manifest) == 2, 'unpacked complete drafts'
        records, offset = [], 0
        with execute.safe(ARCHIVE).open('xb') as output:
            with lzma.LZMAFile(output, 'wb', filters=[dict(id=lzma.FILTER_LZMA2, preset=1, dict_size=64 * 1024 * 1024)]) as stream:
                for row in manifest:
                    encoded = execute.read(row['path'])
                    assert prepare.identity(encoded) == dict(bytes=row['archive_bytes'], sha256=row['archive_sha256'])
                    body = lzma.decompress(encoded)
                    assert prepare.identity(body) == dict(bytes=row['bytes'], sha256=row['sha256'])
                    stream.write(body)
                    records.append(dict(former_path=row['former_path'], offset=offset,
                                        bytes=row['bytes'], sha256=row['sha256']))
                    offset += len(body)
        packed = dict(schema='fsmgen.caller_module_draft_retention.v1', records=records,
                      archive=prepare.identity(execute.read(ARCHIVE)),
                      programme=prepare.identity(execute.read(execute.AUDIT / 'verify_caller_drafts.py')),
                      recovery='LZMA-decompress the archive; each ordered offset/byte range is the exact former gzip file.')
        verify(packed)
        execute.safe(PATH).write_text(json.dumps(packed, sort_keys=True, indent=2) + '\n')
        # Only exact authenticated, now-recoverable duplicate byte containers.
        for row in manifest:
            execute.safe(row['path']).unlink()
        manifest = packed
    verify(manifest)
    print('Complete earlier draft gzip bytes recover exactly; no source or historical reader executes.')
