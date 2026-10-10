"""Own complete source-header qualification and typed historical boundaries."""
import hashlib
import json
from pathlib import Path

BASE=Path('docs/audits/observer-source-headers-20261011')
VALUES=Path('docs/audits/observer-source-value-acceptance-20261011')
PUBLICATION=Path('docs/audits/observer-source-value-publication-repair-20261011')
CENSUS=Path('docs/audits/observer-header-source-census-20261010')
DISPLAY=Path('docs/audits/observer-display-contract-20261010')
PREDICATE=Path('docs/audits/observer-predicate-values-20261010')
SCALAR=Path('docs/audits/observer-scalar-values-20261010')
REGEX=Path('docs/audits/observer-regex-values-20261010')
REVISION='eec7e0a8e43df9aaff82176eb05e73d862518426'
SCOPE=('Complete source-selected original own argument-header hypotheses and unchanged source-header parent acceptance only. '
       'Every full known value, source member/order/role and inherited evidence role retains. '
       'Current public displays are explicitly conditional qualified constructions; original settings/formatter/flags/encoding, '
       'reference/referent/receiver identity and private framework/eval meanings remain typed unmeasured boundaries. '
       'No scalar/prefix/wildcard substitutes for an unknown. Source do differs from diagnostic require. '
       'Original raw-header comparison, observer/raw/native/private and visual acceptance remain separately owned.')


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
    need(not path.exists(),'retain complete first source-header evidence: '+name)
    path.write_bytes(canonical(value))


def inputs():
    return [CENSUS/n for n in ('source-models.json','census.json','obligation-plan.json')] + [
        VALUES/n for n in ('product-qualified.json','contracts.json','proof.json','manifest.json')] + [
        PUBLICATION/n for n in ('proof.json','manifest.json')] + [
        DISPLAY/n for n in ('repaired-catalogue.json','repaired-hypotheses.json','repaired-native.json',
                           'repaired-joined.json','oracle_repaired.py','model_repaired.py','qualified-proof.json')] + [
        PREDICATE/n for n in ('predicate-values-qualified.json','fixture-plan-qualified.json','native-qualified.json')] + [
        SCALAR/n for n in ('scalars.json','plan.json','native.json')] + [
        REGEX/n for n in ('regexes.json','plan.json','native.json')]
