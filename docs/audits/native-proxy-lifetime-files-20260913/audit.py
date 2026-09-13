"""Independently verify retained actual-file effects without replaying execution."""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
ADMISSION = ROOT / 'docs/audits/native-proxy-lifetime-files-admission-20260913'
sys.path.insert(0, str(ADMISSION))
from support import OLD_COMMON, canonical, digest, document, pin, write, authenticate
import consume


def closed_pairs(pairs):
    value = {}
    for key, item in pairs:
        assert key not in value, 'duplicate journal key'
        value[key] = item
    return value


def retained(row):
    raw = (ROOT / row['retained']['path']).read_bytes()
    assert pin(row['retained']['path']) == row['retained']
    assert {key: row['source'][key] for key in ('size_bytes', 'sha256')} == {
        key: row['retained'][key] for key in ('size_bytes', 'sha256')}
    return raw


def initial_stages(records, selection, payloads):
    """Construct exact cumulative setup membership independently of the runner."""
    for case in selection['cases']:
        context = next(row['value'] for row in records if row['kind'] == 'case-initial' and row['value']['name'] == case['name'])
        stages = [row['value'] for row in records if row['kind'] == 'stage' and row['value']['case'] == case['name']][:6]
        nodes = context['initial']['nodes']; paths = case['roots']
        expected = set(paths.values())
        additions = [{path + '/' + suffix for path in (paths['target'], paths['other'])
                      for suffix in ('rust-tools', 'rust-tool-resolution')}]
        for name in ('target', 'other'):
            runtime = context['runtimes'][name]
            image_root = paths['store'] + '/images/' + runtime['image']['key']
            additions.append({paths['store'] + '/' + suffix for suffix in ('images', 'references', 'coordination.lock')}
                | {image_root} | {row['identity']['path'] for row in runtime['image']['snapshots']}
                | {runtime['reference'][key]['identity']['path'] for key in ('private', 'global')})
        for name in ('a', 'b'):
            additions.append({context['observations'][name]['observation_reference']['source']['identity']['path']})
        for index, stage in enumerate(stages):
            if index: expected.update(additions[index - 1])
            assert set(stage['after']['result']['nodes']) == expected
            assert consume.stable(stage['after']['result']['nodes']) == consume.stable({path: nodes[path] for path in expected})
            if index == 0:
                assert stage['operation']['result'] == context['directories']
                inputs = dict(roots=paths)
            elif index == 1:
                assert stage['operation']['result'] == dict(private_wrappers_only=1)
                inputs = dict(roots=paths, wrapper_hex=payloads['wrapper'].hex())
            elif index in (2, 3):
                name = 'target' if index == 2 else 'other'; image = payloads['image']
                if name == 'other' and case['profile'] == 'different_image':
                    image += bytes.fromhex(selection['payload_source']['different_image_suffix_hex'])
                inputs = dict(store=paths['store'], workspace=context['directories'][name],
                              c_hex=payloads['c'].hex(), image_hex=image.hex())
            else:
                name = 'a' if index == 4 else 'b'
                inputs = dict(store=paths['store'], request=context['requests'][name])
            assert stage['input_before'] == stage['input_after'] == inputs
        assert expected == set(nodes)


def rejects(action):
    try: action()
    except (AssertionError, KeyError, IndexError, ValueError, TypeError): return True
    return False


def countermodels(records, selection, payloads):
    controls = []
    for name in ('omitted_record', 'open_descriptor', 'global_before_private', 'archive_identity',
                 'unsettled_work', 'native_authority', 'hold_reappears'):
        changed = list(records)
        if name == 'omitted_record':
            changed.pop(2)
        else:
            if name == 'native_authority': index = len(changed) - 1
            elif name == 'unsettled_work': index = next(i for i, row in enumerate(changed) if row['kind'] == 'case-initial')
            else:
                stage = {'open_descriptor': 'acquire_runtime_target', 'global_before_private': 'retire_target',
                         'archive_identity': 'archive_a', 'hold_reappears': 'release_a'}[name]
                index = next(i for i, row in enumerate(changed) if row['kind'] == 'stage' and row['value']['name'] == stage)
            changed[index] = copy.deepcopy(changed[index]); value = changed[index]['value']
            if name == 'native_authority': value['runtime_qualification'] = 1
            if name == 'unsettled_work': value['settlements']['a']['receipts'][0]['cleanup']['group_gone'] = 0
            if name == 'open_descriptor': value['operation']['handles'][0]['closed_at_return'] = 0
            if name == 'archive_identity': value['operation']['result']['source_bindings'][0]['archive']['inode'] += 1
            if name == 'global_before_private':
                calls = value['operation']['calls']
                global_path = value['input_before']['acquired']['reference']['global']['identity']['path']
                workspace = value['input_before']['acquired']['reference']['record']['workspace']
                first = next(i for i, row in enumerate(calls) if row['operation'] == 'unlink' and row['paths'] == [global_path])
                second = next(i for i, row in enumerate(calls) if row['operation'] == 'rmdir' and row['path'] == workspace)
                calls[first], calls[second] = calls[second], calls[first]
            if name == 'hold_reappears':
                context = next(row['value'] for row in changed if row['kind'] == 'case-initial')
                path = context['observations']['a']['observation_reference']['source']['identity']['path']
                value['after']['result']['nodes'][path] = copy.deepcopy(context['initial']['nodes'][path])
                value['after']['result']['file_bytes'] += context['initial']['nodes'][path]['identity']['size_bytes']
        assert rejects(lambda: consume.verify(changed, selection, payloads)), name
        controls.append(name)
    return controls


