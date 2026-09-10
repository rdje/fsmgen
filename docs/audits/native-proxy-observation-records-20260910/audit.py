"""Independent data-only observation-record construction and result oracle."""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-observation-records-20260910'
SCHEMA = 'fsmgen.test.rust_proxy_image_observation_reference.v1'
FIELDS = {'schema', 'reference_key', 'image_key', 'evidence_directory',
          'evidence_directory_identity', 'observer_birth', 'target_birth', 'selected_sources'}
BIRTH = {'pid', 'ppid', 'uid', 'ruid', 'start_sec', 'start_usec'}


def canonical(value: object) -> str:
    return json.dumps(value, ensure_ascii=True, sort_keys=True, separators=(',', ':'), allow_nan=False)


def key(value: dict) -> str:
    payload = [value['evidence_directory'], value['observer_birth'], value['target_birth']]
    return hashlib.sha256(b'fsmgen.rust_proxy_reference.observation.v1\0'
                          + canonical(payload).encode('ascii')).hexdigest()


def fields(value: object, names: set) -> None:
    assert type(value) is dict and set(value) == names


def integer(value: object) -> None:
    assert type(value) is int and value >= 0


def digest(value: object) -> None:
    assert type(value) is str and re.fullmatch('[0-9a-f]{64}', value)


def path(value: object) -> None:
    assert type(value) is str and value
    assert not re.search(r'[\x00-\x1f\x7f\\]', value)
    assert all(part not in ('', '.', '..') for part in value.split('/'))


def pairs(rows: list) -> dict:
    result = {}
    for name, value in rows:
        assert name not in result, 'duplicate member'
        result[name] = value
    return result


def validate(case: str, raw: str) -> dict:
    assert type(case) is str and re.fullmatch(
        r'\.artifacts/tmp/native-proxy-image-custody/cases/fsmgen-[A-Za-z0-9_]+', case)
    assert type(raw) is str and raw.isascii() and len(raw) <= 4096
    value = json.loads(raw, object_pairs_hook=pairs)
    fields(value, FIELDS)
    assert value['schema'] == SCHEMA and canonical(value) == raw
    for name in ('image_key', 'reference_key'):
        digest(value[name])
    path(value['evidence_directory'])
    directory = value['evidence_directory_identity']
    fields(directory, {'path', 'device', 'inode'})
    assert directory['path'] == value['evidence_directory']
    for name in ('device', 'inode'):
        integer(directory[name])
    for name in ('observer_birth', 'target_birth'):
        birth = value[name]
        fields(birth, BIRTH)
        for number in birth.values():
            integer(number)
        assert birth['pid'] > 0 and birth['start_usec'] < 1000000
    assert value['reference_key'] == key(value)
    sources = value['selected_sources']
    assert type(sources) is list and len(sources) == 2
    for source, name in zip(sources, ('rustup.c', 'rustup')):
        fields(source, {'path', 'device', 'inode', 'size_bytes', 'sha256'})
        assert source['path'] == f"{case}/images/{value['image_key']}/{name}"
        for field in ('device', 'inode', 'size_bytes'):
            integer(source[field])
        assert source['size_bytes'] <= 65536
        digest(source['sha256'])
    return value


