"""Retain exact completed matrix output; saved verification never reopens raw logs."""
import copy
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
        if node == ROOT: break
        assert not node.is_symlink() and node.stat().st_dev == ROOT.stat().st_dev
    assert path.is_file()
    return path.read_bytes()


def load(path):
    return json.loads(read(path))


def identity(raw):
    return dict(size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def verify(records, source=False):
    plan = load(BASE / 'plan.json')
    names = [prefix + '.' + ext for prefix in ('prepare', 'syntax', 'admission')
             for ext in ('stdout', 'stderr', 'exit')]
    names += ['qualify.tap', 'qualify.stderr', 'qualify.exit', 'qualification.json', 'admission.jsonl',
              'audit.stdout', 'audit.stderr', 'audit.exit', 'audit.json']
    names += ['cases/case-%04d.json' % c['index'] for c in plan['cases']]
    assert len(records) == len({r['destination'] for r in records}) == len(names)
    assert [(r['source'], r['destination']) for r in records] == [
        (str((LOG / n).relative_to(ROOT)), str((BASE / 'result' / n).relative_to(ROOT))) for n in names]
    for record in records:
        for key in ('source', 'destination'):
            relative = Path(record[key]); assert not relative.is_absolute() and '..' not in relative.parts
        assert record['source'].startswith(str(LOG.relative_to(ROOT)) + '/')
        assert record['destination'].startswith(str(BASE.relative_to(ROOT)) + '/result/')
        raw = read(ROOT / record['destination'])
        assert identity(raw) == {k: record[k] for k in ('size_bytes', 'sha256')}
        if source: assert raw == read(ROOT / record['source'])


def main():
    assert sys.argv[1:] in ([], ['--verify-saved'])
    output = BASE / 'result'; manifest = output / 'recovery-copies.json'
    if sys.argv[1:]:
        records = load(manifest); verify(records)
    else:
        assert not manifest.exists()
        plan = load(BASE / 'plan.json'); report = load(LOG / 'qualification.json')
        assert report['success'] is True and report['cases'] == [] and report['current_case'] is None
        assert load(LOG / 'audit.json')['success'] is True
        for prefix in ('prepare', 'syntax', 'admission', 'qualify', 'audit'):
            assert read(LOG / (prefix + '.exit')) == b'0\n'
        names = [prefix + '.' + ext for prefix in ('prepare', 'syntax', 'admission')
                 for ext in ('stdout', 'stderr', 'exit')]
        names += ['qualify.tap', 'qualify.stderr', 'qualify.exit', 'qualification.json', 'admission.jsonl',
                  'audit.stdout', 'audit.stderr', 'audit.exit', 'audit.json']
        assert len(plan['cases']) == len(report['case_files'])
        expected = set()
        for case, receipt in zip(plan['cases'], report['case_files'], strict=True):
            assert receipt['index'] == case['index'] and receipt['name'] == case['name']
            name = 'cases/case-%04d.json' % case['index']; expected.add(name.removeprefix('cases/'))
            raw = read(LOG / name); assert identity(raw) == {k: receipt[k] for k in ('size_bytes', 'sha256')}
            assert json.loads(raw)['roots_absent'] is True
            names.append(name)
        assert {p.name for p in (LOG / 'cases').iterdir()} == expected
        records = []
        for name in names:
            raw = read(LOG / name)
            records.append(dict(source=str((LOG / name).relative_to(ROOT)),
                destination=str((output / name).relative_to(ROOT)), **identity(raw)))
        # An exact plan precedes copies. If interrupted, only byte-identical
        # existing copies may be accepted; divergent or foreign bytes fail.
        recovery_plan = output / 'recovery-plan.json'
        if recovery_plan.exists():
            assert load(recovery_plan) == records
        else:
            with recovery_plan.open('x') as stream: stream.write(json.dumps(records, sort_keys=True, indent=2) + '\n')
        destination_cases = output / 'cases'
        if destination_cases.exists():
            assert destination_cases.is_dir() and not destination_cases.is_symlink()
            assert {p.name for p in destination_cases.iterdir()} <= expected
        else:
            destination_cases.mkdir()
        for record in records:
            raw = read(ROOT / record['source']); assert identity(raw) == {k: record[k] for k in ('size_bytes', 'sha256')}
            destination = ROOT / record['destination']
            if destination.exists(): assert read(destination) == raw
            else:
                with destination.open('xb') as stream: stream.write(raw)
        verify(records, True)
        with manifest.open('x') as stream: stream.write(json.dumps(records, sort_keys=True, indent=2) + '\n')
    controls = []
    for name, change in (
        ('omitted-copy', lambda rows: rows.pop()),
        ('foreign-destination', lambda rows: rows[0].update(destination='foreign')),
        ('changed-copy-digest', lambda rows: rows[0].update(sha256='0' * 64)),
    ):
        changed = copy.deepcopy(records); change(changed)
        try:
            verify(changed)
        except (AssertionError, KeyError, ValueError, TypeError):
            controls.append(name)
        else:
            raise AssertionError(name)
    print(json.dumps(dict(success=True, copies=len(records), bytes=sum(r['size_bytes'] for r in records),
        source_reaccess=not bool(sys.argv[1:]), falsifiers=controls), sort_keys=True))


if __name__ == '__main__':
    main()