def absent(relative):
    path = ROOT; device = ROOT.stat().st_dev
    for component in relative.split('/'):
        assert component not in ('', '.', '..')
        path /= component
        try: metadata = os.lstat(path)
        except FileNotFoundError: return True
        assert stat.S_ISDIR(metadata.st_mode) and metadata.st_dev == device and metadata.st_uid == os.getuid()
    return False


def verify():
    plan = document(BASE / 'capture-plan.json'); captured = document(BASE / 'capture.json')
    for row in plan['sources'] + document(BASE / 'audit-pins.json'): assert pin(row['path']) == row
    original_plan = document(ADMISSION / 'plan.json'); original_pins = document(ADMISSION / 'preflight-pins.json')
    authenticate(original_plan, original_pins)
    for row in original_pins:
        raw = subprocess.check_output(['git', 'show', plan['admission_commit'] + ':' + row['path']], cwd=ROOT)
        assert len(raw) == row['size_bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256']
    assert captured['owner'] == plan['owner'] and captured['admission_commit'] == plan['admission_commit']
    assert captured['first_exit'] == 0 and captured['independently_qualified'] is False
    selection = document(ADMISSION / 'selection.json')
    records, total = [], 0
    for index, row in enumerate(captured['records']):
        assert row['retained']['path'] == str((BASE / 'records' / ('event-%06d.json' % index)).relative_to(ROOT))
        raw = retained(row); total += len(raw)
        assert len(raw) <= selection['bounds']['record_bytes'] and total <= selection['bounds']['total_record_bytes']
        value = json.loads(raw, object_pairs_hook=closed_pairs)
        assert canonical(value) + b'\n' == raw
        records.append(value)
    assert len(records) == captured['record_count'] <= plan['maximum_journal_records']
    assert total == captured['record_bytes']
    assert sorted(path.name for path in (BASE / 'records').iterdir()) == ['event-%06d.json' % i for i in range(len(records))]
    outputs = {row['retained']['path'].rsplit('/', 1)[1]: retained(row) for row in captured['first_outputs']}
    assert outputs['first-run.exit'] == outputs['execution-permit.exit'] == b'0\n'
    permit = json.loads(retained(captured['execution_admission']))
    task = retained(captured['task_at_execution'])
    assert hashlib.sha256(task).hexdigest() == permit['task_sha256']
    section = task.decode().split('- ID: `' + plan['owner'] + '`\n')[1].split('- ID: `', 1)[0]
    assert 'Status: `active`' in section
    assert permit['admission_commit'] == plan['admission_commit'] and permit['execution_owner'] == plan['owner']
    assert permit['plan_sha256'] == pin(ADMISSION / 'plan.json')['sha256']
    assert permit['preflight_sha256'] == pin(ADMISSION / 'preflight-pins.json')['sha256']
    assert records[0]['value']['admission'] == permit
    model = document(ROOT / selection['payload_source']['path'])
    source = model['seeds']['same_image']['observers']['a']['acquired']['target_sources']
    payloads = {name: bytes.fromhex(source[index]['bytes_hex']) for name, index in selection['payload_source']['target_sources'].items()}
    before = digest(records)
    result = consume.verify(records, selection, payloads)
    initial_stages(records, selection, payloads)
    assert digest(records) == before
    falsifiers = countermodels(records, selection, payloads)
    assert digest(records) == before
    assert json.loads(outputs['first-run.stdout']) == dict(cases=len(selection['cases']), forbidden_process_attempts=0,
        journal_bytes=total, journal_records=len(records), runtime_qualification=0, success=1)
    traces = []
    for record in records:
        if record['kind'] == 'stage': traces.extend(record['value'][name] for name in ('before', 'operation', 'after'))
        if record['kind'] == 'cleanup-admission': traces.append(record['value']['observed'])
    handles = [handle for trace in traces for handle in trace['handles']]
    calls = [call for trace in traces for call in trace['calls']]
    roots = sorted(path for case in selection['cases'] for path in case['roots'].values())
    assert len(roots) == len(set(roots)) == selection['bounds']['fixture_roots']
    assert all(absent(path) for path in roots)
    result.update(schema='fsmgen.inactive_lifetime_actual_files_review.v1', owner=plan['owner'],
        admission_commit=plan['admission_commit'], capture=pin(BASE / 'capture.json'), record_bytes=total,
        native_file_observation_traces=len(traces), primary_handles=len(handles),
        file_handles=sum(row['kind'] == 'file' for row in handles), directory_handles=sum(row['kind'] == 'directory' for row in handles),
        metadata_observers=sum(len(trace['metadata_observers']) for trace in traces), actual_calls=len(calls),
        separate_recoveries=sum(len(trace['recovery']) for trace in traces),
        roots_absent=roots, falsifiers=falsifiers, journal_unchanged_by_auditor=True,
        original_harness_replayed=False, runtime_qualification=False)
    return result


def main():
    parser = argparse.ArgumentParser(); group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain', action='store_true'); group.add_argument('--verify-saved', action='store_true')
    args = parser.parse_args(); result = verify()
    if args.retain: write(BASE / 'review.json', result)
    else: assert document(BASE / 'review.json') == result
    print('actual inert lifetimes: OK; cases=%d stages=%d handles=%d roots_absent=%d native_payload_execution=0' %
          (len(result['cases']), result['stages'], result['primary_handles'], len(result['roots_absent'])))


if __name__ == '__main__':
    main()
