"""Add complete sealed-member identity to an untouched actual command receipt."""
import json
import runpy
from pathlib import Path

CHECKS = Path('docs/audits/public-boundary-retention-checks-20261006')
reader = runpy.run_path(str(CHECKS / 'verify_seal.py'))
record = reader['load'](CHECKS / 'seal-command.json')
record['whole_members'] = reader['members']()
record['actual_result_identity'] = reader['identity']((CHECKS / 'seal-command.json').read_bytes())
reader['header'](record)
output = CHECKS / 'sealed-replay.json'
assert not output.exists()
output.write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
print('PASS whole actual result and sealed-member capture; raw receipt unchanged.')
