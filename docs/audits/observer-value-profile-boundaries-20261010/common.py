"""Owned remaining-value/profile boundary evidence and append-once storage."""
import hashlib
import json
from pathlib import Path

BASE=Path('docs/audits/observer-value-profile-boundaries-20261010')
CENSUS=Path('docs/audits/observer-header-source-census-20261010')
PREDICATE=Path('docs/audits/observer-predicate-values-20261010')
SCALAR=Path('docs/audits/observer-scalar-values-20261010')
REGEX=Path('docs/audits/observer-regex-values-20261010')
REPAIR=Path('docs/audits/observer-regex-publication-repair-20261010')
PUBLIC=Path('docs/audits/record-value-public-boundary-join-20261006/proofs.json')
RAW=Path('docs/audits/record-value-original-raw-20261005/proofs.json')
REVISION='80b3aad7f0011c9b341c83e5069febed24acd73c'
SCOPE=('Complete original remaining-value parent and source-obligation/profile-boundary join only. '
       'Known complete source values and finite current public constructions retain their qualified roles; '
       'inherited inner operands remain dated evidence. Original flags/settings/formatter, identities/referents/receivers '
       'and private/eval intervals stay genuinely unmeasured; source do differs from diagnostic require. '
       'No higher source-value, full-header, observer or raw-stack parent closes.')


def need(condition,cause):
    if not condition:
        raise ValueError(cause)


def canonical(value):
    return (json.dumps(value,sort_keys=True,separators=(',',':'),ensure_ascii=True,allow_nan=False)+'\n').encode()


def pin(raw):
    return dict(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())


def read(path):
    return json.loads(path.read_bytes())


def load(name):
    return read(BASE/name)


def same(left,right):
    return canonical(left)==canonical(right)


def save(name,value):
    path=BASE/name
    need(not path.exists(),'retain complete first evidence: '+name)
    path.write_bytes(canonical(value))


def module(path):
    namespace={'__name__':'value_boundary_dependency','__file__':str(path)}
    exec(compile(path.read_bytes(),str(path),'exec'),namespace)
    return namespace
