"""Execute real ordinary/bad-provider probe modes with complete receipts."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-copy-probes-20261004')
CHECKS = Path('docs/audits/record-value-copy-probes-checks-20261004')
receipts = []
for mode in ('ordinary', 'storable', 'alias', 'split-sharing', 'cycle-alias', 'mutate-input', 'numeric-result'):
    command = ['perl', str(BASE / 'probe.pl'), mode, str(BASE / (mode + '.json'))]
    run = subprocess.run(command, text=True, capture_output=True)
    output = run.stdout + run.stderr
    receipt = {'command': command, 'working_directory': '.', 'status': run.returncode,
        'output': output, 'programs': {name: {'bytes': (BASE / name).stat().st_size,
            'sha256': hashlib.sha256((BASE / name).read_bytes()).hexdigest()}
            for name in ('probe.pl', 'candidate.pl')}}
    (CHECKS / (mode + '-native.txt')).write_text(output)
    (CHECKS / (mode + '-native-status.json')).write_text(json.dumps(receipt, sort_keys=True, indent=2) + '\n')
    receipts.append(receipt)
    assert run.returncode == 0 if mode == 'ordinary' else run.returncode > 0, mode + ': ' + output
(BASE / 'native-receipts.json').write_text(json.dumps(receipts, sort_keys=True, indent=2) + '\n')
print('PASS actual ordinary and six bad-provider modes executed, with whole TAP/status/program receipts retained.')
