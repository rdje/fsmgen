"""Retain reached whole clone join omission/allocation/kind/alias controls."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-clone-join-20261004')
CHECKS = Path('docs/audits/record-value-clone-join-checks-20261004')
messages = {
    'omit-call': 'complete original clone joined membership',
    'same-native': 'exact own original native/source slot despite identical full records',
    'wrong-root': 'exact own complete source root and parent allocation',
    'numeric-kind': 'whole joined source product primitive kinds and every field',
    'alias-result': 'actual complete structured clone input/result referents must be detached',
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
    assert run.returncode == 1 and output.rstrip().endswith('AssertionError: ' + message), 'requested clone join control must reach intended assertion: ' + flag
    receipts.append(receipt)
(BASE / 'controls.json').write_text(json.dumps(receipts, sort_keys=True, indent=2) + '\n')
print('PASS all five whole clone join controls reject reached omission/identical-record native permutation/source-root/raw-kind/genuine alias defects at intended assertions.')
