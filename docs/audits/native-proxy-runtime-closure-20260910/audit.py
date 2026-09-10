"""Independent prospective cut matrix and filesystem-footprint oracle."""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-runtime-closure-20260910'
PAYLOADS = ['c', 'manifest', 'executable', 'global', 'private']
NORMAL = ['before_write', 'before_seal', 'after_seal', 'after_write']
CUTS = ['before_write', 'partial_write', 'before_seal', 'after_seal', 'after_write']


def build_plan() -> dict:
    rows = []
    for route in ('fresh', 'reuse'):
        steps = PAYLOADS if route == 'fresh' else PAYLOADS[3:]
        initial = {} if route == 'fresh' else {'c': 'complete', 'manifest': 'complete', 'executable': 'sealed'}
        prefix = []
        complete = dict(initial)
        for payload in steps:
            for cut in CUTS:
                state = dict(complete)
                if cut != 'before_write':
                    state[payload] = ('partial' if cut == 'partial_write' else
                        'sealed' if payload == 'executable' and cut in ('after_seal', 'after_write') else 'complete')
                events = ['before_write', 'partial_write'] if cut == 'partial_write' else NORMAL[:NORMAL.index(cut) + 1]
                rows.append(dict(id=f'{route}:{payload}:{cut}', route=route, payload=payload, cut=cut,
                    expected_trace=prefix + [f'{payload}:{event}' for event in events],
                    expected_files=state, returns=False))
            complete[payload] = 'sealed' if payload == 'executable' else 'complete'
            prefix += [f'{payload}:{event}' for event in NORMAL]
        rows.append(dict(id=f'{route}:complete', route=route, payload=None, cut=None,
                         expected_trace=prefix, expected_files=complete, returns=True))
    return dict(schema='fsmgen.inactive_publication_reference_cut_plan.v1',
        owner='HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.2.2.3',
        partial_write_bytes=8, rows=rows,
        scope='Inert fresh/reuse acquisition only; preserve an earlier complete owner at every cut. '
              'No compiler, native fixture, original, collector or actual contention worker.',
        missing_legs=['runtime retirement and maintenance', 'observation snapshots and lifetime',
                      'real cross-language contention', 'native behavior and historical startup repair'])


