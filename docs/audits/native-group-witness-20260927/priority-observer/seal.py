#!/usr/bin/env python3
"""Retain a completed finite qualification; never launches the priority test."""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys

root = Path.cwd()
here = Path('docs/audits/native-group-witness-20260927/priority-observer')
base = Path('.artifacts/priority-native-observer')
assert len(sys.argv) == 3 and re.fullmatch('[a-z][a-z0-9_]{0,20}', sys.argv[1])
prefix, log = sys.argv[1:]
destination = here / 'evidence'
destination.mkdir()


def retain(target, data):
    path = destination / target
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('xb') as stream:
        stream.write(data)


rows = json.loads((base / f'{prefix}-results.json').read_bytes())
retain('results.json', (base / f'{prefix}-results.json').read_bytes())
retain('prove.txt', Path(log).read_bytes().replace(str(root).encode() + b'/', b''))
postcheck = []
for row in rows:
    if row['case'] == 'reuse':
        continue
    capture = row['capture']
    retain(f'{capture}-admission.json', (base / f'{capture}-admission.json').read_bytes())
    work = base / capture
    if not work.exists():
        continue
    for path in sorted(work.iterdir()):
        if path.suffix not in ('.json', '.jsonl'):
            continue
        data = path.read_bytes()
        # Stage records are already normalized and their receipt hashes must
        # remain byte-exact. Only the independent control copy needs mapping.
        if path.name == 'control-results.json':
            data = data.replace(str(root).encode() + b'/', b'')
        retain(f'{capture}/{path.name}', data)
    for item in json.loads((work / 'control-results.json').read_bytes()):
        pid = item['child']['pid']
        def absent(group):
            try:
                (os.killpg if group else os.kill)(pid, 0)
            except ProcessLookupError:
                return True
            return False
        postcheck.append({'case': row['case'], 'pid': pid, 'pid_absent': absent(False), 'group_absent': absent(True)})
assert all(row['pid_absent'] and row['group_absent'] for row in postcheck)
retain('postcheck.json', (json.dumps(postcheck, sort_keys=True) + '\n').encode())
files = [p for p in here.iterdir() if p.is_file() and p.name != 'manifest.json'] + list(destination.rglob('*'))
manifest = {'schema': 'fsmgen.fixed_priority_observer_qualification.v1', 'capture': prefix,
            'baseline_revision': subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip(),
            'helper_qualification_sha256': hashlib.sha256((here.parent / 'manifest.json').read_bytes()).hexdigest(),
            'failure_qualification_sha256': hashlib.sha256((here.parent / 'failure-only/manifest.json').read_bytes()).hexdigest(),
            'normalization': 'Exact repository prefix only in result/prove/control-result text; admissions, native events and stage receipts remain byte-exact.',
            'sha256': {str(p.relative_to(here)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(files) if p.is_file()}}
with (here / 'manifest.json').open('x') as stream:
    json.dump(manifest, stream, indent=2, sort_keys=True)
    stream.write('\n')