def build_plan() -> dict:
    prior = json.loads((BASE.parent / 'native-proxy-image-custody-20260910/vectors.json').read_bytes())
    c, image = bytes.fromhex(prior['generated_c_hex']), bytes.fromhex(prior['image_hex'])
    image_key = hashlib.sha256(b'fsmgen.rust_proxy_image.v1\0' + len(c).to_bytes(8, 'big') + c
                              + len(image).to_bytes(8, 'big') + image).hexdigest()
    assert image_key == prior['key']
    case = '.artifacts/tmp/native-proxy-image-custody/cases/fsmgen-ObservationCodec'
    evidence = '.artifacts/logs/inert-observation-codec'
    record = dict(schema=SCHEMA, reference_key='', image_key=image_key, evidence_directory=evidence,
                  evidence_directory_identity=dict(path=evidence, device=17, inode=101),
                  observer_birth=dict(pid=101, ppid=100, uid=501, ruid=501, start_sec=123, start_usec=456),
                  target_birth=dict(pid=102, ppid=99, uid=501, ruid=501, start_sec=124, start_usec=789),
                  selected_sources=[dict(path=f'{case}/images/{image_key}/{name}', device=17,
                                         inode=inode, size_bytes=len(data), sha256=hashlib.sha256(data).hexdigest())
                                    for name, inode, data in [('rustup.c', 102, c), ('rustup', 103, image)]])
    record['reference_key'] = key(record)
    vectors = []

    def vector(name: str, value: dict) -> None:
        value['reference_key'] = key(value)
        raw = canonical(value)
        validate(case, raw)
        vectors.append(dict(name=name, record=value, raw=raw))

    vector('inert historical identities', copy.deepcopy(record))
    unicode = copy.deepcopy(record)
    unicode['evidence_directory'] += '-é-😀'
    unicode['evidence_directory_identity']['path'] = unicode['evidence_directory']
    vector('Unicode path canonical ASCII', unicode)
    large = copy.deepcopy(record)
    large['selected_sources'][1]['inode'] = 9007199254740993
    vector('integer above binary64 precision', large)
    ceiling = copy.deepcopy(record)
    for source in ceiling['selected_sources']:
        source['size_bytes'] = 65536
    vector('source byte ceiling is structural only', ceiling)
    boundary = copy.deepcopy(record)
    if (4096 - len(canonical(boundary))) % 2:
        boundary['evidence_directory_identity']['inode'] = 1000
    boundary['evidence_directory'] += 'B' * ((4096 - len(canonical(boundary))) // 2)
    boundary['evidence_directory_identity']['path'] = boundary['evidence_directory']
    vector('record byte ceiling is syntax only', boundary)
    assert len(vectors[-1]['raw']) == 4096
    for owner in ('observer_birth', 'target_birth'):
        for field in sorted(BIRTH):
            changed = copy.deepcopy(record)
            changed[owner][field] += 1
            vector(f'key binds {owner}.{field}', changed)
            assert changed['reference_key'] != record['reference_key']
    swapped = copy.deepcopy(record)
    swapped['observer_birth'], swapped['target_birth'] = swapped['target_birth'], swapped['observer_birth']
    vector('birth order remains significant', swapped)
    assert swapped['reference_key'] != record['reference_key']
    edge = copy.deepcopy(record)
    edge['observer_birth'] = dict(pid=1, ppid=0, uid=0, ruid=0, start_sec=0, start_usec=0)
    edge['target_birth']['start_usec'] = 999999
    vector('native birth structural endpoints', edge)
    rejects = []

    def reject(name: str, value: object, diagnostic: str, *, target_case: str = case) -> None:
        raw = canonical(value)
        try:
            validate(target_case, raw)
        except (AssertionError, ValueError):
            pass
        else:
            raise AssertionError(f'invalid planned rejection: {name}')
        rejects.append(dict(name=name, operation='encode', case=target_case,
                            record=value, diagnostic=diagnostic))

    def changed(name: str, mutate, diagnostic: str) -> None:
        value = copy.deepcopy(record)
        mutate(value)
        reject(name, value, diagnostic)

    reject('null root', None, 'closed record')
    reject('array root', [], 'closed record')
    for field in sorted(FIELDS):
        changed('missing root ' + field, lambda x, f=field: x.pop(f), 'closed record')
    changed('extra root field', lambda x: x.update(extra=0), 'closed record')
    changed('merged root fields', lambda x: (x.update({'image_key,reference_key': x.pop('image_key')}),
                                           x.pop('reference_key')), 'closed record')
    for value in ('fsmgen.test.rust_proxy_image_reference.v1', 'fsmgen.test.rust_proxy_image_observation_reference.v2'):
        changed('wrong schema ' + value, lambda x, v=value: x.update(schema=v), 'observation reference schema')
    changed('boolean schema', lambda x: x.update(schema=True), 'JSON string')
    for field in ('image_key', 'reference_key'):
        for label, value, diagnostic in [('uppercase', 'A' * 64, 'lowercase SHA'),
                                         ('short', 'a' * 63, 'lowercase SHA'),
                                         ('numeric', 123, 'JSON string')]:
            changed(f'{field} {label}', lambda x, f=field, v=value: x.update({f: v}), diagnostic)
    changed('wrong reference key', lambda x: x.update(reference_key='0' * 64), 'key differs')
    for owner in ('observer_birth', 'target_birth'):
        for label, value, diagnostic in [('null', None, 'closed native birth'),
                                         ('array', [], 'closed native birth'),
                                         ('extra', dict(record[owner], extra=0), 'closed native birth')]:
            changed(f'{owner} {label}', lambda x, o=owner, v=value: x.update({o: v}), diagnostic)
        for field in sorted(BIRTH):
            changed(f'{owner} missing {field}', lambda x, o=owner, f=field: x[o].pop(f), 'closed native birth')
            changed(f'{owner} stale key {field}', lambda x, o=owner, f=field: x[o].update({f: x[o][f] + 1}), 'key differs')
        for label, value in [('string', '101'), ('boolean', True), ('negative', -1),
                             ('fraction', 0.5), ('null', None), ('array', []), ('object', {})]:
            changed(f'{owner} integer {label}', lambda x, o=owner, v=value: x[o].update(uid=v), 'birth integer')
        for field, value in [('pid', 0), ('start_usec', 1000000)]:
            changed(f'{owner} invalid {field}', lambda x, o=owner, f=field, v=value: x[o].update({f: v}), 'invalid native birth')
        changed(f'{owner} merged padded fields', lambda x, o=owner: (
            x[o].update({'ppid,ruid': x[o].pop('ppid'), 'padding': 0}), x[o].pop('ruid')), 'closed native birth')
    changed('directory path mismatch', lambda x: x['evidence_directory_identity'].update(path='other'), 'identity path differs')
    changed('directory extra field', lambda x: x['evidence_directory_identity'].update(extra=0), 'closed record')
    changed('directory merged padded fields', lambda x: (
        x['evidence_directory_identity'].update({'device,inode': 17, 'padding': 0}),
        x['evidence_directory_identity'].pop('device'), x['evidence_directory_identity'].pop('inode')), 'closed record')
    for label, value in [('string', '101'), ('boolean', True), ('negative', -1), ('fraction', 0.5), ('null', None), ('array', [])]:
        changed('directory integer ' + label, lambda x, v=value: x['evidence_directory_identity'].update(inode=v), 'JSON integer')
        changed('source integer ' + label, lambda x, v=value: x['selected_sources'][0].update(size_bytes=v), 'JSON integer')
    for label, mutate, diagnostic in [
        ('source order', lambda x: x['selected_sources'].reverse(), 'source path differs'),
        ('source missing', lambda x: x['selected_sources'].pop(), 'source pair'),
        ('source extra', lambda x: x['selected_sources'].append(copy.deepcopy(x['selected_sources'][0])), 'source pair'),
        ('source map', lambda x: x.update(selected_sources={}), 'source pair'),
        ('source null', lambda x: x['selected_sources'].__setitem__(0, None), 'closed record'),
        ('source extra field', lambda x: x['selected_sources'][0].update(extra=0), 'closed record'),
        ('source ceiling excess', lambda x: x['selected_sources'][0].update(size_bytes=65537), 'source exceeds'),
        ('source digest', lambda x: x['selected_sources'][0].update(sha256='G' * 64), 'lowercase SHA'),
        ('source private substitution', lambda x: x['selected_sources'][0].update(path='.artifacts/tmp/process-supervisor-tests/fsmgen-A/rust-tools/rustup.c'), 'source path differs'),
        ('source foreign image', lambda x: x['selected_sources'][0].update(path=f'{case}/images/' + '0' * 64 + '/rustup.c'), 'source path differs'),
    ]:
        changed(label, mutate, diagnostic)
    for value in ('', '/absolute', '../escape', 'a/../b', 'a/./b', 'a//b', 'a/', 'a\\b', 'a\n', 'a\x00', 'a\x7f', 123, True, None, []):
        changed('evidence path ' + canonical(value), lambda x, v=value: x.update(evidence_directory=v), 'root-relative path')
    for value in ('/absolute', case + '/../B', case + '/', case + '\n', '.artifacts/cache/rust-proxy-images/v1'):
        reject('case path ' + canonical(value), copy.deepcopy(record), 'inactive image case', target_case=value)
    oversized = copy.deepcopy(boundary)
    oversized['evidence_directory_identity']['inode'] *= 10
    reject('record encode ceiling', oversized, 'record exceeds')
    raw = canonical(record)
    spellings = [
        ('trailing newline', raw + '\n', 'not canonical'),
        ('leading whitespace', ' ' + raw, 'not canonical'),
        ('duplicate root', '{"schema":"discarded",' + raw[1:], 'not canonical'),
        ('duplicate directory member', raw.replace('"evidence_directory_identity":{', '"evidence_directory_identity":{"inode":0,'), 'not canonical'),
        ('duplicate birth member', raw.replace('"observer_birth":{', '"observer_birth":{"pid":0,'), 'not canonical'),
        ('noncanonical fraction', raw.replace('"inode":101', '"inode":101.0'), 'not canonical'),
        ('noncanonical exponent', raw.replace('"inode":101', '"inode":1.01e2'), 'not canonical'),
        ('noncanonical ASCII escape', raw.replace('"schema":', '"sch\\u0065ma":'), 'not canonical'),
        ('invalid JSON', '{', 'invalid observation JSON'),
        ('deep JSON', '[' * 20 + '0' + ']' * 20, 'invalid observation JSON'),
        ('decode ceiling', ' ' * 4097, 'bounded ASCII'),
    ]
    for name, spelling, diagnostic in spellings:
        try:
            validate(case, spelling)
        except (AssertionError, ValueError):
            pass
        else:
            raise AssertionError(f'invalid planned spelling: {name}')
        rejects.append(dict(name=name, operation='decode', case=case, raw=spelling, diagnostic=diagnostic))
    mutants = []
    for name in ('omitted field closure', 'omitted key derivation', 'omitted birth validation'):
        value = copy.deepcopy(record)
        if name == 'omitted field closure':
            value['extra'] = 0
        elif name == 'omitted key derivation':
            value['reference_key'] = '0' * 64
        else:
            value['observer_birth']['uid'] = True
            value['reference_key'] = key(value)
        mutants.append(dict(name=name, record=value, raw=canonical(value)))
    return dict(schema='fsmgen.inactive_observation_record_plan.v1', case=case,
                vectors=vectors, rejects=rejects, mutants=mutants,
                limits='Synthetic paths/identities only. No current filesystem, native identity, custody or liveness proof.')


def tap_count(raw: str) -> int:
    assert not re.search(r'^(?:not ok|Bail out!)', raw, re.M)
    plans = re.findall(r'^1\.\.([0-9]+)$', raw, re.M)
    assert len(plans) == 1
    total = int(plans[0])
    assert [int(n) for n in re.findall(r'^ok ([0-9]+) - ', raw, re.M)] == list(range(1, total + 1))
    return total


EXTRA_CONTROLS = ['raw non-ASCII', 'character instead of bytes', 'reference instead of bytes',
                  'extra encode argument', 'missing decode argument', 'extra decode argument',
                  'runtime record in observation decoder', 'observation record in runtime decoder']


def validate_result(result: dict, plan: dict) -> None:
    assert result['schema'] == 'fsmgen.inactive_observation_record_qualification.v1'
    assert result['success'] is True
    for name in ('forbidden_process_attempts', 'filesystem_lookup_attempts'):
        assert type(result[name]) is int and result[name] == 0
    assert result['encoded'] == [entry['raw'] for entry in plan['vectors']]
    for raw in result['encoded']:
        validate(plan['case'], raw)
    controls = result['controls']
    assert [row['name'] for row in controls] == [row['name'] for row in plan['rejects']] + EXTRA_CONTROLS
    assert all(type(row['rejected']) is int and row['rejected'] == 1
               and type(row['expected_diagnostic']) is int and row['expected_diagnostic'] == 1 for row in controls)
    assert result['mutants'] == [dict(name=row['name'], raw=row['raw'], accepted_by_mutant=1) for row in plan['mutants']]
    for mutant in result['mutants']:
        try:
            validate(plan['case'], mutant['raw'])
        except AssertionError:
            pass
        else:
            raise AssertionError('independent oracle missed mutant: ' + mutant['name'])


def main() -> None:
    plan = build_plan()
    if sys.argv[1:] == ['--plan']:
        (BASE / 'plan.json').write_text(json.dumps(plan, sort_keys=True, indent=2) + '\n')
        print(json.dumps(dict(vectors=len(plan['vectors']), planned_rejections=len(plan['rejects']), mutants=len(plan['mutants']))))
        return
    assert not sys.argv[1:]
    assert json.loads((BASE / 'plan.json').read_bytes()) == plan
    contract = ROOT / 'docs/audits/native-proxy-canonical-contract-20260910/contract.json'
    assert hashlib.sha256(contract.read_bytes()).hexdigest() == 'f3f981398afae72540ab4ac0194b8380d4743c3d2146c1172a85365add053222'
    result = json.loads((LOG / 'qualification.json').read_bytes())
    validate_result(result, plan)
    assertions = tap_count((LOG / 'qualify.tap').read_text())
    assert assertions == len(plan['vectors']) * 2 + len(plan['rejects']) + len(EXTRA_CONTROLS) + len(plan['mutants']) + 2
    falsifiers = []
    for name, mutate in [
        ('hidden failure', lambda x: x.update(success=False)),
        ('lost rejection', lambda x: x['controls'].pop()),
        ('duplicate rejection', lambda x: x['controls'].append(x['controls'][0])),
        ('hidden acceptance', lambda x: x['controls'][0].update(rejected=0)),
        ('wrong diagnostic', lambda x: x['controls'][0].update(expected_diagnostic=0)),
        ('lost birth mutant', lambda x: x['mutants'].pop()),
        ('lookup despite pure codec', lambda x: x.update(filesystem_lookup_attempts=1)),
        ('unexpected process', lambda x: x.update(forbidden_process_attempts=1)),
        ('changed encoded bytes', lambda x: x['encoded'].__setitem__(0, x['encoded'][0] + '\n')),
    ]:
        altered = copy.deepcopy(result)
        mutate(altered)
        try:
            validate_result(altered, plan)
        except AssertionError:
            falsifiers.append(name)
        else:
            raise AssertionError('counterfactual accepted: ' + name)
    prior = BASE.parent / 'native-proxy-runtime-records-20260910'
    spec = importlib.util.spec_from_file_location('prior_runtime_audit', prior / 'audit.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.validate_result(json.loads((LOG / 'runtime-regression.json').read_bytes()), module.build_vectors())
    runtime_assertions = module.tap_count((LOG / 'runtime-regression.tap').read_text())
    report = dict(schema='fsmgen.inactive_observation_record_audit.v1', success=True,
                  assertions=assertions, vectors=len(plan['vectors']), rejection_controls=len(result['controls']),
                  mutants=[x['name'] for x in plan['mutants']], falsifiers=falsifiers,
                  runtime_regression_assertions=runtime_assertions,
                  limits=['Only closed record syntax, historical identity consistency and key derivation.',
                          'No store/workspace/reference created; no native query or fixture/compiler subprocess launched.',
                          'Dual census, observation acquisition/release, archive custody and capture compatibility remain open.'])
    (LOG / 'audit.json').write_text(json.dumps(report, sort_keys=True, indent=2) + '\n')
    print(json.dumps(report, sort_keys=True))


if __name__ == '__main__':
    main()
