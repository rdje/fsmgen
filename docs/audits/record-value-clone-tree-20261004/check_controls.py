"""Retain actual reached recursive membership/source/product/topology REDs."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-clone-tree-20261004')
CHECKS = Path('docs/audits/record-value-clone-tree-checks-20261004')
messages = {
    'omit-call': 'every original recursive clone operation membership',
    'omit-key': 'whole recursive clone source product keys/order/primitive kinds/context',
    'array-order': 'whole recursive clone source product keys/order/primitive kinds/context',
    'dfs-order': 'independent full source path parent and DFS allocation',
    'wrong-caller': 'exact root versus hash/array recursive caller',
    'same-source': 'exact recursive own source root despite equal values',
    'numeric-kind': 'whole recursive clone source product keys/order/primitive kinds/context',
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
    assert run.returncode == 1 and output.rstrip().endswith('AssertionError: ' + message), 'requested control must reach intended source/native assertion: ' + flag
    receipts.append(receipt)
(BASE / 'controls.json').write_text(json.dumps(receipts, sort_keys=True, indent=2) + '\n')
print('PASS all eight recursive clone controls reject reached membership/key/array-order/DFS/caller/identical-value source/raw-kind/genuine native alias defects at intended assertions.')
