#!/usr/bin/env python3
"""Verify the saved original observation; never execute the original again."""
import copy
import hashlib
import json
from pathlib import Path
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from verify import decode, unique_object, validate_saved

STAGES = tuple(f'{index:02d}_{"compile" if index % 2 else "runtime"}'
               for index in range(1, 9))


def read_json(path):
    return json.loads(path.read_bytes(), object_pairs_hook=unique_object)


def validate(rows, results, postcheck):
    assert len(rows) == 2 + 4 * len(STAGES)
    assert rows[0]['event'] == 'begin' and rows[-1]['event'] == 'end'
    start, end = rows[0], rows[-1]
    assert end['stages'] == len(STAGES) and end['capture_error'] is None
    assert end['retention_errors'] == [] and start['context'] == end['context']
    parent_identity = start['context']['caller']
    calls = [row for row in rows if row['event'] == 'setpgid']
    assert len({(row['pid'], row['sequence']) for row in calls}) == len(calls)
    children = set()
    for index, label in enumerate(STAGES):
        begin, first, second, finish = rows[1 + 4 * index:5 + 4 * index]
        assert begin == {'event': 'stage_begin', 'label': label, 'stage': label[3:]}
        assert finish['event'] == 'stage_result' and finish['label'] == label
        assert finish['path'] == f'.artifacts/native-group-witness/original/{label}.json'
        assert {first['event'], second['event']} == {'setpgid'}
        child = next(row for row in (first, second) if row['arguments'] == [0, 0])
        parent = second if child is first else first
        pid = child['pid']
        assert pid not in children
        children.add(pid)
        assert parent['arguments'] == [pid, pid] and parent['pid'] == parent_identity['pid']
        assert child['before']['caller']['ppid'] == parent['pid']
        result = results[label]['result']
        assert result['schema'] == 'fsmgen.test.verilator_runtime_result.v1'
        assert result['stage'] == label[3:]
        assert result['timeout_seconds'] == (120 if index % 2 == 0 else 30)
        assert result['capture_limit_bytes'] == (8_388_608 if index % 2 == 0 else 67_108_864)
        assert result['ok'] == 1 and result['status'] == 'success'
        assert result['exit_code'] == result['signal'] == result['exec_failed'] == 0
        assert result['exec_error'] is None
        assert result['timed_out'] == result['output_limited'] == 0
        cleanup = result['cleanup']
        assert cleanup['containment'] == 'test_runtime_process_group'
        assert cleanup['leader_started'] == cleanup['leader_reaped'] == cleanup['group_gone'] == 1
        assert cleanup['surviving_descendants'] == 0
        for call in (first, second):
            assert call['label'] == label and call['result'] == '0 but true'
            assert type(call['errno']) is int and call['errno'] >= 0
            assert result['started_monotonic_ns'] <= call['start_ns'] <= call['end_ns']
            assert call['end_ns'] <= result['finished_monotonic_ns']
            for phase in ('before', 'after'):
                native = call[phase]
                assert native['caller']['pid'] == call['pid']
                assert native['target']['pid'] == pid
                for identity in native.values():
                    assert identity['pgid'] > 0
                    assert identity['sid'] == parent_identity['sid'] != pid
                    assert identity['pgid_errno'] == identity['sid_errno'] == 0
                if call is parent:
                    assert native['caller'] == parent_identity
                else:
                    assert native['caller'] == {**native['target'], 'ppid': parent['pid']}
            assert call['after']['target']['pgid'] == pid
        if index % 2:
            entry = 0 if index < 4 else 1
            expected = (f'GUARD_VALUES disabled=0 enabled=6 symbolic=0 '
                        f'captured={42 if entry else 0} observed={9 if entry else 0}')
            assert expected in result['stdout'].splitlines()
            assert result['stdout'].splitlines().count('CONSTANT_GUARDS_PASS') == 1
    assert len(postcheck['children']) == len(children)
    assert {row['pid'] for row in postcheck['children']} == children
    assert all(row['pid_absent'] is True and row['group_absent'] is True
               for row in postcheck['children'])
    binaries = [results[label]['arguments'][0][0] for label in STAGES if label.endswith('runtime')]
    assert postcheck['temporary_binaries'] == [{'path': p, 'absent': True} for p in binaries]


def main():
    validate_saved(HERE.parent)
    manifest = read_json(HERE / 'manifest.json')
    expected = {'observe.t', 'admission.json', 'events.jsonl', 'postcheck.json',
                'prove.txt', 'verify_original.py'} | {label + '.json' for label in STAGES}
    assert manifest['schema'] == 'fsmgen.native_group_original_observation.v1'
    assert set(manifest['sha256']) == expected
    for name, digest in manifest['sha256'].items():
        assert hashlib.sha256((HERE / name).read_bytes()).hexdigest() == digest
    rows = decode((HERE / 'events.jsonl').read_bytes())
    assert rows[0]['qualification_sha256'] == hashlib.sha256((HERE.parent / 'manifest.json').read_bytes()).hexdigest()
    assert rows[0]['admission_sha256'] == manifest['sha256']['admission.json']
    admission = read_json(HERE / 'admission.json')
    repository = HERE.parents[3]
    observer = str((HERE / 'observe.t').relative_to(repository))
    assert admission['sha256'][observer] == manifest['sha256']['observe.t']
    for path, digest in admission['sha256'].items():
        if path == observer:
            continue
        source = subprocess.check_output(
            ['git', 'show', admission['qualification_revision'] + ':' + path],
            cwd=repository)
        assert hashlib.sha256(source).hexdigest() == digest
    results = {label: read_json(HERE / (label + '.json')) for label in STAGES}
    for row in rows:
        if row['event'] == 'stage_result':
            assert row['sha256'] == manifest['sha256'][row['label'] + '.json']
    postcheck = read_json(HERE / 'postcheck.json')
    validate(rows, results, postcheck)
    log = (HERE / 'prove.txt').read_text()
    assert 'All tests successful.' in log and 'Result: PASS' in log
    assert 'not ok' not in log and 'SKIP' not in log
    corruptions = []
    missing = copy.deepcopy(rows)
    del missing[2]
    corruptions.append((missing, results, postcheck))
    for field, value in [('result', None), ('pid', -1)]:
        changed = copy.deepcopy(rows)
        changed[2][field] = value
        corruptions.append((changed, results, postcheck))
    changed = copy.deepcopy(rows)
    changed[2]['after']['target']['sid'] += 1
    corruptions.append((changed, results, postcheck))
    for field, value in [('stdout', ''), ('timeout_seconds', 31)]:
        changed = copy.deepcopy(results)
        changed['02_runtime']['result'][field] = value
        corruptions.append((rows, changed, postcheck))
    changed = copy.deepcopy(postcheck)
    changed['children'][0]['group_absent'] = False
    corruptions.append((rows, results, changed))
    for args in corruptions:
        try:
            validate(*args)
        except AssertionError:
            continue
        raise AssertionError('corrupt original observation accepted')
    print('Saved original pass, native identities, limits, cleanup and corruption controls verified; historical cause remains open.')


if __name__ == '__main__':
    main()
