"""Independent complete-image maintenance and conservative retention oracle."""
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
LOG = ROOT / '.artifacts/logs/native-proxy-image-maintenance-20260910'


def build_plan() -> dict:
    paths = ['rustup.c', 'image.json', 'rustup', '']
    trace = [dict(path=path, phase=phase) for path in paths for phase in ('before', 'after')]
    cases = []
    for index, cut in enumerate(trace):
        removed = paths[:(index + 1) // 2]
        cases.append(dict(name=f"{cut['phase']} {cut['path'] or 'DIRECTORY'}", cut=cut,
                          trace=trace[:index + 1], removed=removed, returned=0))
    cases.append(dict(name='complete', cut=None, trace=trace, removed=paths, returned=1))
    return dict(schema='fsmgen.inactive_image_maintenance_plan.v1', cases=cases,
                limits='Only inert images under the isolated qualification store; deterministic deletion '
                       'cuts do not establish actual crash/power-loss or observer/native lifecycle behavior.')


def load(name: str, directory: str):
    spec = importlib.util.spec_from_file_location(name, BASE.parent / directory / 'audit.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def tap_count(raw: str) -> int:
    assert not re.search(r'^(?:not ok|Bail out!)', raw, re.M)
    plans = re.findall(r'^1\.\.([0-9]+)$', raw, re.M)
    assert len(plans) == 1
    total = int(plans[0])
    assert [int(n) for n in re.findall(r'^ok ([0-9]+) - ', raw, re.M)] == list(range(1, total + 1))
    return total


def expected_image(c: bytes, executable: bytes) -> tuple[str, bytes]:
    key = hashlib.sha256(b'fsmgen.rust_proxy_image.v1\0' + len(c).to_bytes(8, 'big') + c
                         + len(executable).to_bytes(8, 'big') + executable).hexdigest()
    manifest = dict(schema='fsmgen.test.rust_proxy_image.v1', key=key,
                    generated_c=dict(size_bytes=len(c), sha256=hashlib.sha256(c).hexdigest()),
                    executable=dict(size_bytes=len(executable), sha256=hashlib.sha256(executable).hexdigest()))
    return key, json.dumps(manifest, sort_keys=True, separators=(',', ':')).encode('ascii')


def check_image(nodes: dict, c: bytes, executable: bytes) -> str:
    key, manifest = expected_image(c, executable)
    prefix = f'images/{key}'
    assert nodes[prefix]['kind'] == 'directory' and nodes[prefix]['mode'] == 0o700
    for name, raw, mode in [('rustup.c', c, 0o400), ('rustup', executable, 0o500), ('image.json', manifest, 0o400)]:
        node = nodes[f'{prefix}/{name}']
        assert node['kind'] == 'file' and node['links'] == 1 and node['mode'] == mode
        assert node['bytes'] == len(raw) and node['sha256'] == hashlib.sha256(raw).hexdigest()
    return key


def validate(result: dict, plan: dict) -> None:
    assert result['success'] is True and type(result['forbidden_process_attempts']) is int
    assert result['forbidden_process_attempts'] == 0
    vector = json.loads((BASE.parent / 'native-proxy-image-custody-20260910/vectors.json').read_bytes())
    c, image = (bytes.fromhex(vector[name]) for name in ('generated_c_hex', 'image_hex'))
    acquired = load('maintenance_acquisition_oracle', 'native-proxy-runtime-acquisition-20260910')
    allocations = {row['path']: row for row in result['allocated']}
    assert len(allocations) == len(result['allocated'])
    assert list(allocations.values()) == [json.loads(line) for line in (LOG / 'admission.jsonl').read_text().splitlines()]
    assert len(result['cuts']) == len(plan['cases'])
    for row, expected in zip(result['cuts'], plan['cases']):
        assert row['name'] == expected['name'] and row['trace'] == expected['trace']
        assert row['returned'] == expected['returned']
        assert row['error'] == ('' if expected['returned'] else 'selected maintenance cut\n')
        candidate = check_image(row['before'], c, image)
        held_key = check_image(row['before'], c, image + b'held')
        assert candidate != held_key and row['candidate'] == candidate
        acquired.acquisition(row['held'], allocations, image + b'held')
        assert row['held_workspace_absent'] == 1
        prefix = f'images/{candidate}'
        removed = {f'{prefix}/{path}' if path else prefix for path in expected['removed']}
        assert row['after'] == {key: value for key, value in row['before'].items() if key not in removed}
        if expected['returned']:
            assert row['result']['schema'] == 'fsmgen.inactive_image_maintenance.v1'
            assert row['result']['runtime_authorized'] == 0 and row['result']['executable'] is None
            assert row['result']['removed_image'] == candidate
        ref = row['held']['reference']['global']
        relative = ref['identity']['path'].removeprefix(row['case'] + '/')
        assert row['after'][relative]['sha256'] == hashlib.sha256(ref['bytes'].encode('ascii')).hexdigest()
    controls = result['controls']
    assert len(controls) == len({row['name'] for row in controls})
    assert {'stale owner still pins selected image', 'absent selected image', 'unknown image name',
            'partial unreferenced other image', 'partial selected image', 'changed selected bytes',
            'runtime fields relabeled as observation', 'malformed reference', 'shared selected source',
            'absent lock cannot be recreated', 'unknown store member', 'invalid selected key',
            'extra argument', 'direct removal bypass'} <= {row['name'] for row in controls}
    assert all(row['rejected'] == 1 and row['diagnostic_matched'] == 1 and row['returned'] == 0
               and row['before'] == row['after'] for row in controls)
    late = result['late_changes']
    assert {row['name'] for row in late} == {'source_replaced', 'directory_replaced', 'late_member', 'directory_reappeared'}
    assert len(late) == 4
    for row in late:
        assert row['rejected'] == 1 and row['returned'] == 0 and row['diagnostic_matched'] == 1
        prefix = f"images/{row['candidate']}"
        assert {p: n for p, n in row['before'].items() if not p.startswith(prefix)} == {
            p: n for p, n in row['after'].items() if not p.startswith(prefix)}
        if row['name'] in ('source_replaced', 'directory_replaced'):
            assert row['after'] == row['injected']
        elif row['name'] == 'late_member':
            assert {p for p in row['after'] if p.startswith(prefix)} == {prefix, prefix + '/late-added'}
        else:
            assert {p for p in row['after'] if p.startswith(prefix)} == {prefix}
    capacity = result['capacity']
    expected_keys = {expected_image(c, image)[0], expected_image(c, image + b'held')[0]}
    expected_keys |= {expected_image(c, image + f'capacity{i}'.encode())[0] for i in range(30)}
    assert set(capacity['before_keys']) == expected_keys and len(expected_keys) == 32
    assert capacity['publication_before_rejected'] == 1
    candidate = expected_image(c, image)[0]
    assert set(capacity['after_maintenance_keys']) == expected_keys - {candidate}
    assert set(capacity['after_publication_keys']) == expected_keys - {candidate} | {expected_image(c, image + b'next')[0]}
    assert capacity['held_before'] == capacity['held_after']
    assert result['last_image']['remaining_images'] == [] and result['last_image']['references'] == []
    assert result['last_image']['lock_before'] == result['last_image']['lock_after']
    mutant = result['mutant']
    assert mutant['removed_despite_pin'] == 1 and mutant['reference_retained'] == 1 and mutant['returned'] == 0
    assert mutant['error_matches_missing_image'] == 1
    for path, row in allocations.items():
        assert row['kind'] in ('store', 'workspace')
        assert re.fullmatch(r'\.artifacts/tmp/(?:native-proxy-image-custody/cases|process-supervisor-tests)/fsmgen-[A-Za-z0-9_]+', path)
        assert row['device'] == ROOT.stat().st_dev and type(row['inode']) is int and row['inode'] > 0
        item = ROOT / path
        assert not item.exists() and not item.is_symlink()


def main() -> None:
    plan = build_plan()
    if sys.argv[1:] == ['--plan']:
        (BASE / 'plan.json').write_text(json.dumps(plan, sort_keys=True, indent=2) + '\n')
        print(f"fixed maintenance plan: {len(plan['cases'])} routes")
        return
    assert not sys.argv[1:]
    assert json.loads((BASE / 'plan.json').read_bytes()) == plan
    result = json.loads((LOG / 'qualification.json').read_bytes())
    validate(result, plan)
    retirement = load('maintenance_retirement_oracle', 'native-proxy-runtime-retirement-20260910')
    retirement.LOG = LOG / 'retirement-regression'
    regression = json.loads((retirement.LOG / 'qualification.json').read_bytes())
    retirement.validate_result(regression, retirement.build_plan())
    assert not ({row['path'] for row in result['allocated']} & {row['path'] for row in regression['allocated']})
    falsifiers = []
    for name, mutate in [
        ('missing cut', lambda x: x['cuts'].pop()),
        ('lost hold', lambda x: x['cuts'][0]['after'].pop(next(p for p in x['cuts'][0]['after'] if p.startswith('references/') ))),
        ('returned interruption', lambda x: x['cuts'][0].update(returned=1)),
        ('lost rejection', lambda x: x['controls'][0].update(rejected=0)),
        ('lost late-change control', lambda x: x['late_changes'].pop()),
        ('unproved capacity recovery', lambda x: x['capacity']['after_maintenance_keys'].pop()),
        ('hidden stale-pin deletion', lambda x: x['mutant'].update(removed_despite_pin=0)),
        ('lost allocation', lambda x: x['allocated'].pop()),
        ('process attempted', lambda x: x.update(forbidden_process_attempts=1)),
    ]:
        altered = copy.deepcopy(result)
        mutate(altered)
        try:
            validate(altered, plan)
        except AssertionError:
            falsifiers.append(name)
        else:
            raise AssertionError(f'counterfactual accepted: {name}')
    report = dict(schema='fsmgen.inactive_image_maintenance_audit.v1', success=True,
                  assertions=tap_count((LOG / 'qualify.tap').read_text()), deletion_cuts=len(plan['cases'])-1,
                  rejection_controls=len(result['controls']), late_changes=len(result['late_changes']),
                  allocations=len(result['allocated']), retirement_regression_assertions=tap_count((retirement.LOG / 'qualify.tap').read_text()),
                  regression_allocations=len(regression['allocated']), falsifiers=falsifiers, limits=plan['limits'])
    (LOG / 'audit.json').write_text(json.dumps(report, sort_keys=True, indent=2) + '\n')
    print(json.dumps(report, sort_keys=True))


if __name__ == '__main__':
    main()
