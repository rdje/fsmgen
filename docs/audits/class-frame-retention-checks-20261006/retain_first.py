"""Preserve and verify exact first draft/programme bytes before supersession."""
import hashlib
import json
from pathlib import Path

root = Path('docs/audits/record-value-class-frame-retention-20261006')
checks = Path('docs/audits/class-frame-retention-checks-20261006')
assert not (root / 'manifest.json').exists()
pins = {}
for name in ('prepare.py','proposal.json','retention-map.json'):
    source = root / name
    destination = checks / ('first-' + name + ('.txt' if name.endswith('.py') else ''))
    assert source.is_file() and not source.is_symlink() and source.stat().st_dev == checks.stat().st_dev == Path.cwd().stat().st_dev
    assert not destination.exists()
    raw = source.read_bytes(); destination.write_bytes(raw)
    assert destination.read_bytes() == raw
    pins[str(destination)] = dict(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())
record = json.loads((checks / 'first-budget.json').read_text())
assert type(record['status']) is int and record['status'] == 1
assert record['stderr'].endswith('AssertionError: complete retention proposal must not grow bytes or LF\n')
output = checks / 'first-retention.json'; assert not output.exists()
output.write_text(json.dumps(dict(members=pins,first_budget=record,role='Exact first unsealed draft and invocation programme retained before supersession; no original/live source is altered.'),sort_keys=True,indent=2) + '\n')
for name in ('proposal.json','retention-map.json'):
    source = root / name; retained = checks / ('first-' + name)
    assert source.read_bytes() == retained.read_bytes()
    source.unlink()
print('PASS exact first programme/proposal/map retained and verified before superseding unsealed products.')
