"""Bind the untouched actual seal process to every full relative member."""
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-join-20261006')
CHECKS = Path('docs/audits/class-frame-join-checks-20261006')
ns = {'__name__': 'capture_actual_class_frame_seal', '__file__': str(BASE / 'verify.py')}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
receipt = ns['load'](CHECKS / 'seal-command.json')
assert type(receipt['status']) is int and receipt['status'] == 0
assert receipt['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / 'verify.py'), '--seal']
assert receipt['stdout'] == ns['SUCCESS']
assert ns['same'](ns['load'](BASE / 'manifest.json'), ns['members']())
receipt['whole_members'] = {str(Path(p).relative_to(BASE)):pin for p, pin in ns['whole'](BASE).items()}
receipt['actual_result_identity'] = ns['identity']((CHECKS / 'seal-command.json').read_bytes())
path = CHECKS / 'sealed-replay.json'; assert not path.exists()
path.write_text(json.dumps(receipt, sort_keys=True, indent=2) + '\n')
print('PASS untouched actual class/frame seal process and complete relative member binding.')
