"""Retain the actual host guard stop before serial native retry at unchanged limits."""
import hashlib
import json
from pathlib import Path

CHECKS = Path('docs/audits/class-frame-publication-checks-20261006')
source = CHECKS / 'native-result.json'; raw = source.read_bytes(); actual = json.loads(raw)
assert type(actual['status']) is int and actual['status'] == 137
assert actual['stdout'] == '' and 'host memory 89.9% reached cutoff 88%' in actual['stderr']
assert 'descendant RSS cutoff 4096 MiB; poll 2s' in actual['stderr']
target = CHECKS / 'first-native-guard-result.json'; assert not target.exists()
target.write_bytes(raw); assert target.read_bytes() == raw
programme = CHECKS / 'build_native.py'; saved = CHECKS / 'first-native-programme.py.txt'; assert not saved.exists()
saved.write_bytes(programme.read_bytes()); assert saved.read_bytes() == programme.read_bytes()
proof = CHECKS / 'native-guard-stop.json'; assert not proof.exists()
proof.write_text(json.dumps(dict(actual=dict(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest()),
    programme=dict(bytes=len(saved.read_bytes()),sha256=hashlib.sha256(saved.read_bytes()).hexdigest()),
    cause='Actual host occupied memory 89.9% reached the existing 88% guard cutoff; protected PID tree terminated with137.',
    role='Terminal protected first native attempt retained; retry is serial with unchanged 88%/4096MiB/2s limits, not a duplicate live job or native success.'),sort_keys=True,indent=2) + '\n')
assert source.read_bytes() == target.read_bytes(); source.unlink()
print('PASS actual terminal native host-guard stop and whole programme retained; unchanged-limit serial retry is owned.')
