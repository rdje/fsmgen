#!/usr/bin/env python3
"""Seal portable source-only evidence; retain raw epoch bytes before projection.

The sole epoch edit is its own script-input label. Full observed payloads and
captured script texts stay exact. Raw copies are diagnostic only; tracked
portable products retain all functional evidence without checkout dependence.
"""
import gzip
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path.cwd().resolve()
BASE = Path('.artifacts/nested-normalization-20261022/qualified')
AUDIT = Path('docs/audits')
RECIPE = 'docs/audits/nested-normalization-qualification-20261022.py'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def packed(value):
    return gzip.compress((json.dumps(value, sort_keys=True, indent=2) + '\n').encode(), mtime=0)


projections = {}
for epoch in ('before', 'after'):
    path = AUDIT / f'nested-normalization-{epoch}-20261022.json.gz'
    raw = path.read_bytes()
    value = json.loads(gzip.decompress(raw))
    if RECIPE in value['inputs']:
        raise ValueError('epoch already portable; do not reseal or overwrite evidence')
    old_label = str(ROOT / RECIPE)
    if set(k for k in value['inputs'] if k.startswith('/')) != {old_label}:
        raise ValueError('unexpected absolute input labels')
    raw_path = BASE / 'raw' / path.name
    raw_path.parent.mkdir(exist_ok=True)
    with raw_path.open('xb') as stream:
        stream.write(raw)
    if raw_path.read_bytes() != raw:
        raise ValueError('raw copy differs')
    value['inputs'][RECIPE] = value['inputs'].pop(old_label)
    projected = packed(value)
    # Prove the projection changes the one declared label only.
    restored = json.loads(gzip.decompress(projected))
    restored['inputs'][old_label] = restored['inputs'].pop(RECIPE)
    if restored != json.loads(gzip.decompress(raw)):
        raise ValueError('projection changed more than its declared input label')
    temporary = BASE / (path.name + '.portable')
    with temporary.open('xb') as stream:
        stream.write(projected)
    temporary.replace(path)
    projections[str(path)] = {'raw_sha256': sha(raw), 'portable_sha256': sha(projected),
                             'operation': 'Replace only the checkout-absolute recipe input label with RECIPE.'}

logs = {}
for name in ('red.log', 'red-qualified.log', 'green.log', 'native-before.log',
             'native-after.log', 'preservation.log', 'origins.log', 'book.log', 'pressure.log'):
    path = BASE / name
    # The original sandbox refusal is outside the corrected fixture epoch.
    if name == 'red.log':
        path = BASE.parent / name
    raw = path.read_bytes()
    logs[name] = {'raw_sha256': sha(raw), 'text': raw.decode().replace(str(ROOT), '<repo>')}
for name in ('green.log', 'preservation.log', 'origins.log'):
    if 'All tests successful.' not in logs[name]['text'] or 'Result: PASS' not in logs[name]['text']:
        raise ValueError('required test result not green: ' + name)
inputs = {}
for name in ('perl/FSM/Adapter/ISF/LispishAdapter.pm', 't/1092-isf-lispish-adapter.t',
             't/2097-isf-nested-aggregate-normalization.t', RECIPE,
             'docs/audits/nested-normalization-knowledge-verify-20261022.py',
             'docs/audits/nested-normalization-seal-20261022.py'):
    raw = Path(name).read_bytes()
    inputs[name] = {'sha256': sha(raw), 'text': raw.decode()}
record = {'owner': 'ISF-REDUCTION-DELIVERY.2.3.2.1.2.2',
          'baseline_revision': subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode().strip(),
          'scope': 'Completed source-only fixed regression, native controls, library-origin and focused preservation tests, and book build. Initial fixture/pressure failures remain retained. Staged doctrines and normal hooks qualify the later commit separately; no external HDL or generic specialization claim.',
          'projections': projections, 'inputs': inputs, 'logs': logs}
with (AUDIT / 'nested-normalization-validation-20261022.json.gz').open('xb') as stream:
    stream.write(packed(record))
print('nested normalization evidence sealed; exact raw bytes retained before label-only portable projection')
