"""Retain reached source/strict/payload/raw-kind reader rejections."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-identities-20261004')
CHECKS = Path('docs/audits/record-value-identities-checks-20261004')
messages = {
    'omit-call': 'all original strict identity/payload membership',
    'trust-width': 'independent complete type identity versus narrower payload product',
    'strict-payload': 'independent complete type identity versus narrower payload product',
    'same-source': 'exact own source/copy parent despite identical type arguments',
    'numeric-kind': 'whole original source/private argument primitive kinds',
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
    assert run.returncode == 1 and output.rstrip().endswith('AssertionError: ' + message), 'requested identity/payload control must reach intended assertion: ' + flag
    receipts.append(receipt)
(BASE / 'controls.json').write_text(json.dumps(receipts, sort_keys=True, indent=2) + '\n')
print('PASS all five identity/payload controls reject reached omission/width-only/strict-payload/identical-argument source/raw-kind defects at intended assertions.')
