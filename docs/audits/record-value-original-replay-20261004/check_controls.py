"""Retain actual input and genuine source/owner authority rejections."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-replay-20261004')
CHECKS = Path('docs/audits/record-value-original-replay-checks-20261004')
messages = {
    'omit-input': 'complete pinned original source/task input membership',
    'trust-decoy': 'whole original source bodies cannot borrow actual decoy authority',
    'wrong-owner': 'whole pinned task bodies retain exact completed owner authority',
}
receipts = []
for flag, message in messages.items():
    command = ['python3', '-B', str(BASE / 'verify.py'), '--' + flag]
    run = subprocess.run(command, text=True, capture_output=True)
    output = run.stdout + run.stderr
    receipt = {'command': command, 'working_directory': '.', 'status': run.returncode,
        'output': output, 'expected_failure': message}
    (CHECKS / (flag + '.txt')).write_text(output)
    (CHECKS / (flag + '-status.json')).write_text(json.dumps(receipt, sort_keys=True, indent=2) + '\n')
    assert run.returncode == 1 and output.rstrip().endswith('AssertionError: ' + message), output
    receipts.append(receipt)
(BASE / 'controls.json').write_text(json.dumps(receipts, sort_keys=True, indent=2) + '\n')
print('PASS all three actual pinned input/source/owner authority controls reach their intended RED1 assertions.')
