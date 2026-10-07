"""Probe the historical reader's actual current predicate without recapture."""
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-publication-20261006')
ns = {'__name__': 'current_epoch_probe', '__file__': str(BASE / 'verify.py')}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
for name, pin in json.loads((BASE / 'manifest.json').read_bytes()).items():
    raw = (BASE / name).read_bytes()
    assert pin == {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}, name
snapshot = ns['load'](BASE / 'publication.json')['snapshot']
ns['check_current'](snapshot)
actual = ns['current_input']()
try:
    ns['check_current'](actual)
except ValueError as error:
    assert str(error) == 'whole current physical member and non-target source conservation', str(error)
    result = {'status': 0, 'snapshot': 'passed', 'live_extension': 'refused', 'cause': str(error),
              'scope': 'Actual historical current predicate and current source/query input. No original capture or whole semantic reader replay.'}
else:
    raise AssertionError('expected current epoch coupling did not reproduce')
print(json.dumps(result, sort_keys=True))
