"""Retain exact draft/gate files in one verified same-volume archive."""
import argparse
import gzip
import hashlib
import io
import json
import tarfile
from pathlib import Path

BASE = Path('docs/audits/coordinate-public-route-checks-20261008')
NAMES = ('first-current-tests.py.txt', 'first-independent.py.txt', 'second-independent.py.txt',
         'first-workflow.py.txt', 'first-route-control.py.txt', 'second-route-control.py.txt',
         'first-route-product.json', 'route.json', 'route-final.json', 'focused.json',
         'saved-result.json', 'saved-final.json', 'workflow.json', 'doctrines.json',
         'doctrines-final.json', 'first-hook-failure.json', 'hook-gate-replay.json',
         'hook-inventory-diagnosis.json', 'parser-diagnosis.json')


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def check():
    catalog = json.loads((BASE / 'drafts.json').read_bytes())
    with tarfile.open(BASE / 'drafts.tar.gz') as archive:
        members = archive.getmembers()
        assert all(m.isfile() for m in members) and [m.name for m in members] == list(NAMES)
        restored = {m.name: archive.extractfile(m).read() for m in members}
    assert catalog['members'] == {name: pin(raw) for name, raw in restored.items()}
    assert catalog['archive'] == pin((BASE / 'drafts.tar.gz').read_bytes())
    return restored


def main():
    parser = argparse.ArgumentParser(description=__doc__); parser.add_argument('--pack', action='store_true'); args = parser.parse_args()
    if args.pack:
        assert not (BASE / 'drafts.tar.gz').exists() and not (BASE / 'drafts.json').exists()
        assert all((BASE / name).is_file() and not (BASE / name).is_symlink()
                   and (BASE / name).stat().st_dev == BASE.stat().st_dev for name in NAMES)
        original = {name: (BASE / name).read_bytes() for name in NAMES}
        stream = io.BytesIO()
        with tarfile.open(fileobj=stream, mode='w') as archive:
            for name, raw in original.items():
                member = tarfile.TarInfo(name); member.size = len(raw); archive.addfile(member, io.BytesIO(raw))
        (BASE / 'drafts.tar.gz').write_bytes(gzip.compress(stream.getvalue(), mtime=0))
        catalog = dict(archive=pin((BASE / 'drafts.tar.gz').read_bytes()), members={n: pin(v) for n, v in original.items()},
                       retrieval='Read exact named regular members with tarfile; no extraction needed. All original source/command/status/stream bytes retain.',
                       role='Physical path packing only; no evidence is discarded and no inventory allowance changes.')
        (BASE / 'drafts.json').write_text(json.dumps(catalog, sort_keys=True, indent=2) + '\n')
        assert check() == original
        for name in NAMES:
            assert (BASE / name).read_bytes() == original[name]
            (BASE / name).unlink()
        assert all(not (BASE / name).exists() for name in NAMES)
    else:
        check()
    print('PASS exact draft/gate archive members hashes and retrieval; original file bytes retained under unchanged limits.')


if __name__ == '__main__':
    main()
