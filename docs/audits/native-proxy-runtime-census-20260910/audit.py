"""Independent byte, record, retention and retired-case audit; no processes."""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import re

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-runtime-census-20260910'


def load(name: str, directory: str):
    spec = importlib.util.spec_from_file_location(name, BASE.parent / directory / 'audit.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


CODEC = load('runtime_codec_audit', 'native-proxy-runtime-records-20260910')
CUSTODY = load('image_custody_audit', 'native-proxy-image-custody-20260910')
COORDINATION = load('image_coordination_audit', 'native-proxy-image-coordination-20260910')
PUBLICATION = load('image_publication_audit', 'native-proxy-image-publication-20260910')
VECTOR = json.loads((BASE.parent / 'native-proxy-image-custody-20260910/vectors.json').read_bytes())
BYTES = CUSTODY.vectors(VECTOR)


def source(value: dict, path: str, expected: bytes) -> None:
    assert type(value['bytes']) is str and value['bytes'].encode('latin1') == expected
    identity = value['identity']
    assert identity['path'] == path
    assert identity['size_bytes'] == len(expected)
    assert identity['sha256'] == hashlib.sha256(expected).hexdigest()
    assert type(identity['device']) is int and identity['device'] == ROOT.stat().st_dev
    assert type(identity['inode']) is int and identity['inode'] > 0


def census(value: dict) -> None:
    assert value['schema'] == 'fsmgen.inactive_runtime_reference_census.v1'
    assert type(value['runtime_authorized']) is int and value['runtime_authorized'] == 0
    assert value['executable'] is None
    assert value['retention'] == 'all_valid_runtime_records_retained; stale_owners_not_released'
    lock = value['lock']
    assert lock['path'].endswith('/coordination.lock')
    case = lock['path'].removesuffix('/coordination.lock')
    assert re.fullmatch(r'\.artifacts/tmp/native-proxy-image-custody/cases/fsmgen-[A-Za-z0-9_]+', case)
    assert type(lock['inode']) is int and lock['inode'] > 0 and lock['device'] == ROOT.stat().st_dev
    images = value['images']
    assert len(images) == 1 and images[0]['key'] == VECTOR['key']
    assert len(images[0]['snapshots']) == 3
    for snapshot, name, data in zip(images[0]['snapshots'], ('rustup.c', 'rustup', 'image.json'), BYTES):
        source(snapshot, f"{case}/images/{VECTOR['key']}/{name}", data)
    assert value['references']
    keys = []
    for entry in value['references']:
        raw = entry['source']['bytes']
        record = CODEC.validate(case, raw)
        assert record == entry['record']
        key = record['reference_key']
        keys.append(key)
        source(entry['source'], f'{case}/references/{key}.json', raw.encode('ascii'))
        assert record['image_key'] == VECTOR['key']
        assert record['workspace_identity'] == dict(path=record['workspace'], device=17, inode=99)
        for index, (historical, data) in enumerate(zip(record['selected_sources'], BYTES[:2])):
            assert historical['size_bytes'] == len(data)
            assert historical['sha256'] == hashlib.sha256(data).hexdigest()
            assert historical['device'] == 17 and historical['inode'] == 100 + index
    assert len(keys) == len(set(keys))


def absence(cases: list) -> None:
    assert cases and len(cases) == len(set(cases))
    for case in cases:
        assert re.fullmatch(r'\.artifacts/tmp/native-proxy-image-custody/cases/fsmgen-[A-Za-z0-9_]+', case)
        path = ROOT / case
        assert not path.exists() and not path.is_symlink()


def validate(result: dict) -> None:
    assert result['success'] is True
    assert type(result['forbidden_process_attempts']) is int and result['forbidden_process_attempts'] == 0
    census(result['positive'])
    assert len(result['positive']['references']) == 2
    assert {entry['record']['workspace'] for entry in result['positive']['references']} == {
        '.artifacts/tmp/process-supervisor-tests/fsmgen-Census20260910' + suffix for suffix in ('A', 'B')}
    controls = result['controls']
    assert len(controls) == len({row['name'] for row in controls})
    assert all(row['rejected'] == 1 and row['expected_diagnostic'] == 1 and row['returned_result'] == 0 for row in controls)
    assert {'merged runtime fields', 'wrong reference content digest', 'wrong reference content length',
            'dangling referenced image', 'unknown observation format', 'reference wrong_filename',
            'reference partial', 'reference duplicate', 'closure reference_replaced',
            'closure reference_bytes_changed', 'closure reference_added', 'closure image_replaced',
            'closure image_directory_replaced', 'reference capacity exceeded',
            'direct inspection bypass', 'caller callback rejected'} <= {row['name'] for row in controls}
    expected = {CODEC.key('.artifacts/tmp/process-supervisor-tests/fsmgen-Census20260910Cap' + str(index))
                for index in range(128)}
    keys = result['capacity']['keys']
    assert len(keys) == 128 and set(keys) == expected
    assert result['incomplete']['retained_unreferenced_partial'] == 1
    absence(result['retired_cases'])
    assert result['capacity']['case'] in result['retired_cases']
    assert result['incomplete']['case'] in result['retired_cases']
    assert {row['kind'] for row in result['mutants']} == {'content', 'filename'}
    assert len(result['mutants']) == 2
    for row in result['mutants']:
        try:
            census(row['accepted'])
        except AssertionError:
            pass
        else:
            raise AssertionError(f"independent oracle missed {row['kind']} mutant")


def main() -> None:
    result = json.loads((LOG / 'qualification.json').read_bytes())
    validate(result)
    initial = json.loads((LOG / 'initial-harness.json').read_bytes())
    assert initial['success'] is False and initial['forbidden_process_attempts'] == 0
    failed = [row for row in initial['controls'] if not row['expected_diagnostic']]
    assert len(failed) == 1 and failed[0]['name'] == 'merged runtime fields'
    assert all(row['rejected'] == 1 and row['returned_result'] == 0 for row in initial['controls'])
    first_tap = (LOG / 'initial-harness.tap').read_text()
    assert re.findall(r'^not ok ([0-9]+) - ', first_tap, re.M) == ['13']
    absence(initial['retired_cases'])
    coordination = json.loads((LOG / 'coordination-regression.json').read_bytes())
    publication = json.loads((LOG / 'publication-regression.json').read_bytes())
    COORDINATION.validate(coordination)
    PUBLICATION.validate(publication, VECTOR, BYTES)
    all_cases = [*initial['retired_cases'], *result['retired_cases'],
                 *coordination['retired_cases'], *publication['retired_cases']]
    absence(all_cases)
    falsifiers = []
    for name, mutate in (
        ('hidden failure', lambda x: x.update(success=False)),
        ('dropped stale owner', lambda x: x['positive']['references'].pop()),
        ('runtime authority', lambda x: x['positive'].update(runtime_authorized=1)),
        ('runnable result', lambda x: x['positive'].update(executable='rustup')),
        ('incomplete capacity census', lambda x: x['capacity']['keys'].pop()),
        ('discarded partial state', lambda x: x['incomplete'].update(retained_unreferenced_partial=0)),
        ('omitted counterimplementation', lambda x: x.update(mutants=[])),
    ):
        altered = copy.deepcopy(result)
        mutate(altered)
        try:
            validate(altered)
        except AssertionError:
            falsifiers.append(name)
        else:
            raise AssertionError(f'counterfactual accepted: {name}')
    paths = [BASE / name for name in ('ReferenceCensus.pm', 'qualify.t')]
    paths += [BASE.parent / 'native-proxy-image-coordination-20260910/Coordination.pm']
    paths += [LOG / name for name in ('qualification.json', 'qualify.tap', 'initial-harness.json',
        'initial-harness.tap', 'coordination-regression.json', 'coordination-regression.tap',
        'publication-regression.json', 'publication-regression.tap')]
    report = dict(schema='fsmgen.inactive_runtime_reference_census_audit.v1', success=True,
        assertions=CODEC.tap_count((LOG / 'qualify.tap').read_text()),
        coordination_assertions=CODEC.tap_count((LOG / 'coordination-regression.tap').read_text()),
        publication_assertions=CODEC.tap_count((LOG / 'publication-regression.tap').read_text()),
        rejection_controls=len(result['controls']), retained_capacity_keys=len(result['capacity']['keys']),
        retired_cases=dict(initial=len(initial['retired_cases']), census=len(result['retired_cases']),
                           coordination=len(coordination['retired_cases']), publication=len(publication['retired_cases'])),
        falsifiers=falsifiers,
        inputs=[dict(path=str(path.relative_to(ROOT)), size_bytes=path.stat().st_size,
                     sha256=hashlib.sha256(path.read_bytes()).hexdigest()) for path in paths],
        limits=['All images and references are inert qualification fixtures, never compiled or executed.',
                'Absent synthetic workspaces and historical IDs do not authorize reference release.',
                'Only referenced image content is admitted; unreferenced partial data remains for owned recovery.',
                'Snapshots are dated, not ongoing immutability or loaded-image attestation.',
                'Global/private acquisition, observation formats/lifetimes, retirement, maintenance, '
                'actual contention and native behavior remain unqualified.'])
    (LOG / 'audit.json').write_text(json.dumps(report, sort_keys=True, indent=2) + '\n')
    print(json.dumps({key: report[key] for key in ('success', 'assertions', 'coordination_assertions',
          'publication_assertions', 'rejection_controls', 'retained_capacity_keys', 'retired_cases')}, sort_keys=True))


if __name__ == '__main__':
    main()
