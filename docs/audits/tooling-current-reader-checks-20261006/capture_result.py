"""Bind the actual completed command to every immutable reader member."""
from pathlib import Path
import json

CHECKS = Path('docs/audits/tooling-current-reader-checks-20261006')
path = CHECKS / 'verify_seal.py'
ns = {'__name__': 'tooling_capture', '__file__': str(path)}
exec(compile(path.read_bytes(), str(path), 'exec'), ns)
raw_path = CHECKS / 'seal-command.json'
receipt = ns['load'](raw_path)
receipt.update(actual_result_identity=ns['identity'](raw_path.read_bytes()), whole_members=ns['whole_members']())
ns['header'](receipt)
output = CHECKS / 'sealed-replay.json'; assert not output.exists()
output.write_text(json.dumps(receipt, sort_keys=True, indent=2) + '\n')
print('PASS actual tooling current result and every whole member bound.')
