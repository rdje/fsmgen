"""Capture actually reached whole root source/allocation/kind rejections."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-clone-root-20261004')
CHECKS = Path('docs/audits/record-value-clone-root-checks-20261004')
messages = {'omit-root': 'every complete original root membership',
    'wrong-role': 'independent complete root source role',
    'same-type-source': 'exact own source parent despite identical type values',
    'numeric-preparation': 'whole source root raw preparation primitive kinds'}
receipts = []
for flag, message in messages.items():
    command = ['python3', '-B', str(BASE / 'verify.py'), '--' + flag]
    run = subprocess.run(command, text=True, capture_output=True)
    output = run.stdout + run.stderr
    receipt = {'command': command, 'working_directory': '.', 'status': run.returncode, 'expected_failure': message, 'output': output}
    (CHECKS / (flag + '.txt')).write_text(output)
    (CHECKS / (flag + '-status.json')).write_text(json.dumps(receipt, sort_keys=True, indent=2) + '\n')
    assert run.returncode == 1 and output.rstrip().endswith('AssertionError: ' + message), 'requested root control must reach its intended source assertion: ' + flag
    receipts.append(receipt)
(BASE / 'controls.json').write_text(json.dumps(receipts, sort_keys=True, indent=2) + '\n')
print('PASS all four root controls reject complete source membership/role/identical-type source-parent/raw preparation kind at intended assertions.')
