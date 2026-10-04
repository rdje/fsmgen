"""Retain actually reached whole core membership/allocation/kind/private REDs."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-core-join-20261004')
CHECKS = Path('docs/audits/record-value-core-join-checks-20261004')
messages = {
    'omit-call': 'complete original core joined membership',
    'same-model': 'exact own core source model despite identical whole native values',
    'wrong-family': 'exact native core role/completed source model family',
    'numeric-product': 'complete core source-modeled product primitive kinds',
    'omit-private': 'all own core source/private/field/handoff/stage links retain',
}
receipts = []
for flag, message in messages.items():
    command = ['python3', '-B', str(BASE / 'verify.py'), '--' + flag]
    run = subprocess.run(command, text=True, capture_output=True)
    output = run.stdout + run.stderr
    receipt = {'command': command, 'working_directory': '.', 'status': run.returncode,
        'expected_failure': message, 'output': output}
    (CHECKS / (flag + '.txt')).write_text(output)
    (CHECKS / (flag + '-status.json')).write_text(json.dumps(receipt, sort_keys=True, indent=2) + '\n')
    assert run.returncode == 1 and output.rstrip().endswith('AssertionError: ' + message), 'requested core control must reach intended assertion: ' + flag
    receipts.append(receipt)
(BASE / 'controls.json').write_text(json.dumps(receipts, sort_keys=True, indent=2) + '\n')
print('PASS all five core join controls reject reached omission/identical-native model allocation/family/primitive/private defects at intended assertions.')
