"""Copy exact completed evidence, or verify the saved recovery manifest.

This is a storage step only. It cannot execute a fixture or substitute for the
independent audit. Existing destinations are compared, never overwritten.
"""
import hashlib
import json
from pathlib import Path
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name
RESULT = BASE / 'result'


def safe_file(path):
    for ancestor in [path, *path.parents]:
        if ancestor == ROOT:
            break
        assert not ancestor.is_symlink() and ancestor.stat().st_dev == ROOT.stat().st_dev
    assert path.is_file()
    return path.read_bytes()


def verify(records, require_sources):
    assert len({r['destination'] for r in records}) == len(records)
    for record in records:
        for key in ('source', 'destination'):
            path = Path(record[key])
            assert not path.is_absolute() and '..' not in path.parts
        raw = safe_file(ROOT / record['destination'])
        assert len(raw) == record['size_bytes'] and hashlib.sha256(raw).hexdigest() == record['sha256']
        if require_sources:
            assert raw == safe_file(ROOT / record['source'])


def main():
    assert sys.argv[1:] in ([], ['--verify-saved'])
    manifest = RESULT / 'recovery-copies.json'
    if sys.argv[1:]:
        records = json.loads(safe_file(manifest))
        verify(records, False)
        print(json.dumps(dict(success=True, recovery_copies=len(records), source_reaccess=False), sort_keys=True))
        return
    assert not manifest.exists() and not manifest.is_symlink()
    report = json.loads(safe_file(LOG / 'qualification.json'))
    audit = json.loads(safe_file(LOG / 'audit.json'))
    assert report['success'] is audit['success'] is True
    assert safe_file(LOG / 'qualify.exit') == safe_file(LOG / 'audit.exit') == b'0\n'
    assert len(report['case_files']) == audit['cases'] == 518
    names = ['qualification.json', 'admission.jsonl', 'qualify.tap', 'qualify.stderr', 'qualify.exit',
             'audit.json']
    names += ['case-%04d.json' % r['index'] for r in report['case_files']]
    pairs = [(LOG / n, RESULT / n) if not n.startswith('case-')
             else (LOG / 'cases' / n, RESULT / 'cases' / n) for n in names]
    pairs += [(LOG / ('audit.' + suffix), RESULT / ('audit.' + suffix))
              for suffix in ('stdout', 'stderr', 'exit')]
    for prefix in ('prepare', 'syntax', 'audit-admission', 'hook-admission',
                   'knowledge-gen', 'knowledge-check', 'task'):
        pairs.extend((LOG / (prefix + '.' + suffix), RESULT / (prefix + '.' + suffix))
                     for suffix in ('stdout', 'stderr', 'exit'))
    pairs.append((LOG / 'book.exit', RESULT / 'book.exit'))
    pairs += [(LOG / ('oracle-preflight.' + suffix), RESULT / 'oracle-preflight' / ('oracle-preflight.' + suffix))
              for suffix in ('json', 'stdout', 'stderr', 'exit')]
    records = []
    for source, destination in pairs:
        raw = safe_file(source)
        destination.parent.mkdir(parents=True, exist_ok=True)
        assert destination.parent.stat().st_dev == ROOT.stat().st_dev and not destination.parent.is_symlink()
        if destination.exists() or destination.is_symlink():
            assert safe_file(destination) == raw
        else:
            with destination.open('xb') as output:
                output.write(raw)
        records.append(dict(source=str(source.relative_to(ROOT)), destination=str(destination.relative_to(ROOT)),
            size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest()))
    verify(records, True)
    with manifest.open('x') as output:
        output.write(json.dumps(records, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(success=True, recovery_copies=len(records), copied_bytes=sum(r['size_bytes'] for r in records),
                         source_reaccess=True), sort_keys=True))


if __name__ == '__main__':
    main()
