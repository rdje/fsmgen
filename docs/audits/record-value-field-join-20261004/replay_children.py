"""Reexecute immutable readers with their exact dated document after-images."""
import hashlib
import argparse
import json
import os
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
parser.add_argument('--check', action='store_true')
args = parser.parse_args()
ROOT = Path.cwd()
data = json.loads((BASE / 'join.json').read_text())
checks = Path('docs/audits/record-value-field-join-checks-20261004')
checks.mkdir(exist_ok=True)
receipts = []
for child, flags in [
    (data['children'][0], ['--omit-type', '--swap-order', '--trust-private-product']),
    (data['children'][1], ['--omit-field', '--swap-source-role', '--trust-private-product', '--swap-malformed-model'])]:
    archive = child['archive']
    directory = Path('docs/audits') / archive
    fixture = Path('.artifacts/record-value-field-join-replay-20261004') / archive
    fixture.mkdir(parents=True, exist_ok=True)
    for path, source in data['sources'].items():
        target = fixture / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(source['body'])
    historical = {'docs/knowledge/isf-aggregate-port-request-baseline.md': (directory / 'card-after.txt').read_text()}
    if (directory / 'doc-updates.json').exists():
        historical.update({row['path']: row['after'] for row in json.loads((directory / 'doc-updates.json').read_text())})
    for path, body in historical.items():
        (fixture / path).write_text(body)
    link = fixture / 'docs/audits'
    expected_link = os.path.relpath(ROOT / 'docs/audits', ROOT / fixture / 'docs')
    if link.is_symlink():
        assert os.readlink(link) == expected_link
    else:
        assert not link.exists()
        link.symlink_to(expected_link, target_is_directory=True)
    inputs = {}
    for path in data['sources']:
        raw = (fixture / path).read_bytes()
        expected = historical.get(path, data['sources'][path]['body']).encode()
        assert raw == expected
        inputs[path] = {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest(),
            'boundary': 'sealed document after-image' if path in historical else 'current committed source'}
    for flag in [None] + flags:
        command = ['python3', '-B', str(directory / 'verify.py')] + ([flag] if flag else [])
        run = subprocess.run(command, cwd=fixture, text=True, capture_output=True)
        expected_status = 1 if flag else 0
        name = archive + '-' + (flag.removeprefix('--') if flag else 'ordinary')
        if not args.check:
            (checks / (name + '.txt')).write_text(run.stdout + run.stderr)
        receipt = {'archive': archive, 'command': command, 'working_directory': str(fixture),
            'inputs': inputs, 'status': run.returncode, 'expected_status': expected_status,
            'output': run.stdout + run.stderr}
        receipts.append(receipt)
        print(name, run.returncode)
        assert run.returncode == expected_status
if args.check:
    assert receipts == json.loads((BASE / 'child-replays.json').read_text()), 'complete reader/control replay identity and outcomes'
else:
    (BASE / 'child-replays.json').write_text(json.dumps(receipts, sort_keys=True, indent=2) + '\n')
print('PASS both immutable semantic readers and all seven child falsifiers at exact source/document boundaries; current source/body join is separate.')
