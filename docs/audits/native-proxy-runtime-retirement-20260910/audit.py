"""Prospective deletion cuts and independent filesystem retirement oracle."""
from __future__ import annotations

import copy
import base64
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-runtime-retirement-20260910'
NODES = ['', 'rust-tool-resolution', 'rust-tools', 'rust-tools/cargo',
         'rust-tools/compiler-cache', 'rust-tools/compiler-cache/cache.dat',
         'rust-tools/compiler-temp', 'rust-tools/compiler-temp/scratch.dat',
         'rust-tools/image-reference.json', 'rust-tools/rustup', 'rust-tools/rustup.c']


def build_plan() -> dict:
    removals = list(reversed(NODES)) + ['GLOBAL']
    trace = [dict(path=path, phase=phase) for path in removals for phase in ('before', 'after')]
    cases = []
    for index, step in enumerate(trace):
        completed = (index + 1) // 2
        cases.append(dict(name=f"{step['phase']} {step['path'] or 'ROOT'}", cut=step,
                          trace=trace[:index + 1], remaining=sorted(set(NODES) - set(removals[:completed])),
                          global_retained=int(completed < len(removals)), returned=0))
    cases.append(dict(name='complete', cut=None, trace=trace, remaining=[], global_retained=0, returned=1))
    return dict(schema='fsmgen.inactive_runtime_retirement_plan.v1', nodes=NODES, cases=cases,
                ceilings=dict(nodes=256, depth=8, regular_file_bytes=65536, total_regular_file_bytes=4194304),
                limits='Fixed inert filesystem profiles and deterministic exceptions; no actual process crash, '
                       'compiler output capacity, authenticated cleanup or product runtime authority.')


def tap_count(raw: str) -> int:
    assert not re.search(r'^(?:not ok|Bail out!)', raw, re.M)
    plans = re.findall(r'^1\.\.([0-9]+)$', raw, re.M)
    assert len(plans) == 1
    total = int(plans[0])
    assert [int(n) for n in re.findall(r'^ok ([0-9]+) - ', raw, re.M)] == list(range(1, total + 1))
    return total


def canonical(value: object) -> bytes:
    return json.dumps(value, sort_keys=True, ensure_ascii=True, separators=(',', ':')).encode('ascii')


def file_bytes(entry: dict, raw: bytes, mode: int) -> None:
    assert entry['kind'] == 'file' and entry['links'] == 1 and entry['mode'] == mode
    assert entry['bytes'] == len(raw) and entry['sha256'] == hashlib.sha256(raw).hexdigest()


def image_bytes(nodes: dict) -> tuple[str, bytes, bytes]:
    vector = json.loads((BASE.parent / 'native-proxy-image-custody-20260910/vectors.json').read_bytes())
    c, executable = (bytes.fromhex(vector[name]) for name in ('generated_c_hex', 'image_hex'))
    key = hashlib.sha256(b'fsmgen.rust_proxy_image.v1\0' + len(c).to_bytes(8, 'big') + c
                         + len(executable).to_bytes(8, 'big') + executable).hexdigest()
    manifest = canonical(dict(schema='fsmgen.test.rust_proxy_image.v1', key=key,
                              generated_c=dict(size_bytes=len(c), sha256=hashlib.sha256(c).hexdigest()),
                              executable=dict(size_bytes=len(executable), sha256=hashlib.sha256(executable).hexdigest())))
    assert set(nodes) == {'', key, f'{key}/rustup.c', f'{key}/rustup', f'{key}/image.json'}
    for node in nodes.values():
        assert type(node['device']) is int and node['device'] == ROOT.stat().st_dev
        assert type(node['inode']) is int and node['inode'] > 0 and node['uid'] == os.getuid()
    for path in ('', key):
        assert nodes[path]['kind'] == 'directory' and nodes[path]['mode'] == 0o700
    for name, raw, mode in [('rustup.c', c, 0o400), ('rustup', executable, 0o500), ('image.json', manifest, 0o400)]:
        file_bytes(nodes[f'{key}/{name}'], raw, mode)
    return key, c, executable


