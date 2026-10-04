"""Capture reached full actor/API/source/private/parse product controls."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-products-20261004')
CHECKS = Path('docs/audits/record-value-products-checks-20261004')
messages = {
    'omit-actor': 'complete original actor/parse product membership',
    'omit-call': 'complete original actor/value/core API product membership',
    'same-model': 'exact own source/completed join allocation despite identical native values',
    'wrong-family': 'exact original API source family and operation role',
    'omit-private': 'complete original own private clone/field product membership',
    'numeric-product': 'complete original source-modeled API product primitive kinds',
    'trust-private-actor': 'whole source actor product with original primitive kinds, not private-copy authority',
    'wrong-parse': 'exact source parse/outcome/bounds allocation for every nested API',
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
    assert run.returncode == 1 and output.rstrip().endswith('AssertionError: ' + message), 'requested product control must reach intended assertion: ' + flag
    receipts.append(receipt)
(BASE / 'controls.json').write_text(json.dumps(receipts, sort_keys=True, indent=2) + '\n')
print('PASS all eight actor/API product controls reach intended omission/identical-native allocation/family/private/kind/genuine private-actor/parse assertions.')
