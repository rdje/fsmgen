"""Preserve the complete first selection run with exact, resumable copies."""
import copy
import hashlib
import json
from pathlib import Path
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name
NAMES = tuple(prefix + '.' + ext for prefix in ('prepare', 'audit')
              for ext in ('stdout', 'stderr', 'exit')) + ('audit.json',)


def read(path):
    assert path.is_relative_to(ROOT)
    for node in [path, *path.parents]:
        if node == ROOT: break
        assert not node.is_symlink() and node.stat().st_dev == ROOT.stat().st_dev
    assert path.is_file()
    return path.read_bytes()


def pin(path):
    raw = read(path)
    return dict(path=str(path.relative_to(ROOT)), size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def verify(records, sources=False):
    expected = [(str((LOG / name).relative_to(ROOT)), str((BASE / 'result' / name).relative_to(ROOT)))
                for name in NAMES]
    assert [(r['source'], r['destination']) for r in records] == expected
    for record in records:
        assert set(record) == {'source', 'destination', 'size_bytes', 'sha256'}
        raw = read(ROOT / record['destination'])
        assert len(raw) == record['size_bytes'] and hashlib.sha256(raw).hexdigest() == record['sha256']
        if sources: assert raw == read(ROOT / record['source'])


def main():
    assert sys.argv[1:] in ([], ['--verify-saved'])
    assert json.loads(read(BASE / 'recovery-pins.json')) == [pin(BASE / 'recover.py')]
    output = BASE / 'result'
    if not sys.argv[1:]:
        assert json.loads(read(LOG / 'audit.json'))['success'] is True
        assert all(read(LOG / (prefix + '.exit')) == b'0\n' for prefix in ('prepare', 'audit'))
        records = []
        for name in NAMES:
            raw = read(LOG / name)
            records.append(dict(source=str((LOG / name).relative_to(ROOT)),
                destination=str((output / name).relative_to(ROOT)), size_bytes=len(raw),
                sha256=hashlib.sha256(raw).hexdigest()))
        manifest = json.dumps(records, indent=2, sort_keys=True).encode() + b'\n'
        if not output.exists(): output.mkdir()
        planned = output / 'recovery-plan.json'
        if planned.exists(): assert read(planned) == manifest
        else:
            with planned.open('xb') as stream: stream.write(manifest)
        for record in records:
            source, destination = ROOT / record['source'], ROOT / record['destination']
            if destination.exists(): assert read(destination) == read(source)
            else:
                with destination.open('xb') as stream: stream.write(read(source))
        verify(records, True)
        completed = output / 'recovery-copies.json'
        if completed.exists(): assert read(completed) == manifest
        else:
            with completed.open('xb') as stream: stream.write(manifest)
    records = json.loads(read(output / 'recovery-copies.json'))
    assert records == json.loads(read(output / 'recovery-plan.json'))
    verify(records)
    controls = []
    for name, mutate in (
        ('omitted-copy', lambda r: r.pop()),
        ('foreign-destination', lambda r: r[0].update(destination='foreign')),
        ('changed-copy-digest', lambda r: r[0].update(sha256='0' * 64)),
    ):
        changed = copy.deepcopy(records); mutate(changed)
        try: verify(changed)
        except AssertionError: controls.append(name)
        else: raise AssertionError(name)
    print(json.dumps(dict(success=True, copies=len(records), bytes=sum(r['size_bytes'] for r in records),
        source_reaccess=not bool(sys.argv[1:]), falsifiers=controls), sort_keys=True))


if __name__ == '__main__':
    main()