def workspace_bytes(nodes: dict, case: str, workspace: str, image: dict) -> bytes:
    key, c, executable = image_bytes(image)
    assert set(nodes) == set(NODES)
    assert re.fullmatch(r'\.artifacts/tmp/native-proxy-image-custody/cases/fsmgen-[A-Za-z0-9_]+', case)
    assert re.fullmatch(r'\.artifacts/tmp/process-supervisor-tests/fsmgen-[A-Za-z0-9_]+', workspace)
    sources = [dict(path=f'{case}/images/{key}/{name}', device=image[f'{key}/{name}']['device'],
                    inode=image[f'{key}/{name}']['inode'], size_bytes=image[f'{key}/{name}']['bytes'],
                    sha256=image[f'{key}/{name}']['sha256']) for name in ('rustup.c', 'rustup')]
    record = canonical(dict(schema='fsmgen.test.rust_proxy_image_reference.v1',
                            reference_key=hashlib.sha256(b'fsmgen.rust_proxy_reference.runtime.v1\0' + workspace.encode()).hexdigest(),
                            image_key=key, workspace=workspace,
                            workspace_identity=dict(path=workspace, device=nodes['']['device'], inode=nodes['']['inode']),
                            selected_sources=sources))
    for node in nodes.values():
        assert node['device'] == ROOT.stat().st_dev and node['uid'] == os.getuid()
        assert type(node['inode']) is int and node['inode'] > 0
    for path in ('', 'rust-tools', 'rust-tools/compiler-cache', 'rust-tools/compiler-temp'):
        assert nodes[path]['kind'] == 'directory' and nodes[path]['mode'] == 0o700
    link = nodes['rust-tools/cargo']
    assert link['kind'] == 'symlink' and link['target'] == '../../inert-dangling-target'
    for path, raw, mode in [('rust-tool-resolution', b'inert wrapper; never executed', 0o700),
                            ('rust-tools/compiler-cache/cache.dat', b'inert cache', 0o400),
                            ('rust-tools/compiler-temp/scratch.dat', b'inert scratch', 0o600),
                            ('rust-tools/rustup.c', c, 0o400), ('rust-tools/rustup', executable, 0o500),
                            ('rust-tools/image-reference.json', record, 0o400)]:
        file_bytes(nodes[path], raw, mode)
    return record


