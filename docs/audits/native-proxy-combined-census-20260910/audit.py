"""Independent mixed-reference, complete-source and read-only-census oracle."""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-combined-census-20260910'


def load(name: str, directory: str):
    spec = importlib.util.spec_from_file_location(name, BASE.parent / directory / 'audit.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


RUNTIME = load('combined_runtime_codec', 'native-proxy-runtime-records-20260910')
OBSERVER = load('combined_observation_codec', 'native-proxy-observation-records-20260910')
VECTOR = json.loads((BASE.parent / 'native-proxy-image-custody-20260910/vectors.json').read_bytes())
C, IMAGE = (bytes.fromhex(VECTOR[name]) for name in ('generated_c_hex', 'image_hex'))


def canonical(value: object) -> bytes:
    return json.dumps(value, sort_keys=True, ensure_ascii=True, separators=(',', ':'), allow_nan=False).encode('ascii')


def image(variant: str) -> tuple[str, tuple[bytes, bytes, bytes]]:
    assert variant in ('', 'second')
    executable = IMAGE + variant.encode('ascii')
    key = hashlib.sha256(b'fsmgen.rust_proxy_image.v1\0' + len(C).to_bytes(8, 'big') + C
                         + len(executable).to_bytes(8, 'big') + executable).hexdigest()
    manifest = dict(schema='fsmgen.test.rust_proxy_image.v1', key=key,
                    generated_c=dict(size_bytes=len(C), sha256=hashlib.sha256(C).hexdigest()),
                    executable=dict(size_bytes=len(executable), sha256=hashlib.sha256(executable).hexdigest()))
    return key, (C, executable, canonical(manifest))


def record(case: str, kind: str, index: int, variant: str = '') -> dict:
    key, data = image(variant)
    value = dict(image_key=key, selected_sources=[dict(path=f'{case}/images/{key}/{name}',
        device=17, inode=100+i, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
        for i, (name, raw) in enumerate(zip(('rustup.c', 'rustup'), data[:2]))])
    if kind == 'runtime':
        path = f'.artifacts/tmp/process-supervisor-tests/fsmgen-CombinedCensus{index}'
        value.update(schema=RUNTIME.SCHEMA, workspace=path, workspace_identity=dict(path=path, device=17, inode=99),
                     reference_key=RUNTIME.key(path))
        RUNTIME.validate(case, canonical(value).decode('ascii'))
    else:
        assert kind == 'observation'
        path = '.artifacts/logs/inert-combined-census'
        value.update(schema=OBSERVER.SCHEMA, evidence_directory=path,
            evidence_directory_identity=dict(path=path, device=17, inode=99),
            observer_birth=dict(pid=101, ppid=100, uid=501, ruid=501, start_sec=123, start_usec=456),
            target_birth=dict(pid=201+index, ppid=200, uid=501, ruid=501, start_sec=124, start_usec=789))
        value['reference_key'] = OBSERVER.key(value)
        OBSERVER.validate(case, canonical(value).decode('ascii'))
    return value


def specs(name: str) -> list[tuple[str, int, str]]:
    return {
        'empty': [],
        'observation_only': [('observation', i, '') for i in range(2)],
        'mixed_images': [('runtime', 0, ''), ('observation', 0, ''),
                         ('runtime', 1, 'second'), ('observation', 1, 'second')],
        'mixed_capacity': [(kind, i, '') for i in range(64) for kind in ('runtime', 'observation')],
    }[name]


def native(value: dict) -> None:
    assert type(value['device']) is int and value['device'] == ROOT.stat().st_dev
    assert type(value['inode']) is int and value['inode'] > 0


def source(value: dict, path: str, raw: bytes, nodes: dict | None = None, case: str | None = None) -> None:
    assert set(value) == {'bytes', 'identity'}
    assert type(value['bytes']) is str and value['bytes'].encode('latin1') == raw
    identity = value['identity']
    assert set(identity) == {'path', 'device', 'inode', 'size_bytes', 'sha256'}
    assert identity['path'] == path and identity['size_bytes'] == len(raw)
    assert identity['sha256'] == hashlib.sha256(raw).hexdigest()
    native(identity)
    if nodes is not None:
        assert case is not None
        node = nodes[path.removeprefix(case + '/')]
        assert node['device'] == identity['device'] and node['inode'] == identity['inode']
        assert node['bytes'] == identity['size_bytes'] and node['sha256'] == identity['sha256']


def census(value: dict, case: str, owners: list, nodes: dict | None = None) -> None:
    assert set(value) == {'schema', 'runtime_authorized', 'executable', 'lock', 'references', 'images', 'retention'}
    assert value['schema'] == 'fsmgen.inactive_image_reference_census.v1'
    assert type(value['runtime_authorized']) is int and value['runtime_authorized'] == 0
    assert value['executable'] is None
    assert value['retention'] == 'all_valid_runtime_and_observation_records_retained; stale_owners_not_released'
    assert set(value['lock']) == {'path', 'device', 'inode'}
    assert value['lock']['path'] == case + '/coordination.lock'
    native(value['lock'])
    if nodes is not None:
        assert all(value['lock'][k] == nodes['coordination.lock'][k] for k in ('device', 'inode'))
    expected = sorted((record(case, *spec) for spec in owners), key=lambda r: r['reference_key'])
    assert len(value['references']) == len(expected)
    for entry, wanted in zip(value['references'], expected):
        assert set(entry) == {'record', 'source'} and entry['record'] == wanted
        source(entry['source'], f"{case}/references/{wanted['reference_key']}.json", canonical(wanted), nodes, case)
        codec = RUNTIME if wanted['schema'] == RUNTIME.SCHEMA else OBSERVER
        assert codec.validate(case, entry['source']['bytes']) == wanted
    selected = {image(spec[2])[0]: image(spec[2])[1] for spec in owners}
    assert [entry['key'] for entry in value['images']] == sorted(selected)
    for entry in value['images']:
        assert set(entry) == {'key', 'snapshots'} and len(entry['snapshots']) == 3
        for snapshot, name, raw in zip(entry['snapshots'], ('rustup.c', 'rustup', 'image.json'), selected[entry['key']]):
            source(snapshot, f"{case}/images/{entry['key']}/{name}", raw, nodes, case)


def footprint(nodes: dict, case: str, owners: list, variants: tuple = ('',), reference_files: dict | None = None) -> None:
    expected = {'', 'coordination.lock', 'images', 'references'}
    files = {'coordination.lock': (b'', 0o600, 1)}
    for variant in variants:
        key, data = image(variant)
        prefix = f'images/{key}'
        expected.add(prefix)
        for name, raw, mode in zip(('rustup.c', 'rustup', 'image.json'), data, (0o400, 0o500, 0o400)):
            files[f'{prefix}/{name}'] = (raw, mode, 1)
    if reference_files is None:
        for spec in owners:
            value = record(case, *spec)
            files[f"references/{value['reference_key']}.json"] = (canonical(value), 0o400, 1)
    else:
        files.update(reference_files)
    expected.update(files)
    assert set(nodes) == expected
    for path, node in nodes.items():
        native(node)
        assert node['uid'] == os.getuid()
        if path in files:
            raw, mode, links = files[path]
            assert node['kind'] == 'file' and node['mode'] == mode and node['links'] == links
            assert node['bytes'] == len(raw) and node['sha256'] == hashlib.sha256(raw).hexdigest()
        else:
            assert node['kind'] == 'directory' and node['mode'] == 0o700


def control_files(name: str, case: str) -> dict:
    value = record(case, 'observation', 0)
    filename = value['reference_key'] + '.json'
    if name == 'extra observation field':
        value['extra'] = 0
    elif name == 'merged observation fields':
        value['image_key,reference_key'] = value.pop('image_key')
        value.pop('reference_key')
    elif name == 'birth integer boolean':
        value['observer_birth']['uid'] = True
    elif name == 'birth key mismatch':
        value['target_birth']['start_usec'] += 1
    elif name == 'source content mismatch':
        value['selected_sources'][0]['sha256'] = '0' * 64
    elif name == 'source length mismatch':
        value['selected_sources'][1]['size_bytes'] += 1
    elif name == 'source order':
        value['selected_sources'].reverse()
    elif name == 'absent image':
        value['image_key'] = '0' * 64
        for source in value['selected_sources']:
            source['path'] = re.sub(r'/images/[0-9a-f]+/', '/images/' + '0' * 64 + '/', source['path'])
    elif name == 'unknown schema':
        value['schema'] += '.unknown'
    elif name == 'missing schema':
        value.pop('schema')
    elif name == 'boolean schema':
        value['schema'] = True
    elif name == 'runtime fields relabeled as observation':
        value = record(case, 'runtime', 0)
        filename = value['reference_key'] + '.json'
        value['schema'] = OBSERVER.SCHEMA
    elif name == 'wrong filename':
        filename = '0' * 64 + '.json'
    raw = canonical(value)
    if name == 'duplicate member':
        raw = b'{"schema":"discarded",' + raw[1:]
    elif name == 'partial JSON':
        raw = b'{'
    links = 2 if name == 'hardlinked reference' else 1
    mode = 0o600 if name == 'writable reference' else 0o400
    files = {'references/' + filename: (raw, mode, links)}
    if links == 2:
        files['references/' + '1' * 64 + '.json'] = (raw, mode, links)
    return files


def late_change(row: dict) -> None:
    before, after, name, case = (row[k] for k in ('before', 'injected', 'name', 'case'))
    value = record(case, 'observation', 0)
    reference = f"references/{value['reference_key']}.json"
    if name == 'reference_added':
        footprint(after, case, [('observation', 0, ''), ('observation', 1, '')])
        assert {p: after[p] for p in before} == before
        return
    key = image('')[0]
    selected = {'reference_replaced': reference, 'reference_bytes_changed': reference,
                'image_replaced': f'images/{key}/rustup', 'image_directory_replaced': f'images/{key}'}[name]
    assert set(before) == set(after)
    assert {p: n for p, n in before.items() if p != selected} == {p: n for p, n in after.items() if p != selected}
    if name == 'reference_bytes_changed':
        value['evidence_directory_identity']['inode'] = 100
        raw = canonical(value)
        assert after[selected] == dict(before[selected], bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
    else:
        assert before[selected]['inode'] != after[selected]['inode']
        native(after[selected])
        assert after[selected] == dict(before[selected], inode=after[selected]['inode'])


def validate(result: dict, plan: dict) -> None:
    assert result['schema'] == 'fsmgen.inactive_combined_reference_census_qualification.v1'
    assert result['success'] is True and type(result['forbidden_process_attempts']) is int
    assert result['forbidden_process_attempts'] == 0
    allocations = result['allocated']
    assert len(allocations) == len(plan['positive']) + len(plan['controls']) + len(plan['late']) + len(plan['mutants'])
    assert allocations == [json.loads(line) for line in (LOG / 'admission.jsonl').read_text().splitlines()]
    paths = [row['path'] for row in allocations]
    assert len(paths) == len(set(paths))
    for row in allocations:
        assert row['kind'] == 'store' and re.fullmatch(
            r'\.artifacts/tmp/native-proxy-image-custody/cases/fsmgen-[A-Za-z0-9_]+', row['path'])
        native(row)
        path = ROOT / row['path']
        assert not path.exists() and not path.is_symlink()
    positive = result['positive']
    assert [row['name'] for row in positive] == plan['positive']
    for row in positive:
        owners = specs(row['name'])
        assert row['before'] == row['after']
        assert row['cloexec_sources'] == [1] * len(owners)
        footprint(row['before'], row['case'], owners, ('', 'second') if row['name'] == 'mixed_images' else ('',))
        census(row['census'], row['case'], owners, row['before'])
    extra = result['capacity_excess']
    assert extra['case'] == positive[3]['case'] and extra['name'] == 'combined capacity excess'
    footprint(extra['before'], extra['case'], specs('mixed_capacity') + [('observation', 64, '')])
    assert extra['before'] == extra['after']
    assert extra['rejected'] == extra['diagnostic_matched'] == 1 and extra['returned'] == 0
    controls = result['controls']
    assert [row['name'] for row in controls] == plan['controls']
    assert all(row['rejected'] == row['diagnostic_matched'] == 1 and row['returned'] == 0
               and row['before'] == row['after'] for row in controls)
    for row in controls:
        footprint(row['before'], row['case'], [], reference_files=control_files(row['name'], row['case']))
    pin = next(row for row in controls if row['name'] == 'observation pin blocks maintenance')
    footprint(pin['before'], pin['case'], [('observation', 0, '')])
    late = result['late_changes']
    assert [row['name'] for row in late] == plan['late']
    for row in late:
        footprint(row['before'], row['case'], [('observation', 0, '')])
        assert row['rejected'] == row['diagnostic_matched'] == 1 and row['returned'] == 0
        assert row['after'] == row['injected'] and row['before'] != row['injected']
        late_change(row)
    mutants = result['mutants']
    assert [row['name'] for row in mutants] == plan['mutants']
    for row in mutants:
        try:
            census(row['accepted'], row['case'], [('observation', 0, '')])
        except AssertionError:
            pass
        else:
            raise AssertionError('independent oracle missed mutant: ' + row['name'])
    rows = [*positive, *controls, *late, *mutants]
    assert {row['case'] for row in rows} == set(paths) and len(rows) == len(paths)
    for row in [*positive, *controls, *late]:
        allocation = allocations[paths.index(row['case'])]
        assert all(row['before'][''][key] == allocation[key] for key in ('device', 'inode'))


def main() -> None:
    assert hashlib.sha256((BASE / 'plan.json').read_bytes()).hexdigest() == '9acb2e13135f501617d972f9376b8e37a01e33485d70e5cd762fb7fe791c716b'
    plan = json.loads((BASE / 'plan.json').read_bytes())
    result = json.loads((LOG / 'qualification.json').read_bytes())
    validate(result, plan)
    assertions = RUNTIME.tap_count((LOG / 'qualify.tap').read_text())
    assert assertions == len(result['allocated']) + 2
    falsifiers = []
    for name, mutate in [
        ('hidden failure', lambda x: x.update(success=False)),
        ('lost observation hold', lambda x: x['positive'][1]['census']['references'].pop()),
        ('mixed capacity omission', lambda x: x['positive'][3]['census']['references'].pop()),
        ('lost source inode join', lambda x: x['positive'][1]['census']['references'][0]['source']['identity'].update(inode=1)),
        ('runtime authorization', lambda x: x['positive'][1]['census'].update(runtime_authorized=1)),
        ('lost rejection', lambda x: x['controls'].pop()),
        ('maintenance deleted observation pin', lambda x: x['controls'][18]['after'].pop('references')),
        ('lost mutation detection', lambda x: x['late_changes'][0].update(rejected=0)),
        ('lost schema mutant', lambda x: x['mutants'].pop()),
        ('lost allocation', lambda x: x['allocated'].pop()),
        ('forbidden process', lambda x: x.update(forbidden_process_attempts=1)),
    ]:
        altered = copy.deepcopy(result)
        mutate(altered)
        try:
            validate(altered, plan)
        except AssertionError:
            falsifiers.append(name)
        else:
            raise AssertionError('counterfactual accepted: ' + name)
    regressions = {}
    for name, directory in [('runtime-census', 'native-proxy-runtime-census-20260910'),
                            ('retirement', 'native-proxy-runtime-retirement-20260910'),
                            ('maintenance', 'native-proxy-image-maintenance-20260910')]:
        module = load('combined_' + name.replace('-', '_') + '_regression', directory)
        module.LOG = LOG / (name + '-regression')
        data = json.loads((module.LOG / 'qualification.json').read_bytes())
        if name == 'runtime-census':
            module.validate(data)
            retired = data['retired_cases']
        elif name == 'retirement':
            module.validate_result(data, module.build_plan())
            retired = [row['path'] for row in data['allocated']]
        else:
            module.validate(data, module.build_plan())
            retired = [row['path'] for row in data['allocated']]
        regressions[name] = dict(assertions=RUNTIME.tap_count((module.LOG / 'qualify.tap').read_text()), retired_paths=retired)
    paths = [row['path'] for row in result['allocated']] + [p for r in regressions.values() for p in r['retired_paths']]
    assert len(paths) == len(set(paths))
    report = dict(schema='fsmgen.inactive_combined_reference_census_audit.v1', success=True,
        assertions=assertions, allocations=len(result['allocated']), rejection_controls=len(result['controls'])+1,
        late_changes=len(result['late_changes']), mutants=plan['mutants'], falsifiers=falsifiers,
        regressions={name: dict(assertions=row['assertions'], retired_paths=len(row['retired_paths'])) for name,row in regressions.items()},
        all_allocation_rosters_disjoint_and_absent=True, limits=plan['limits'])
    (LOG / 'audit.json').write_text(json.dumps(report,sort_keys=True,indent=2)+'\n')
    print(json.dumps(report,sort_keys=True))


if __name__ == '__main__':
    main()
