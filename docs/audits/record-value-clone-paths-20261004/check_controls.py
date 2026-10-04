"""Capture actual rejecting reader executions; require the intended native locus."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-clone-paths-20261004')
CHECKS = Path('docs/audits/record-value-clone-paths-checks-20261004')
controls = {
    'omit-call': 'every whole original structured clone call membership',
    'alias-result': 'actual complete structured clone input/result referents must be detached',
    'false-zero': 'independent reachable referents match actual input/result/shared census',
    'joint-swap': 'independent reachable referents match actual input/result/shared census',
    'wrong-kind': 'whole joint input ties original before arguments',
}
receipts = []
for flag, expected in controls.items():
    command = ['python3', '-B', str(BASE / 'verify.py'), '--' + flag]
    run = subprocess.run(command, text=True, capture_output=True)
    output = run.stdout + run.stderr
    (CHECKS / (flag + '.txt')).write_text(output)
    receipt = {'command': command, 'working_directory': '.', 'status': run.returncode, 'expected_failure': expected, 'output': output}
    (CHECKS / (flag + '-status.json')).write_text(json.dumps(receipt, sort_keys=True, indent=2) + '\n')
    assert run.returncode == 1 and output.rstrip().endswith('AssertionError: ' + expected), 'requested control must reach intended native referent/value assertion: ' + flag
    receipts.append(receipt)
(BASE / 'controls.json').write_text(json.dumps(receipts, sort_keys=True, indent=2) + '\n')
print('PASS all five controls actually reject at intended membership/joint reachable-sharing/raw input kind assertions; genuine alias native profile remains125-original-consumer green.')
