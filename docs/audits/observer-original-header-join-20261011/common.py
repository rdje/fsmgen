"""Own complete source-header qualification and typed historical boundaries."""
import hashlib
import json
from pathlib import Path

BASE=Path('docs/audits/observer-original-header-join-20261011')
VALUES=Path('docs/audits/observer-source-value-acceptance-20261011')
PUBLICATION=Path('docs/audits/observer-source-value-publication-repair-20261011')
CENSUS=Path('docs/audits/observer-header-source-census-20261010')
DISPLAY=Path('docs/audits/observer-display-contract-20261010')
PREDICATE=Path('docs/audits/observer-predicate-values-20261010')
SCALAR=Path('docs/audits/observer-scalar-values-20261010')
REGEX=Path('docs/audits/observer-regex-values-20261010')
REVISION='83ad8b9385fc6f7149d735eb28586134117f1c41'
HEADERS=Path('docs/audits/observer-source-headers-20261011')
HEADER_REPAIR=Path('docs/audits/observer-source-header-publication-repair-20261011')
CLASS=Path('docs/audits/record-value-class-frame-join-20261006')
SCOPE=('Complete original own observer/callback/refuses/subtest/do-load full header/source join and unchanged repair acceptance only. Complete raw/address/coordinate/source domains and every inherited evidence role conserve. Original settings/formatter/flags/encoding, reference/referent/receiver identity and private framework/eval meanings remain unmeasured. Explicit finite public grammar compatibility supplies no original native/provider/private attribution. Whole observer publication and higher raw/native/private/visual scopes remain separately owned.')


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


def inherited_inputs():
    return [CENSUS/n for n in ('source-models.json','census.json','obligation-plan.json')] + [
        VALUES/n for n in ('product-qualified.json','contracts.json','proof.json','manifest.json')] + [
        PUBLICATION/n for n in ('proof.json','manifest.json')] + [
        DISPLAY/n for n in ('repaired-catalogue.json','repaired-hypotheses.json','repaired-native.json',
                           'repaired-joined.json','oracle_repaired.py','model_repaired.py','qualified-proof.json')] + [
        PREDICATE/n for n in ('predicate-values-qualified.json','fixture-plan-qualified.json','native-qualified.json')] + [
        SCALAR/n for n in ('scalars.json','plan.json','native.json')] + [
        REGEX/n for n in ('regexes.json','plan.json','native.json')]


def inputs():
    return inherited_inputs()+[HEADERS/n for n in ("headers.json","current-headers.json","selection.json","proof.json","contracts.json","manifest.json","publication-proof.json")]+[HEADER_REPAIR/n for n in ("proof.json","manifest.json")]+[CLASS/n for n in ("source-models.json","raw-product.json","proofs.json","binding.json","manifest.json")]