def validate_result(result: dict, plan: dict) -> None:
    assert result['success'] is True
    assert type(result['forbidden_process_attempts']) is int and result['forbidden_process_attempts'] == 0
    assert len(result['cuts']) == len(plan['cases'])
    for actual, expected in zip(result['cuts'], plan['cases']):
        assert actual['name'] == expected['name'] and actual['trace'] == expected['trace']
        assert actual['remaining'] == expected['remaining']
        assert actual['global_retained'] == expected['global_retained']
        assert actual['returned'] == expected['returned']
        assert actual['prior_before'] == actual['prior_after']
        assert actual['image_before'] == actual['image_after']
        workspace_bytes(actual['before'], actual['case'], actual['workspace'], actual['image_before'])
        prior = actual['prior_before']
        raw = workspace_bytes(prior['workspace'], actual['case'], actual['prior_workspace'], actual['image_before'])
        assert set(prior['global']) == {''}
        file_bytes(prior['global'][''], raw, 0o400)
        assert actual['error'] == ('' if expected['returned'] else 'selected retirement cut\n')
        assert set(actual['before']) == set(NODES)
        assert actual['after'] == {key: actual['before'][key] for key in expected['remaining']}
        if expected['returned']:
            assert actual['result']['removed_nodes'] == len(NODES)
            assert actual['result']['runtime_authorized'] == 0 and actual['result']['executable'] is None
    controls = result['controls']
    assert len(controls) == len({row['name'] for row in controls})
    assert all(row['rejected'] == 1 and row['expected_diagnostic'] == 1 and row['returned'] == 0
               and row['before'] == row['after'] for row in controls)
    assert {'unsettled compiler', 'missing outer', 'missing inner stages', 'same-byte global replacement',
            'same-byte private replacement', 'replaced acquired workspace', 'unknown node spelling',
            'special FIFO', 'shared file links', 'file byte ceiling', 'node ceiling', 'depth ceiling',
            'aggregate byte ceiling', 'absent lock cannot be recreated', 'absent namespace cannot be recreated',
            'wrong lock identity', 'changed acquired image', 'unknown acquisition field', 'direct retirement bypass'} \
        <= {row['name'] for row in controls}
    last = result['last_owner']
    assert last['references_remaining'] == 0 and last['image_before'] == last['image_after']
    assert last['workspace_absent'] == 1
    image_bytes(last['image_before'])
    late = result['late_changes']
    assert {row['name'] for row in late} == {'changed_file', 'replaced_file', 'new_member', 'replaced_root',
                                           'partial_new_member', 'reappeared_root', 'replaced_global'}
    assert len(late) == 7
    for row in late:
        assert row['rejected'] == 1 and row['returned'] == 0 and row['expected_diagnostic'] == 1
        assert row['global_retained'] == 1 and row['prior_before'] == row['prior_after']
        assert row['image_before'] == row['image_after']
        if row['name'] == 'partial_new_member':
            assert set(row['after']) == {'', 'late-added'}
        elif row['name'] == 'replaced_global':
            assert row['after'] == {}
        else:
            assert row['after'] == row['injected']
    positives = result['positives']
    assert {row['name'] for row in positives} == {'node_ceiling', 'depth_ceiling', 'byte_ceiling', 'symlink_target'}
    assert len(positives) == 4
    for row in positives:
        assert row['after'] == {} and row['global_retained'] == 0
        assert row['prior_before'] == row['prior_after'] and row['image_before'] == row['image_after']
        assert row['result']['runtime_authorized'] == 0 and row['result']['executable'] is None
        assert row['result']['removed_nodes'] == len(row['before'])
        if row['name'] == 'node_ceiling':
            assert len(row['before']) == plan['ceilings']['nodes']
        elif row['name'] == 'depth_ceiling':
            assert max(path.count('/') + bool(path) for path in row['before']) == plan['ceilings']['depth']
        elif row['name'] == 'byte_ceiling':
            assert sum(node['bytes'] for node in row['before'].values() if node['kind'] == 'file') == plan['ceilings']['total_regular_file_bytes']
        else:
            assert row['before']['rust-tools/cargo']['target'].startswith('../../fsmgen-')
    mutants = result['mutants']
    assert set(mutants) == {'omitted cleanup review', 'discarded prior workspace identity'}
    for row in mutants.values():
        assert row['returned'] == 1 and row['global_retained'] == 0 and row['workspace_absent'] == 1
    assert mutants['omitted cleanup review']['compiler_group_gone'] == 0
    assert mutants['discarded prior workspace identity']['prior_inode'] != mutants['discarded prior workspace identity']['current_inode']
    allocated = result['allocated']
    assert allocated and len({row['path'] for row in allocated}) == len(allocated)
    for row in allocated:
        assert row['kind'] in ('store', 'workspace')
        assert type(row['device']) is int and row['device'] == ROOT.stat().st_dev
        assert type(row['inode']) is int and row['inode'] > 0
        assert re.fullmatch(r'\.artifacts/tmp/(?:native-proxy-image-custody/cases|process-supervisor-tests)/fsmgen-[A-Za-z0-9_]+', row['path'])
        path = ROOT / row['path']
        assert not path.exists() and not path.is_symlink()
    ledger = [json.loads(line) for line in (LOG / 'admission.jsonl').read_text().splitlines()]
    assert ledger == allocated


