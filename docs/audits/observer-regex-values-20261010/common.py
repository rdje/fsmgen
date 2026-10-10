"""Owned regex evidence identity, closed scope and append-once storage."""
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/observer-regex-values-20261010')
SCALAR = Path('docs/audits/observer-scalar-values-20261010')
CENSUS = Path('docs/audits/observer-header-source-census-20261010')
AUTHORITY = Path('docs/audits/record-value-original-observer-sources-20261005/proofs.json')
REVISION = '5c560fba3d64d04560b0d8736e35e6ef970b651c'
SCOPE = ('Complete authored regex expressions, pattern characters, absent authored modifiers and source allocation; '
         'finite selected current public literal/byte/upgraded constructors and explicit display profiles only. '
         'Original native regex flags/encoding, Regexp/provider/reference identity and formatter/settings remain '
         'unmeasured; full original headers, original raw join and all parent acceptance remain open.')


def need(condition, cause):
    if not condition:
        raise ValueError(cause)


def canonical(value):
    return (json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True, allow_nan=False)+'\n').encode()


def same(left, right):
    return canonical(left) == canonical(right)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def read(path):
    return json.loads(path.read_bytes())


def load(name):
    return read(BASE/name)


def save(name, value):
    path = BASE/name
    need(not path.exists(), 'retain complete first evidence: '+name)
    path.write_bytes(canonical(value))


def module(path):
    namespace = {'__name__': 'regex_source_dependency', '__file__': str(path)}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace
