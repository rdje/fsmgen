"""Preserve exact join output with an exclusive, resumable copy plan."""
import copy
import hashlib
import json
from pathlib import Path
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name
NAMES = [prefix + '.' + ext for prefix in ('prepare', 'admission', 'join')
         for ext in ('stdout', 'stderr', 'exit')] + ['join.json']


def source_path(name):
    prefix = name.split('.', 1)[0]
    return LOG / ('final-' + name if prefix in ('admission', 'join')  else name)


def read(path):
    assert path.is_relative_to(ROOT)
    for node in [path, *path.parents]:
        if node == ROOT:
            break
        assert not node.is_symlink() and node.stat().st_dev == ROOT.stat().st_dev
    assert path.is_file()
    return path.read_bytes()


def load(path):
    return json.loads(read(path))


def identity(raw):
    return dict(size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def verify(records, source=False):
    assert len(records) == len({r['destination'] for r in records}) == len(NAMES)
    assert [(r['source'], r['destination']) for r in records] == [
        (str(source_path(name).relative_to(ROOT)), str((BASE / 'result' / name).relative_to(ROOT))) for name in NAMES]
    for record in records:
        assert set(record) == {'source', 'destination', 'size_bytes', 'sha256'}
        raw = read(ROOT / record['destination'])
        assert identity(raw) == {k: record[k] for k in ('size_bytes', 'sha256')}
        if source:
            assert raw == read(ROOT / record['source'])


def main():
    assert sys.argv[1:] in ([], ['--verify-saved'])
    assert load(BASE / 'recovery-final-pins.json') == [dict(path=str((BASE / 'recover-final.py').relative_to(ROOT)),
                                                   **identity(read(BASE / 'recover-final.py')))]
    output = BASE / 'result'
    manifest = output / 'recovery-copies.json'
    recovery_plan = output / 'recovery-plan.json'
    if sys.argv[1:]:
        records = load(manifest)
        assert records == load(recovery_plan)
        verify(records)
    else:
        assert not manifest.exists()
        assert load(LOG / 'final-join.json')['success'] is True
        for prefix in ('prepare', 'admission', 'join'):
            assert read(source_path(prefix + '.exit')) == b'0\n'
        output.mkdir(exist_ok=True)
        assert not output.is_symlink() and output.stat().st_dev == ROOT.stat().st_dev
        records = [dict(source=str(source_path(name).relative_to(ROOT)),
            destination=str((output / name).relative_to(ROOT)), **identity(read(source_path(name)))) for name in NAMES]
        if recovery_plan.exists():
            assert load(recovery_plan) == records
        else:
            with recovery_plan.open('x') as stream:
                stream.write(json.dumps(records, sort_keys=True, indent=2) + '\n')
        for record in records:
            raw = read(ROOT / record['source'])
            destination = ROOT / record['destination']
            if destination.exists():
                assert read(destination) == raw
            else:
                with destination.open('xb') as stream:
                    stream.write(raw)
        verify(records, True)
        with manifest.open('x') as stream:
            stream.write(json.dumps(records, sort_keys=True, indent=2) + '\n')
    controls = []
    for name, mutate in (
        ('missing-copy', lambda rows: rows.pop()),
        ('foreign-destination', lambda rows: rows[0].update(destination='foreign')),
        ('corrupt-copy-digest', lambda rows: rows[0].update(sha256='0' * 64)),
    ):
        bad = copy.deepcopy(records); mutate(bad)
        try:
            verify(bad)
        except (AssertionError, KeyError, TypeError, ValueError):
            controls.append(name)
        else:
            raise AssertionError(name)
    print(json.dumps(dict(success=True, copies=len(records), bytes=sum(r['size_bytes'] for r in records),
        falsifiers=controls, source_reaccess=not bool(sys.argv[1:])), sort_keys=True))


if __name__ == '__main__':
    main()
