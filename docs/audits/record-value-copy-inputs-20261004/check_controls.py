"""Retain actual legacy-copy, population and source-authority rejections."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-copy-inputs-20261004')
CHECKS = Path('docs/audits/record-value-copy-inputs-checks-20261004')
messages = {
    'omit-copy': 'every original whole test-copy input/source/field record retains',
    'legacy-authority': 'actual original Storable copy cannot be kind-preserving baseline authority',
    'wrong-model': 'whole own source/field/native semantic assignment retains',
    'wrong-recipe': 'exact named existing plain copy/snapshot/identity recipe source authority',
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
print('PASS all four whole input/actual legacy/source-model/recipe authority controls reach intended RED1 assertions.')
