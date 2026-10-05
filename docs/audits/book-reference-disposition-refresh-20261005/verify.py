"""Conserve the source-specific disposition across native destination publication."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/book-reference-disposition-refresh-20261005')
REGISTRY = Path('doctrine/claim_verification/dispositions.jsonl')
REVISION = '7b67fa41e7961ea74f51c42680aaf6e610c5ba76'


def exact(a, b):
    return json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True)


def main():
    pins = json.loads((BASE / 'manifest.json').read_text())
    assert set(pins) == {str(p) for p in BASE.iterdir() if p.is_file() and p.name != 'manifest.json'}
    for path, pin in pins.items():
        raw = Path(path).read_bytes()
        assert exact(pin, {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()})
    record = json.loads((BASE / 'refresh.json').read_text())
    before = (BASE / 'registry-before.jsonl').read_bytes()
    assert before == subprocess.check_output(['git', 'show', REVISION + ':' + str(REGISTRY)])
    lines = before.decode().splitlines()
    assert sum(json.loads(line).get('candidate_id') == record['old']['candidate_id'] for line in lines) == 1
    assert exact(record['new'], dict(record['old'], candidate_id=record['new']['candidate_id']))
    updated = '\n'.join(json.dumps(record['new'], sort_keys=True, separators=(',', ':'))
                        if json.loads(line).get('candidate_id') == record['old']['candidate_id'] else line for line in lines) + '\n'
    assert updated.encode() == (BASE / 'registry-after.jsonl').read_bytes()
    actual = [json.loads(line) for line in REGISTRY.read_text().splitlines()]
    assert not any(row.get('candidate_id') == record['old']['candidate_id'] for row in actual)
    assert sum(exact(row, record['new']) for row in actual) == 1
    inventory = [json.loads(line) for line in Path('doctrine/claim_verification/inventory.jsonl').read_text().splitlines()]
    candidate = next(row for row in inventory if row.get('candidate_id') == record['new']['candidate_id'])
    assert candidate['path'] == record['path'] and candidate['excerpt'] == record['after_line']
    assert candidate['source_line_sha256'] == hashlib.sha256(record['after_line'].encode()).hexdigest()
    assert record['new']['disposition'] == 'reviewed_incidental' and record['new']['reason_code'] == 'identifier_or_navigation'
    print('PASS full disposition conservation and authoritative current candidate/line identity agree.')


if __name__ == '__main__':
    main()
