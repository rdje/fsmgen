"""Authenticate the exact lossless ordering repair and current candidate role."""
import collections
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/book-reference-disposition-order-20261005')
REGISTRY = Path('doctrine/claim_verification/dispositions.jsonl')
pins = json.loads((BASE / 'manifest.json').read_text())
assert set(pins) == {str(p) for p in BASE.iterdir() if p.is_file() and p.name != 'manifest.json'}
for path, pin in pins.items():
    raw = Path(path).read_bytes()
    assert json.dumps(pin, sort_keys=True) == json.dumps({'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}, sort_keys=True)
before = (BASE / 'before.jsonl').read_bytes().splitlines(keepends=True)
after = (BASE / 'after.jsonl').read_bytes().splitlines(keepends=True)
assert before[0] == after[0]
assert collections.Counter(before[1:]) == collections.Counter(after[1:])
assert after[1:] == sorted(before[1:], key=lambda line: json.loads(line)['candidate_id'])
record = json.loads(Path('docs/audits/book-reference-disposition-refresh-20261005/refresh.json').read_text())
assert b''.join(before) == Path('docs/audits/book-reference-disposition-refresh-20261005/registry-after.jsonl').read_bytes()
current = [json.loads(line) for line in REGISTRY.read_text().splitlines()[1:]]
ids = [row['candidate_id'] for row in current]
assert ids == sorted(ids) and len(set(ids)) == len(ids)
assert record['old']['candidate_id'] not in ids
assert sum(json.dumps(row, sort_keys=True) == json.dumps(record['new'], sort_keys=True) for row in current) == 1
print('PASS lossless exact raw-row ordering and unique current navigation disposition.')
