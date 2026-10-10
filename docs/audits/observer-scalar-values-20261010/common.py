"""Data-only identities and append-once evidence for the owned scalar slice."""
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/observer-scalar-values-20261010')
CENSUS = Path('docs/audits/observer-header-source-census-20261010')
PREDICATE = Path('docs/audits/observer-predicate-values-20261010')
REVISION = 'fa40d54b364b9afa87342de0084f2ed8e9214794'
SCOPE = ('Complete source scalar values and selected current public scalar constructors only. '
         'Inherited serialized inner operands retain their dated evidence role; they are not '
         'a new independent semantic header oracle. Original scalar flags, formatter/settings, '
         'reference/receiver/referent identity, private framework intervals and do/require '
         'roles remain unchanged. Regex, full original headers and parent acceptance stay open.')


def need(condition, cause):
    if not condition:
        raise ValueError(cause)


def canonical(value):
    return (json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True,
                       allow_nan=False) + '\n').encode()


def same(left, right):
    return canonical(left) == canonical(right)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def read(path):
    return json.loads(path.read_bytes())


def load(name):
    return read(BASE / name)


def save(name, value):
    path = BASE / name
    need(not path.exists(), 'retain first complete evidence: ' + name)
    path.write_bytes(canonical(value))


def module(path):
    namespace = {'__name__': 'scalar_source_dependency', '__file__': str(path)}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace
