"""Own finite source-census constants and data-only helpers."""
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/observer-predicate-values-20261010')
PRIOR = Path('docs/audits/observer-header-source-census-20261010')
DISPLAY = Path('docs/audits/observer-display-contract-20261010')
SOURCE = Path('docs/audits/record-value-class-frame-join-20261006')
REVISION = '6715ce66cf7b8a63c3a7f3125d722b578b29ad87'
ROLE = ('Complete finite source-predicate value qualification and current source-neutral '
        'public constructor/display fixtures only; no original trace display is a new '
        'semantic oracle or original execution recapture. Original native scalar flags, '
        'formatter/settings/provider/identity/private meanings remain unmeasured. '
        'Remaining scalars/regex values, full source headers and original joining stay open.')
READERS = {
    'own-source-chain': ['docs/audits/record-value-parser-context-join-20261006/verify.py'],
    'public-documentation': ['docs/audits/record-value-public-framework-profile-20261006/verify.py'],
    'public-fixtures': ['docs/audits/record-value-public-native-fixtures-20261006/verify.py'],
    'public-boundary': ['docs/audits/record-value-public-boundary-join-20261006/verify.py', '--checkpoint-prerequisites'],
    'class-frame': [str(SOURCE / 'verify.py')],
    'public-display': [str(DISPLAY / 'verify.py')],
    'source-census': [str(PRIOR / 'verify.py')],
    'census-obligations': [str(PRIOR / 'obligations_verify.py')],
    'census-publication': [str(PRIOR / 'publication_verify_final.py')],
    'census-book': [str(PRIOR / 'book.py'), '--verify'],
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