def main() -> None:
    plan = build_plan()
    if sys.argv[1:] == ['--plan']:
        (BASE / 'plan.json').write_text(json.dumps(plan, sort_keys=True, indent=2) + '\n')
        print(f"fixed retirement plan: {len(plan['cases'])} routes")
        return
    assert not sys.argv[1:]
    assert json.loads((BASE / 'plan.json').read_bytes()) == plan
    result = json.loads((LOG / 'qualification.json').read_bytes())
    validate_result(result, plan)
    spec = importlib.util.spec_from_file_location('retirement_acquisition_audit', BASE.parent / 'native-proxy-runtime-acquisition-20260910/audit.py')
    acquisition = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(acquisition)
    regression = json.loads((LOG / 'acquisition-regression.json').read_bytes())
    acquisition.validate(regression)
    assert regression['allocated'] == [json.loads(line) for line in (LOG / 'acquisition-regression-admission.jsonl').read_text().splitlines()]
    assert not ({row['path'] for row in result['allocated']} & {row['path'] for row in regression['allocated']})
    # Preserve the malformed first ledger exactly, including its final blank
    # line, without requiring a Git whitespace exception for that evidence.
    initial_base = BASE / 'result'
    initial_raw = base64.decodebytes((initial_base / 'initial-admission.json.stream.base64').read_bytes())
    recovery = json.loads((initial_base / 'initial-ledger-recovery.json').read_bytes())
    assert len(initial_raw) == recovery['source_bytes']
    assert hashlib.sha256(initial_raw).hexdigest() == recovery['source_sha256']
    initial_text = initial_raw.decode('ascii')
    decoder = json.JSONDecoder()
    offset, initial_rows = 0, []
    while offset < len(initial_text):
        while offset < len(initial_text) and initial_text[offset].isspace():
            offset += 1
        if offset == len(initial_text):
            break
        row, offset = decoder.raw_decode(initial_text, offset)
        initial_rows.append(row)
    initial_result = json.loads((initial_base / 'initial-qualification.json').read_bytes())
    assert initial_rows == initial_result['allocated'] and len(initial_rows) == recovery['complete_stream_objects']
    assert not ({row['path'] for row in initial_rows} & {row['path'] for row in result['allocated'] + regression['allocated']})
    for row in initial_rows:
        assert re.fullmatch(r'\.artifacts/tmp/(?:native-proxy-image-custody/cases|process-supervisor-tests)/fsmgen-[A-Za-z0-9_]+', row['path'])
        path = ROOT / row['path']
        assert not path.exists() and not path.is_symlink()
    falsifiers = []
    for name, mutate in [
        ('missing cut', lambda x: x['cuts'].pop()),
        ('early release', lambda x: x['cuts'][0].update(global_retained=0)),
        ('unremoved node', lambda x: x['cuts'][-1]['remaining'].append('rust-tools')),
        ('lost prior owner', lambda x: x['cuts'][0].update(prior_after={})),
        ('changed shared image', lambda x: x['cuts'][0].update(image_after={})),
        ('returned interruption', lambda x: x['cuts'][0].update(returned=1)),
        ('lost rejection', lambda x: x['controls'][0].update(rejected=0)),
        ('missing mutant', lambda x: x['mutants'].pop('discarded prior workspace identity')),
        ('lost allocation', lambda x: x['allocated'].pop()),
        ('process attempted', lambda x: x.update(forbidden_process_attempts=1)),
        ('lost late replacement', lambda x: x['late_changes'].pop()),
        ('unproved exact capacity', lambda x: x['positives'][0]['before'].pop('padding1')),
    ]:
        altered = copy.deepcopy(result)
        mutate(altered)
        try:
            validate_result(altered, plan)
        except AssertionError:
            falsifiers.append(name)
        else:
            raise AssertionError(f'counterfactual accepted: {name}')
    report = dict(schema='fsmgen.inactive_runtime_retirement_audit.v1', success=True,
                  assertions=tap_count((LOG / 'qualify.tap').read_text()),
                  cuts=len(plan['cases']) - 1, complete_cut_routes=1,
                  rejecting_controls=len(result['controls']), allocations=len(result['allocated']),
                  late_changes=len(result['late_changes']), positive_boundaries=len(result['positives']),
                  regression_assertions=tap_count((LOG / 'acquisition-regression.tap').read_text()),
                  initial_stream_recovered_allocations=len(initial_rows),
                  mutants=sorted(result['mutants']), falsifiers=falsifiers, limits=plan['limits'])
    (LOG / 'audit.json').write_text(json.dumps(report, sort_keys=True, indent=2) + '\n')
    print(json.dumps(report, sort_keys=True))


if __name__ == '__main__':
    main()
