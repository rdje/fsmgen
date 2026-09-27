#!/usr/bin/env python3
"""Validate bounded witness qualification, independent outcomes, and hostile records."""
import copy
import errno
import hashlib
import json
from pathlib import Path
import sys

LABELS = ('ordinary', 'parent_first', 'child_first', 'session_leader', 'success_stale')
SAVED_FILES = {'GroupWitness.pm', 'build.py', 'context.c', 'postcheck.json',
               'qualification.jsonl', 'qualify.t', 'verify.py'}


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        assert key not in result
        result[key] = value
    return result


def decode(data):
    assert len(data) <= 1_048_576
    assert data.endswith(b'\n')
    lines = data.splitlines(keepends=True)
    assert all(len(line) <= 4096 for line in lines)
    return [json.loads(line, object_pairs_hook=unique_object) for line in lines]


def validate(rows):
    calls = [row for row in rows if row['event'] == 'setpgid']
    results = [row for row in rows if row['event'] == 'result']
    assert len(rows) == len(calls) + len(results)
    assert [row['label'] for row in results] == list(LABELS)
    assert len(calls) == 2 * len(LABELS) - 1
    assert set(row['label'] for row in calls) == set(LABELS)
    assert len({(row['pid'], row['sequence']) for row in calls}) == len(calls)
    for item in results:
        label, result = item['label'], item['result']
        selected = [row for row in calls if row['label'] == label]
        child_calls = [row for row in selected if row['arguments'] == [0, 0]]
        assert len(child_calls) == 1
        child = child_calls[0]
        pid = child['pid']
        assert pid > 0
        parent_calls = [row for row in selected if row is not child]
        assert len(parent_calls) == (0 if label == 'session_leader' else 1)
        for call in selected:
            assert set(call) == {'event', 'label', 'pid', 'sequence', 'arguments',
                                 'result', 'errno', 'incoming_errno', 'start_ns',
                                 'end_ns', 'before', 'after'}
            for field in ('pid', 'sequence', 'errno', 'incoming_errno', 'start_ns', 'end_ns'):
                assert type(call[field]) is int and call[field] >= 0
            assert call['sequence'] > 0
            assert result['started_monotonic_ns'] <= call['start_ns'] <= call['end_ns']
            assert call['end_ns'] <= result['finished_monotonic_ns']
            for phase in ('before', 'after'):
                context = call[phase]
                assert set(context) == {'caller', 'target'}
                assert set(context['caller']) == {'pid', 'ppid', 'pgid', 'sid', 'pgid_errno', 'sid_errno'}
                assert set(context['target']) == {'pid', 'pgid', 'sid', 'pgid_errno', 'sid_errno'}
                assert all(type(value) is int for item in context.values() for value in item.values())
                assert context['caller']['pid'] == call['pid']
                assert context['target']['pid'] == pid
                for identity in context.values():
                    assert identity['pgid'] > 0 and identity['sid'] > 0
                    assert identity['pgid_errno'] == identity['sid_errno'] == 0
            assert call['before']['caller']['sid'] == call['after']['caller']['sid']
            assert call['after']['target']['pgid'] == pid
        assert child['before']['caller'] == {
            **child['before']['target'], 'ppid': child['before']['caller']['ppid']
        }
        assert child['after']['caller'] == {
            **child['after']['target'], 'ppid': child['after']['caller']['ppid']
        }
        cleanup = result['cleanup']
        assert cleanup['leader_started'] == cleanup['leader_reaped'] == cleanup['group_gone'] == 1
        assert cleanup['surviving_descendants'] == 0
        assert result['timed_out'] == result['output_limited'] == 0
        assert result['stderr'] == ''
        if label == 'session_leader':
            assert child['before']['caller']['sid'] == child['before']['caller']['pgid'] == pid
            assert child['result'] is None and child['errno'] == errno.EPERM
            assert result['ok'] == 0 and result['status'] == 'exec_error'
            assert result['exit_code'] == 126 and result['stdout'] == ''
            assert f'pid={pid} operation=setpgid result=undef errno=1 ' in result['exec_error']
        else:
            parent = parent_calls[0]
            assert parent['arguments'] == [pid, pid]
            assert parent['pid'] == child['before']['caller']['ppid']
            assert child['before']['caller']['sid'] == parent['before']['caller']['sid'] != pid
            assert child['after']['caller']['sid'] == parent['after']['target']['sid']
            assert result['ok'] == 1 and result['status'] == 'success' and result['exit_code'] == 0
            assert result['stdout'] == f'native-witness-command={pid}\n'
            for call in selected:
                assert call['result'] == '0 but true' and call['errno'] >= 0
                if label == 'success_stale':
                    assert call['incoming_errno'] == call['errno'] == errno.EPERM
            if label == 'parent_first':
                assert parent['end_ns'] <= child['start_ns']
                assert child['before']['caller']['pgid'] == pid
            if label == 'child_first':
                assert child['end_ns'] <= parent['start_ns']
                assert parent['before']['target']['pgid'] == pid


