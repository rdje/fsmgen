"""Preserve every raw row while restoring the candidate-ID registry order."""
import json
from pathlib import Path

BASE = Path('docs/audits/book-reference-disposition-order-20261005')
REGISTRY = Path('doctrine/claim_verification/dispositions.jsonl')
before = REGISTRY.read_bytes()
assert not (BASE / 'before.jsonl').exists()
assert before == Path('docs/audits/book-reference-disposition-refresh-20261005/registry-after.jsonl').read_bytes()
lines = before.splitlines(keepends=True)
assert json.loads(lines[0])['record_type'] == 'registry'
after = lines[0] + b''.join(sorted(lines[1:], key=lambda line: json.loads(line)['candidate_id']))
assert before != after
(BASE / 'before.jsonl').write_bytes(before)
(BASE / 'after.jsonl').write_bytes(after)
REGISTRY.write_bytes(after)
print('PASS raw registry header and every complete row retained; refreshed candidate moved into canonical order.')
