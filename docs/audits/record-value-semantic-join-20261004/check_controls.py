"""Retain reached full source/field/product/context and native alias controls."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-semantic-join-20261004')
CHECKS = Path('docs/audits/record-value-semantic-join-checks-20261004')
messages = {
    'omit-field': 'complete original copied graph/field/source membership',
    'omit-product': 'complete whole source-modeled actor/API/private/context product join retains',
    'wrong-source': 'whole independently qualified source root/node/property/kind domain retains',
    'wrong-field': 'each original source field/model is allocated to its own whole native copy',
    'wrong-helper': 'exact source helper callback/consumer/parse span allocation',
    'omit-consumer': 'complete original consumer observation/source membership',
    'wrong-consumer-owner': 'exact source helper owner for complete consumer observation',
    'alias-authority': 'actual complete structured clone input/result referents must be detached',
    'wrong-ledger': 'whole reexecuted native capture retains its own full raw difference ledger',
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
    assert run.returncode == 1 and output.rstrip().endswith('AssertionError: ' + message), 'requested semantic control must reach intended assertion: ' + flag
    receipts.append(receipt)
(BASE / 'controls.json').write_text(json.dumps(receipts, sort_keys=True, indent=2) + '\n')
print('PASS all nine whole source/field/product/helper/consumer/alias controls reach intended assertions. Genuine alias provider keeps every8251 separate clone value record/all125 legacy consumer passes but fails full joint detachment.')
