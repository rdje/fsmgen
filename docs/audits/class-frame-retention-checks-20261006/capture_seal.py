"""Bind the actual complete retention seal to every whole sealed member."""
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-retention-20261006')
CHECKS = Path('docs/audits/class-frame-retention-checks-20261006')
source = CHECKS / 'seal-command.json'; actual = json.loads(source.read_text())
assert type(actual['status']) is int and actual['status'] == 0
assert actual['command'] == ['scripts/run_with_ram_guard.sh','--','python3','-B',str(BASE / 'verify.py'),'--seal']
pins = {}
for path in BASE.rglob('*'):
    if path.is_file():
        assert not path.is_symlink() and path.stat().st_dev == Path.cwd().stat().st_dev
        raw = path.read_bytes(); pins[str(path.relative_to(BASE))] = dict(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())
assert 'manifest.json' in pins
actual['whole_members'] = pins
raw = source.read_bytes(); actual['actual_result_identity'] = dict(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())
target = CHECKS / 'sealed-replay.json'; assert not target.exists()
target.write_text(json.dumps(actual,sort_keys=True,indent=2) + '\n')
print('PASS actual complete retention seal bound to every whole root-relative member and original process result.')