def load_acquisition():
    spec = importlib.util.spec_from_file_location('closure_acquisition_audit',
        BASE.parent / 'native-proxy-runtime-acquisition-20260910/audit.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


ACQUISITION = load_acquisition()
CODEC = ACQUISITION.CODEC
C, IMAGE = ACQUISITION.C, ACQUISITION.IMAGE


def snapshot(value: dict, path: str, data: bytes, mode: str) -> None:
    assert type(value) is dict and set(value) == {'path', 'bytes', 'size_bytes', 'sha256',
        'device', 'inode', 'uid', 'links', 'mode'}
    assert value['path'] == path and type(value['bytes']) is str and value['bytes'].encode('latin1') == data
    assert type(value['size_bytes']) is int and value['size_bytes'] == len(data)
    assert value['sha256'] == hashlib.sha256(data).hexdigest() and value['mode'] == mode
    assert type(value['device']) is int and value['device'] == ROOT.stat().st_dev
    assert type(value['inode']) is int and value['inode'] > 0
    assert type(value['links']) is int and value['links'] == 1
    assert type(value['uid']) is int and value['uid'] == os.getuid()


def identity(snapshot: dict) -> dict:
    return {name: snapshot[name] for name in ('path', 'device', 'inode', 'size_bytes', 'sha256')}


def expected_record(case: str, workspace: dict, key: str, files: dict) -> bytes:
    record = dict(schema='fsmgen.test.rust_proxy_image_reference.v1',
        reference_key=CODEC.key(workspace['path']), image_key=key,
        workspace=workspace['path'], workspace_identity=workspace,
        selected_sources=[identity(files[name]) for name in ('c', 'executable')])
    raw = CODEC.canonical(record)
    assert CODEC.validate(case, raw) == record
    return raw.encode('ascii')


def validate_files(case: str, workspace: dict, key: str, files: dict, state: dict, image: bytes) -> None:
    assert set(files) == set(state)
    computed, manifest = ACQUISITION.expected_image(image)
    assert key == computed
    paths = dict(c=f'{case}/images/{key}/rustup.c', manifest=f'{case}/images/{key}/image.json',
                 executable=f'{case}/images/{key}/rustup',
                 global_=f"{case}/references/{CODEC.key(workspace['path'])}.json",
                 private=workspace['path'] + '/rust-tools/image-reference.json')
    paths['global'] = paths.pop('global_')
    expected = dict(c=C, manifest=manifest, executable=image)
    if 'global' in state or 'private' in state:
        record = expected_record(case, workspace, key, files)
        expected.update({'global': record, 'private': record})
    for name, shape in state.items():
        data = expected[name][:8] if shape == 'partial' else expected[name]
        mode = '0500' if name == 'executable' and shape == 'sealed' else '0400'
        snapshot(files[name], paths[name], data, mode)


def validate(result: dict, plan: dict) -> None:
    assert result['complete'] is True and result['success'] is True
    assert type(result['forbidden_process_attempts']) is int and result['forbidden_process_attempts'] == 0
    owned = ACQUISITION.allocations(result)
    rows = result['rows']
    assert [row['id'] for row in rows] == [row['id'] for row in plan['rows']]
    assert len({row['case'] for row in rows}) == len(rows)
    assert {row['case'] for row in rows} == set(result['retired_cases'])
    used_workspaces = set()
    for row, cut in zip(rows, plan['rows']):
        case = row['case']
        for workspace in (row['prior_workspace'], row['target_workspace']):
            assert workspace == {name: owned[workspace['path']][name] for name in ('path', 'device', 'inode')}
            assert owned[workspace['path']]['kind'] == 'workspace'
            assert workspace['path'] not in used_workspaces
            used_workspaces.add(workspace['path'])
        assert owned[case]['kind'] == 'store'
        assert row['trace'] == cut['expected_trace']
        expected_error = '' if cut['returns'] else f"injected matrix {cut['payload']}:{cut['cut']}\n"
        assert row['error'] == expected_error
        prior_key, _ = ACQUISITION.expected_image(IMAGE)
        prior_state = {name: ('sealed' if name == 'executable' else 'complete') for name in PAYLOADS}
        validate_files(case, row['prior_workspace'], prior_key, row['prior_before'], prior_state, IMAGE)
        assert row['prior_before'] == row['prior_after']
        image = IMAGE + b'matrix-new' if cut['route'] == 'fresh' else IMAGE
        validate_files(case, row['target_workspace'], row['image_key'], row['target'], cut['expected_files'], image)
        if cut['route'] == 'reuse':
            assert all(row['target'][name] == row['prior_before'][name] for name in ('c', 'manifest', 'executable'))
        if cut['returns']:
            ACQUISITION.acquisition(row['result'], owned, image)
            assert row['result']['created'] == (1 if cut['route'] == 'fresh' else 0)
            assert row['result']['reference']['record']['workspace'] == row['target_workspace']['path']
            for source, name in zip(row['result']['image']['snapshots'], ('c', 'executable', 'manifest')):
                assert source['identity'] == identity(row['target'][name]) and source['bytes'] == row['target'][name]['bytes']
            for name in ('global', 'private'):
                assert row['result']['reference'][name]['identity'] == identity(row['target'][name])
                assert row['result']['reference'][name]['bytes'] == row['target'][name]['bytes']
        else:
            assert row['result'] is None
    assert used_workspaces == set(result['retired_workspaces'])


def main() -> None:
    if sys.argv[1:] == ['--plan']:
        plan = build_plan()
        (BASE / 'plan.json').write_text(json.dumps(plan, sort_keys=True, indent=2) + '\n')
        print(json.dumps(dict(rows=len(plan['rows']), routes=sorted({row['route'] for row in plan['rows']})), sort_keys=True))
        return
    assert not sys.argv[1:]
    plan = build_plan()
    assert json.loads((BASE / 'plan.json').read_bytes()) == plan
    result = json.loads((LOG / 'qualification.json').read_bytes())
    validate(result, plan)
    ledger = [json.loads(line) for line in (LOG / 'admission.jsonl').read_text().splitlines()]
    assert ledger == result['allocated']
    initial = (LOG / 'initial-compile.tap').read_text()
    assert 'syntax error' in initial and 'aborted due to compilation errors' in initial
    assert not re.search(r'^(?:ok|not ok) [0-9]+', initial, re.M)
    regression = json.loads((LOG / 'acquisition-regression.json').read_bytes())
    ACQUISITION.validate(regression)
    regression_ledger = [json.loads(line) for line in (LOG / 'acquisition-regression-admission.jsonl').read_text().splitlines()]
    assert regression_ledger == regression['allocated']
    assert not set(result['retired_cases']) & set(regression['retired_cases'])
    assert not set(result['retired_workspaces']) & set(regression['retired_workspaces'])
    falsifiers = []
    def row(value, key):
        return next(item for item in value['rows'] if item['id'] == key)
    for name, mutate in (
        ('incomplete run', lambda x: x.update(complete=False)),
        ('omitted cut', lambda x: x['rows'].pop()),
        ('changed prior owner', lambda x: x['rows'][0]['prior_after']['global'].update(inode=1)),
        ('returned after interruption', lambda x: x['rows'][0].update(result={})),
        ('missing partial bytes', lambda x: row(x, 'fresh:c:partial_write')['target']['c'].update(bytes='')),
        ('premature executable permission', lambda x: row(x, 'fresh:executable:partial_write')['target']['executable'].update(mode='0500')),
        ('lost global retention', lambda x: row(x, 'fresh:private:before_write')['target'].pop('global')),
        ('rewritten reuse source', lambda x: row(x, 'reuse:complete')['target']['c'].update(inode=1)),
        ('altered transition prefix', lambda x: x['rows'][0].update(trace=[])),
        ('missing allocation', lambda x: x['allocated'].pop()),
    ):
        altered = copy.deepcopy(result)
        mutate(altered)
        try:
            validate(altered, plan)
        except (AssertionError, KeyError):
            falsifiers.append(name)
        else:
            raise AssertionError(f'counterfactual accepted: {name}')
    paths = [BASE / name for name in ('plan.json', 'qualify.t')]
    paths += [LOG / name for name in ('qualification.json', 'qualify.tap', 'admission.jsonl',
                                     'initial-compile.tap', 'initial-compile.t.source',
                                     'acquisition-regression.json', 'acquisition-regression.tap',
                                     'acquisition-regression-admission.jsonl')]
    report = dict(schema='fsmgen.inactive_publication_reference_cut_audit.v1', success=True,
        assertions=CODEC.tap_count((LOG / 'qualify.tap').read_text()),
        regression_assertions=CODEC.tap_count((LOG / 'acquisition-regression.tap').read_text()),
        cases=len(result['rows']), cuts=sum(not item['returns'] for item in plan['rows']),
        successful_routes=sum(item['returns'] for item in plan['rows']),
        partial_write_cuts=sum(item['cut'] == 'partial_write' for item in plan['rows']),
        retired_stores=len(result['retired_cases']), retired_workspaces=len(result['retired_workspaces']),
        regression_stores=len(regression['retired_cases']), regression_workspaces=len(regression['retired_workspaces']),
        falsifiers=falsifiers,
        inputs=[dict(path=str(path.relative_to(ROOT)), size_bytes=path.stat().st_size,
                     sha256=hashlib.sha256(path.read_bytes()).hexdigest()) for path in paths],
        limits=['Fixed deterministic cuts over inert filesystem publication/acquisition, not actual process crashes or power-loss durability.',
                'Every cut preserves an earlier complete owner and withholds a returned acquisition result.',
                'Partial executable writes remain nonexecutable; complete post-seal files can remain without runtime authority.',
                'No compiler/native/original/collector or actual contention worker is launched.',
                'Observer lifetime, retirement, maintenance, actual coordination workers and native behavior remain unqualified.'])
    (LOG / 'audit.json').write_text(json.dumps(report, sort_keys=True, indent=2) + '\n')
    print(json.dumps({name: report[name] for name in ('success', 'assertions', 'regression_assertions',
        'cases', 'cuts', 'successful_routes', 'partial_write_cuts', 'retired_stores', 'retired_workspaces')}, sort_keys=True))


if __name__ == '__main__':
    main()
