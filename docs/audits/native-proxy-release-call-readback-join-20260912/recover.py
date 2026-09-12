"""Recover the join's own output; never copy or re-execute earlier fixtures."""
import hashlib
import json
from pathlib import Path
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name


def read(path):
    assert path.is_relative_to(ROOT)
    for node in [path, *path.parents]:
        if node == ROOT:
            break
        assert not node.is_symlink() and node.stat().st_dev == ROOT.stat().st_dev
    assert path.is_file()
    return path.read_bytes()


def verify(records, source=False):
    assert len(records) == len({r['destination'] for r in records}) == 10
    for record in records:
        for key in ('source', 'destination'):
            path = Path(record[key])
            assert not path.is_absolute() and '..' not in path.parts
        raw = read(ROOT / record['destination'])
        assert len(raw) == record['size_bytes'] and hashlib.sha256(raw).hexdigest() == record['sha256']
        if source:
            assert raw == read(ROOT / record['source'])


def main():
    assert sys.argv[1:] in ([], ['--verify-saved'])
    output = BASE / 'result'
    if sys.argv[1:]:
        records = json.loads(read(output / 'recovery-copies.json'))
        verify(records)
    else:
        assert not output.exists()
        assert json.loads(read(LOG / 'join.json'))['success'] is True
        for prefix in ('prepare', 'admission', 'join'):
            assert read(LOG / (prefix + '.exit')) == b'0\n'
        output.mkdir()
        names = [prefix + '.' + ext for prefix in ('prepare', 'admission', 'join')
                 for ext in ('stdout', 'stderr', 'exit')] + ['join.json']
        records = []
        for name in names:
            raw = read(LOG / name)
            with (output / name).open('xb') as stream:
                stream.write(raw)
            records.append(dict(source=str((LOG / name).relative_to(ROOT)),
                destination=str((output / name).relative_to(ROOT)), size_bytes=len(raw),
                sha256=hashlib.sha256(raw).hexdigest()))
        verify(records, True)
        with (output / 'recovery-copies.json').open('x') as stream:
            stream.write(json.dumps(records, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(success=True, copies=len(records), bytes=sum(r['size_bytes'] for r in records),
                         source_reaccess=not bool(sys.argv[1:])), sort_keys=True))


if __name__ == '__main__':
    main()
