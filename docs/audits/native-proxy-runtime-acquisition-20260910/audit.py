"""Independent reconstruction of inactive reference acquisition and cleanup."""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import re

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-runtime-acquisition-20260910'


def load(name: str, directory: str):
    spec = importlib.util.spec_from_file_location(name, BASE.parent / directory / 'audit.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


CODEC = load('acquisition_codec_audit', 'native-proxy-runtime-records-20260910')
CENSUS = load('acquisition_census_audit', 'native-proxy-runtime-census-20260910')
VECTOR = json.loads((BASE.parent / 'native-proxy-image-custody-20260910/vectors.json').read_bytes())
C, IMAGE, _ = CENSUS.CUSTODY.vectors(VECTOR)


def expected_image(image: bytes) -> tuple[str, bytes]:
    key = hashlib.sha256(b'fsmgen.rust_proxy_image.v1\0' + len(C).to_bytes(8, 'big') + C
                         + len(image).to_bytes(8, 'big') + image).hexdigest()
    manifest = CODEC.canonical(dict(schema='fsmgen.test.rust_proxy_image.v1', key=key,
        generated_c=dict(size_bytes=len(C), sha256=hashlib.sha256(C).hexdigest()),
        executable=dict(size_bytes=len(image), sha256=hashlib.sha256(image).hexdigest()))).encode('ascii')
    return key, manifest


def acquisition(value: dict, allocations: dict, image: bytes = IMAGE) -> None:
    assert value['schema'] == 'fsmgen.inactive_runtime_reference_acquisition.v1'
    assert type(value['runtime_authorized']) is int and value['runtime_authorized'] == 0
    assert value['executable'] is None and type(value['created']) is int and value['created'] in (0, 1)
    lock = value['lock']
    assert lock['path'].endswith('/coordination.lock')
    case = lock['path'].removesuffix('/coordination.lock')
    assert allocations[case]['kind'] == 'store'
    assert type(lock['inode']) is int and lock['inode'] > 0 and lock['device'] == ROOT.stat().st_dev
    key, manifest = expected_image(image)
    assert value['image']['key'] == key and len(value['image']['snapshots']) == 3
    for snapshot, name, data in zip(value['image']['snapshots'], ('rustup.c', 'rustup', 'image.json'), (C, image, manifest)):
        CENSUS.source(snapshot, f'{case}/images/{key}/{name}', data)
    reference = value['reference']
    raw = reference['global']['bytes']
    record = CODEC.validate(case, raw)
    assert record == reference['record'] and record['image_key'] == key
    expected_workspace = allocations[record['workspace']]
    assert expected_workspace['kind'] == 'workspace'
    assert record['workspace_identity'] == {name: expected_workspace[name] for name in ('path', 'device', 'inode')}
    assert record['selected_sources'] == [source['identity'] for source in value['image']['snapshots'][:2]]
    assert raw == reference['private']['bytes']
    for source, path in ((reference['global'], f"{case}/references/{record['reference_key']}.json"),
                         (reference['private'], record['workspace'] + '/rust-tools/image-reference.json')):
        CENSUS.source(source, path, raw.encode('ascii'))
    assert reference['global']['identity']['inode'] != reference['private']['identity']['inode']


def allocations(result: dict) -> dict:
    rows = result['allocated']
    assert len(rows) == len({row['path'] for row in rows})
    cases, workspaces = set(result['retired_cases']), set(result['retired_workspaces'])
    assert len(cases) == len(result['retired_cases']) and len(workspaces) == len(result['retired_workspaces'])
    assert cases and len(workspaces) == 2 * len(cases)
    assert cases == {row['path'] for row in rows if row['kind'] == 'store'}
    assert workspaces == {row['path'] for row in rows if row['kind'] == 'workspace'}
    for row in rows:
        prefix = '.artifacts/tmp/native-proxy-image-custody/cases/' if row['kind'] == 'store' else '.artifacts/tmp/process-supervisor-tests/'
        assert row['kind'] in ('store', 'workspace')
        assert re.fullmatch(re.escape(prefix) + r'fsmgen-[A-Za-z0-9_]+', row['path'])
        assert type(row['device']) is int and row['device'] == ROOT.stat().st_dev
        assert type(row['inode']) is int and row['inode'] > 0
        path = ROOT / row['path']
        assert not path.exists() and not path.is_symlink()
        # Hostile workspace replacement uses this exact transient sibling and
        # removes the empty old root before returning to the checked closure.
        if row['kind'] == 'workspace':
            old = ROOT / (row['path'] + '_old')
            assert not old.exists() and not old.is_symlink()
    return {row['path']: row for row in rows}


def validate(result: dict) -> None:
    assert result['success'] is True
    assert type(result['forbidden_process_attempts']) is int and result['forbidden_process_attempts'] == 0
    owned = allocations(result)
    for value in (result['first'], result['reuse'], result['different']['first']):
        acquisition(value, owned)
    acquisition(result['different']['second'], owned, IMAGE + b'different')
    assert result['first']['created'] == 1 and result['reuse']['created'] == 0
    assert result['first']['image'] == result['reuse']['image']
    assert result['first']['lock'] == result['reuse']['lock']
    assert result['first']['reference']['record']['reference_key'] != result['reuse']['reference']['record']['reference_key']
    controls = result['controls']
    assert len(controls) == len({row['name'] for row in controls})
    assert all(row['rejected'] == 1 and row['expected_diagnostic'] == 1 and row['returned_result'] == 0 for row in controls)
    assert {'duplicate global ownership', 'admission stale_inode', 'admission malformed_global',
            'admission private_exists', 'admission private_symlink', 'reference capacity before new publication',
            'new image capacity', 'global without private is not reacquired', 'closure workspace_root',
            'closure tools_directory', 'closure private_inode', 'closure prior_record', 'closure prior_image',
            'direct admission bypass', 'direct acquisition bypass', 'direct closure bypass'} <= {row['name'] for row in controls}
    interruptions = result['interruptions']
    expected_states = {'before_global': (0, 0), 'after_global': (1, 0),
                       'before_private': (1, 0), 'after_private': (1, 1)}
    assert len(interruptions) == 4 and {row['boundary'] for row in interruptions} == set(expected_states)
    for row in interruptions:
        assert (row['global_present'], row['private_present']) == expected_states[row['boundary']]
        assert owned[row['case']]['kind'] == 'store' and owned[row['workspace']]['kind'] == 'workspace'
        for side in ('global', 'private'):
            if row[f'{side}_present']:
                record = CODEC.validate(row['case'], row[f'{side}_bytes'])
                assert record['workspace'] == row['workspace'] and record['image_key'] == VECTOR['key']
            else:
                assert f'{side}_bytes' not in row
        if row['private_present']:
            assert row['private_bytes'] == row['global_bytes']
    capacity = result['capacity']
    expected_keys = {CODEC.key('.artifacts/tmp/process-supervisor-tests/fsmgen-AcquisitionCapacity' + str(i)) for i in range(127)}
    expected_keys.add(CODEC.key(capacity['original_workspace']))
    assert len(capacity['keys']) == 128 and set(capacity['keys']) == expected_keys
    assert owned[capacity['case']]['kind'] == 'store'
    mutants = result['mutants']
    assert len(mutants) == 2 and {row['kind'] for row in mutants} == {'workspace_closure', 'sealed_identity'}
    for mutant in mutants:
        value = mutant['accepted']
        acquisition(value, owned)
        if mutant['kind'] == 'workspace_closure':
            returned = value['reference']['record']['workspace_identity']
            current = mutant['current_workspace']
            assert current['path'] == returned['path'] and current['device'] == returned['device']
            assert type(current['inode']) is int and current['inode'] > 0 and current['inode'] != returned['inode']
        else:
            original = mutant['original_private_identity']
            returned = value['reference']['private']['identity']
            assert original['device'] == returned['device'] and original['inode'] != returned['inode']


def main() -> None:
    result = json.loads((LOG / 'qualification.json').read_bytes())
    validate(result)
    ledger = [json.loads(line) for line in (LOG / 'admission.jsonl').read_text().splitlines()]
    assert ledger == result['allocated']
    first = (LOG / 'initial-harness.tap').read_text()
    assert re.findall(r'^not ok ([0-9]+) - ', first, re.M) == ['48', '50', '52', '54', '56', '58', '60']
    assert 'reference closure requires the sealed coordinator' in first
    assert not re.search(r'^1\.\.', first, re.M)
    initial_census = json.loads((LOG / 'initial-failure-namespace-census.json').read_bytes())
    assert set(initial_census) == {'.artifacts/tmp/native-proxy-image-custody/cases', '.artifacts/tmp/process-supervisor-tests'}
    assert all(value['members'] == [] and value['device'] == ROOT.stat().st_dev for value in initial_census.values())
    regressions = {}
    for kind, auditor in [('coordination', CENSUS.COORDINATION), ('publication', CENSUS.PUBLICATION), ('census', CENSUS)]:
        value = json.loads((LOG / f'{kind}-regression.json').read_bytes())
        if kind == 'publication':
            auditor.validate(value, VECTOR, CENSUS.BYTES)
        else:
            auditor.validate(value)
        regressions[kind] = value
    all_cases = [*result['retired_cases'], *regressions['coordination']['retired_cases'],
                 *regressions['publication']['retired_cases'], *regressions['census']['retired_cases']]
    CENSUS.absence(all_cases)
    falsifiers = []
    for name, mutate in (
        ('hidden failure', lambda x: x.update(success=False)),
        ('runtime authority', lambda x: x['first'].update(runtime_authorized=1)),
        ('runnable result', lambda x: x['reuse'].update(executable='rustup')),
        ('lost global pin', lambda x: x['interruptions'][1].update(global_present=0)),
        ('different private bytes', lambda x: x['first']['reference']['private'].update(bytes='{}')),
        ('missing allocation', lambda x: x['allocated'].pop()),
        ('incomplete capacity census', lambda x: x['capacity']['keys'].pop()),
        ('missed stale workspace mutant', lambda x: x['mutants'][0]['current_workspace'].update(
            inode=x['mutants'][0]['accepted']['reference']['record']['workspace_identity']['inode'])),
    ):
        altered = copy.deepcopy(result)
        mutate(altered)
        try:
            validate(altered)
        except (AssertionError, KeyError):
            falsifiers.append(name)
        else:
            raise AssertionError(f'counterfactual accepted: {name}')
    paths = [BASE / name for name in ('ReferenceAcquisition.pm', 'qualify.t')]
    paths += [BASE.parent / 'native-proxy-image-coordination-20260910/Coordination.pm']
    paths += [LOG / name for name in ('qualification.json', 'qualify.tap', 'admission.jsonl',
        'initial-harness.tap', 'initial-harness.t.source', 'initial-failure-namespace-census.json',
        'coordination-regression.json', 'coordination-regression.tap', 'publication-regression.json',
        'publication-regression.tap', 'census-regression.json', 'census-regression.tap')]
    report = dict(schema='fsmgen.inactive_runtime_reference_acquisition_audit.v1', success=True,
        assertions=CODEC.tap_count((LOG / 'qualify.tap').read_text()), rejection_controls=len(result['controls']),
        regression_assertions={kind: CODEC.tap_count((LOG / f'{kind}-regression.tap').read_text()) for kind in regressions},
        retired_cases=dict(acquisition=len(result['retired_cases']), **{kind: len(value['retired_cases']) for kind, value in regressions.items()}),
        retired_workspaces=len(result['retired_workspaces']), allocations=len(ledger), falsifiers=falsifiers,
        inputs=[dict(path=str(path.relative_to(ROOT)), size_bytes=path.stat().st_size,
                     sha256=hashlib.sha256(path.read_bytes()).hexdigest()) for path in paths],
        limits=['Inert record acquisition only, with no compiler, native fixture, original, collector or contention worker.',
                'Initial harness abort has no final JSON/allocation roster; the immediate census independently proves both whole fixture namespaces empty.',
                'Final allocation ledger and result agree; each exact owned store/workspace and replacement transient is absent.',
                'Source snapshots and IDs are dated observations, not loaded-image attestation or arbitrary concurrent-writer protection.',
                'Combined interruption closure, observation lifetimes, retirement, maintenance, actual contention and native behavior remain separately unqualified.'])
    (LOG / 'audit.json').write_text(json.dumps(report, sort_keys=True, indent=2) + '\n')
    print(json.dumps({name: report[name] for name in ('success', 'assertions', 'rejection_controls',
        'regression_assertions', 'retired_cases', 'retired_workspaces', 'allocations')}, sort_keys=True))


if __name__ == '__main__':
    main()