def validate_saved(directory):
    manifest = json.loads((directory / 'manifest.json').read_bytes(),
                          object_pairs_hook=unique_object)
    assert manifest['schema'] == 'fsmgen.native_group_witness_qualification.v1'
    assert set(manifest['sha256']) == SAVED_FILES
    for name, digest in manifest['sha256'].items():
        assert hashlib.sha256((directory / name).read_bytes()).hexdigest() == digest
    assert manifest['build']['source_sha256'] == manifest['sha256']['context.c']
    rows = decode((directory / 'qualification.jsonl').read_bytes())
    children = {row['pid'] for row in rows
                if row['event'] == 'setpgid' and row['arguments'] == [0, 0]}
    postcheck = json.loads((directory / 'postcheck.json').read_bytes(),
                          object_pairs_hook=unique_object)
    assert len(postcheck) == len(children)
    assert {row['pid'] for row in postcheck} == children
    for row in postcheck:
        assert set(row) == {'pid', 'pid_absent', 'group_absent'}
        assert type(row['pid']) is int
        assert row['pid_absent'] is True and row['group_absent'] is True
    return directory / 'qualification.jsonl'


def main():
    assert len(sys.argv) <= 2, 'usage: verify.py [capture.jsonl]'
    path = Path(sys.argv[1]) if len(sys.argv) == 2 else validate_saved(Path(__file__).parent)
    data = path.read_bytes()
    rows = decode(data)
    validate(rows)
    mutations = []
    missing = copy.deepcopy(rows)
    del missing[0]
    mutations.append(missing)
    for field, replacement in [('errno', 0), ('result', '0 but true')]:
        changed = copy.deepcopy(rows)
        failure = next(row for row in changed if row['event'] == 'setpgid' and row['label'] == 'session_leader')
        failure[field] = replacement
        mutations.append(changed)
    foreign = copy.deepcopy(rows)
    next(row for row in foreign if row['event'] == 'setpgid')['before']['target']['pid'] += 1
    mutations.append(foreign)
    wrong_session = copy.deepcopy(rows)
    next(row for row in wrong_session if row['event'] == 'setpgid')['after']['caller']['sid'] += 1
    mutations.append(wrong_session)
    cleanup = copy.deepcopy(rows)
    next(row for row in cleanup if row['event'] == 'result')['result']['cleanup']['leader_reaped'] = 0
    mutations.append(cleanup)
    for changed in mutations:
        try:
            validate(changed)
        except AssertionError:
            continue
        raise AssertionError('corrupt witness evidence was accepted')
    for invalid in (data[:-1], b' ' * 1_048_577, b' ' * 4096 + b'\n', b'{"x":1,"x":2}\n'):
        try:
            decode(invalid)
        except (AssertionError, json.JSONDecodeError):
            continue
        raise AssertionError('capture boundary corruption was accepted')
    print('Witness identities, native outcomes, ordering, cleanup and corruption controls verified.')


if __name__ == '__main__':
    main()
