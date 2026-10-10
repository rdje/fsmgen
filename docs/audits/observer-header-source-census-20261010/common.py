"""Own finite source-census constants and data-only helpers."""
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/observer-header-source-census-20261010')
DISPLAY = Path('docs/audits/observer-display-contract-20261010')
SOURCE = Path('docs/audits/record-value-class-frame-join-20261006')
REVISION = '60791d20a69e2d93572c74aac9c6c64982077cd0'
ROLE = ('Complete dated source-role and exact-header prerequisite census only; no '
        'original trace display is a new semantic oracle. Full source headers, original '
        'raw join and observer publication remain pending. Original settings, native '
        'scalar flags, reference/regex/provider identity and private framework semantics '
        'remain unmeasured; inherited serialized inner operands retain their evidence role.')
READERS = {
    'own-source-chain': ['docs/audits/record-value-parser-context-join-20261006/verify.py'],
    'public-documentation': ['docs/audits/record-value-public-framework-profile-20261006/verify.py'],
    'public-fixtures': ['docs/audits/record-value-public-native-fixtures-20261006/verify.py'],
    'public-boundary': ['docs/audits/record-value-public-boundary-join-20261006/verify.py', '--checkpoint-prerequisites'],
    'class-frame': [str(SOURCE / 'verify.py')],
    'public-display': [str(DISPLAY / 'verify.py')],
}


def need(ok, cause):
    if not ok:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def load(name):
    return json.loads((BASE / name).read_bytes())


def canonical(value):
    return (json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True) + '\n').encode()


def same(a, b):
    return canonical(a) == canonical(b)


def save(name, value):
    path = BASE / name
    need(not path.exists(), 'retain first complete product: ' + name)
    path.write_bytes(canonical(value))


def module(path):
    ns = {'__name__': 'source_census_dependency', '__file__': str(path)}
    exec(compile(path.read_bytes(), str(path), 'exec'), ns)
    return ns
