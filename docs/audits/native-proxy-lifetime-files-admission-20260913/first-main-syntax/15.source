"""Repository-derived inputs and explicitly isolated imports of pure helpers."""
from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys

sys.dont_write_bytecode = True
BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name
MODEL = ROOT / 'docs/audits/native-proxy-lifetime-model-20260913'
CONTRACT = ROOT / 'docs/audits/native-proxy-lifetime-contracts-20260913'


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


OLD_COMMON = load('lifetime_files_model_common', MODEL / 'common.py')
# The original model imports a generic common name. Bind that exact original
# dependency only while loading it; never let it capture an unrelated module.
_missing = object()
_previous = sys.modules.get('common', _missing)
try:
    sys.modules['common'] = OLD_COMMON
    OLD_MODEL = load('lifetime_files_original_model', MODEL / 'model.py')
finally:
    if _previous is _missing:
        sys.modules.pop('common', None)
    else:
        sys.modules['common'] = _previous


def canonical(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=True, separators=(',', ':'), allow_nan=False).encode('ascii')


def digest(value):
    return hashlib.sha256(canonical(value)).hexdigest()


def document(path):
    return json.loads(path.read_bytes())


def write(path, value):
    with path.open('xb') as handle:
        handle.write(json.dumps(value, sort_keys=True, ensure_ascii=True, indent=2, allow_nan=False).encode() + b'\n')


def pin(path):
    path = Path(path)
    relative = str(path.relative_to(ROOT)) if path.is_absolute() else str(path)
    body = (ROOT / relative).read_bytes()
    return dict(path=relative, size_bytes=len(body), sha256=hashlib.sha256(body).hexdigest())


def authenticate(plan, pins):
    for row in plan['inputs'] + pins:
        assert pin(row['path']) == row, row['path']
    for row in plan['inputs']:
        body = subprocess.check_output(['git', 'show', plan['source_revision'] + ':' + row['path']], cwd=ROOT)
        assert body == (ROOT / row['path']).read_bytes(), row['path']
