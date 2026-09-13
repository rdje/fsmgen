"""Load qualified data readers; never invoke a lifecycle or producer main."""
from pathlib import Path
import hashlib
import json
import sys

sys.dont_write_bytecode = True
BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
H = ROOT / 'docs/audits/native-proxy-lifetime-control-harness-20260913'
B = ROOT / 'docs/audits/native-proxy-lifetime-files-20260913'
M = ROOT / 'docs/audits/native-proxy-lifetime-controls-admission-20260913'
sys.path.insert(0, str(H))
import consume_controls as reader
from support_controls import CONSUME as C, stable


def read(path):
    return json.loads(path.read_bytes())


def pin(path):
    body = path.read_bytes()
    return dict(path=path.relative_to(ROOT).as_posix(), size_bytes=len(body),
                sha256=hashlib.sha256(body).hexdigest())


def write(path, value):
    with path.open('xb') as stream:
        stream.write(json.dumps(value, sort_keys=True, indent=2, allow_nan=False).encode() + b'\n')


def record(number):
    return read(B / 'records' / ('event-%06d.json' % number))
