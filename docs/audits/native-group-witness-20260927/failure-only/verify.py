#!/usr/bin/env python3
"""Verify saved failure-only qualification, including successful-path silence."""
import copy
import hashlib
import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import importlib.util
spec = importlib.util.spec_from_file_location('qualified_witness', HERE.parent / 'verify.py')
qualified = importlib.util.module_from_spec(spec)
spec.loader.exec_module(qualified)

LABELS = ('ordinary', 'success_stale', 'session_leader', 'context_error',
          'write_error', 'diagnostic_errno')


def validate(events, results, postcheck):
    assert [row['label'] for row in results] == list(LABELS)
    assert [row['label'] for row in events] == ['session_leader', 'context_error', 'diagnostic_errno']
    assert len({row['child']['pid'] for row in results}) == len(LABELS)
    for item in results:
        label, child, result = item['label'], item['child'], item['result']
        failure = label not in ('ordinary', 'success_stale')
        assert child['calls'] == 1
        assert child['queries'] == child['writes'] == int(failure)
        pid = child['pid']
        assert type(pid) is int and pid > 0 and child['ppid'] > 0
        assert child['pgid'] == pid
        assert result['timeout_seconds'] == 2 and result['capture_limit_bytes'] == 65_536
        assert result['timed_out'] == result['output_limited'] == 0
        assert result['stderr'] == ''
        cleanup = result['cleanup']
        assert cleanup['leader_started'] == cleanup['leader_reaped'] == cleanup['group_gone'] == 1
        assert cleanup['surviving_descendants'] == 0
        selected = [row for row in events if row['label'] == label]
        if failure:
            assert child['session_created'] == pid and child['result'] is None and child['errno'] == 1
            assert result['status'] == 'exec_error' and result['ok'] == 0 and result['exit_code'] == 126
            assert result['stdout'] == ''
            assert f'pid={pid} operation=setpgid result=undef errno=1 ' in result['exec_error']
        else:
            assert child['session_created'] is None
            assert child['result'] == '0 but true'
            assert child['errno'] == (1 if label == 'success_stale' else 0)
            assert result['status'] == 'success' and result['ok'] == 1 and result['exit_code'] == 0
            assert result['stdout'] == f'failure-witness-body={pid}\n'
            assert selected == []
        if label == 'write_error':
            assert child['capture_error'] == 'modeled capture write failure\n' and selected == []
        else:
            assert child['capture_error'] is None
        if not failure or label == 'write_error':
            continue
        assert len(selected) == 1
        event = selected[0]
        assert event['event'] == 'child_setpgid_failure'
        assert event['arguments'] == [0, 0] and event['pid'] == pid and event['sequence'] == 1
        assert event['result'] is None and event['errno'] == child['errno']
        assert result['started_monotonic_ns'] <= event['observed_monotonic_ns']
        assert event['observed_monotonic_ns'] <= event['context_completed_monotonic_ns']
        assert event['context_completed_monotonic_ns'] <= result['finished_monotonic_ns']
        if label == 'context_error':
            assert event['context'] is None and event['context_error'] == 'modeled context query failure\n'
        else:
            assert event['context_error'] is None
            target = {'pid': pid, 'pgid': pid, 'sid': pid, 'pgid_errno': 0, 'sid_errno': 0}
            assert event['context']['target'] == target
            assert event['context']['caller'] == {**target, 'ppid': child['ppid']}
    assert postcheck == [{'pid': row['child']['pid'], 'pid_absent': True, 'group_absent': True}
                         for row in results]


def main():
    qualified.validate_saved(HERE.parent)
    manifest = json.loads((HERE / 'manifest.json').read_bytes())
    assert manifest['schema'] == 'fsmgen.native_failure_context_qualification.v1'
    assert set(manifest['sha256']) == {'FailureWitness.pm', 'qualify.t', 'verify.py',
                                      'events.jsonl', 'results.json', 'postcheck.json', 'prove.txt'}
    for name, digest in manifest['sha256'].items():
        assert hashlib.sha256((HERE / name).read_bytes()).hexdigest() == digest
    assert manifest['helper_qualification_sha256'] == hashlib.sha256((HERE.parent / 'manifest.json').read_bytes()).hexdigest()
    data = (HERE / 'events.jsonl').read_bytes()
    events = qualified.decode(data)
    results = json.loads((HERE / 'results.json').read_bytes())
    postcheck = json.loads((HERE / 'postcheck.json').read_bytes())
    validate(events, results, postcheck)
    assert 'All tests successful.' in (HERE / 'prove.txt').read_text()
    mutations = []
    altered = copy.deepcopy(results)
    altered[1]['child']['queries'] = 1
    mutations.append((events, altered, postcheck))
    altered = copy.deepcopy(events)
    altered[0]['errno'] = 5
    mutations.append((altered, results, postcheck))
    altered = copy.deepcopy(events)
    altered[0]['context']['caller']['sid'] += 1
    mutations.append((altered, results, postcheck))
    altered = copy.deepcopy(results)
    altered[4]['child']['capture_error'] = None
    mutations.append((events, altered, postcheck))
    altered = copy.deepcopy(postcheck)
    altered[0]['group_absent'] = False
    mutations.append((events, results, altered))
    mutations.append((events[1:], results, postcheck))
    for args in mutations:
        try:
            validate(*args)
        except AssertionError:
            continue
        raise AssertionError('corrupt failure-only qualification accepted')
    print('Failure-only context, silent success, retained native errors, explicit capture gaps and cleanup verified.')


if __name__ == '__main__':
    main()
