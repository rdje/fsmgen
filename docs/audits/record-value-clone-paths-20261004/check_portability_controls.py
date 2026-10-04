"""Run exact command/filename/cause/root-text rejection controls sequentially."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-clone-paths-20261004')
CHECKS = Path('docs/audits/record-value-clone-paths-checks-20261004')
predicates = {'absolute-command': 'every stored control command is repository-relative and names the exact current reader',
    'wrong-file': 'exact bound main/imported native module filename coordinate',
    'wrong-cause': 'complete actual semantic/control output beyond only exact program filenames',
    'root-echo': 'complete actual semantic/control output beyond only exact program filenames'}
receipts = []
for flag, message in predicates.items():
    command = ['python3', '-B', str(BASE / 'portability.py'), '--' + flag]
    run = subprocess.run(command, text=True, capture_output=True)
    output = run.stdout + run.stderr
    receipt = {'command': command, 'working_directory': '.', 'status': run.returncode, 'expected_failure': message, 'output': output}
    (CHECKS / (flag + '.txt')).write_text(output)
    (CHECKS / (flag + '-status.json')).write_text(json.dumps(receipt, sort_keys=True, indent=2) + '\n')
    assert run.returncode == 1 and output.rstrip().endswith('AssertionError: ' + message), 'requested portability control must reach intended assertion: ' + flag
    receipts.append(receipt)
(BASE / 'portability-controls.json').write_text(json.dumps(receipts, sort_keys=True, indent=2) + '\n')
print('PASS actual original absolute command, wrong program filename, wrong cause and root-bearing semantic text reject at intended portable boundaries.')
