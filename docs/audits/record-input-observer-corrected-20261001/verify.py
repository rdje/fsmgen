#!/usr/bin/env python3
"""Verify saved fixed-observer evidence without rerunning any process fixture."""
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
NATIVE = ROOT / 'docs/audits/native-group-witness-20260927'
SCENARIOS = ('healthy', 'query_gap', 'capture_gap', 'retention_gap', 'diagnostic_errno')
INVALID = {'empty_inputs': 'incomplete or additional input identity',
           'changed_digest': 'observation input changed', 'wrong_target': 'target outside fixed observation scope',
           'extra_field': 'invalid closed admission object', 'wrong_count': 'invalid fixed control coverage',
           'wrong_scenario': 'invalid fixed scenario', 'reuse': 'exclusive observer work directory',
           'qualification_missing': 'record-input observer qualification required'}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def read_json(path):
    def distinct(pairs):
        result = {}
        for key, value in pairs:
            assert key not in result
            result[key] = value
        return result
    return json.loads(path.read_bytes(), object_pairs_hook=distinct)


def clean(result, timeout, cap):
    assert result['timeout_seconds'] == timeout and result['capture_limit_bytes'] == cap
    assert result['timed_out'] == result['output_limited'] == result['signal'] == 0
    c = result['cleanup']
    assert c['leader_started'] == c['leader_reaped'] == c['group_gone'] == 1
    assert c['surviving_descendants'] == c['term_sent'] == c['kill_sent'] == 0


def validate(rows, cases, postcheck):
    assert [r['case'] for r in rows] == list(SCENARIOS) + list(INVALID)
    expected_postcheck = []
    for row in rows:
        case, outer = row['case'], row['result']
        clean(outer, 60, 1_048_576)
        success = case in ('healthy', 'diagnostic_errno')
        assert bool(outer['ok']) == success and (outer['exit_code'] == 0) == success
        if case in INVALID:
            assert INVALID[case] in outer['stderr'] and outer['stdout'] == ''
            continue
        assert '1..39\n' in outer['stdout'] and not re.search('^not ok', outer['stdout'], re.M)
        assert len(re.findall('^ok [0-9]+ - ', outer['stdout'], re.M)) == 39
        expected_stderr = '' if success else (
            ('modeled capture failure\n' if case == 'capture_gap' else '')
            + 'observer diagnostic gaps retained in summary.json\n'
            + f'# Looks like your test exited with {outer["exit_code"]} just after 39.\n')
        assert outer['stderr'] == expected_stderr
        data = cases[case]
        summary, controls, events = data['summary'], data['controls'], data['events']
        assert summary['schema'] == 'fsmgen.priority_stage_observation.v1' and summary['stages'] == 3
        assert summary['input_error'] is None and summary['test_error'] is None
        assert summary['admission_sha256'] == data['admission_digest']
        expected_labels = ['runtime_b', 'runtime_c'] if case == 'retention_gap' else ['compile_a', 'runtime_b', 'runtime_c']
        assert [r['label'] for r in summary['receipts']] == expected_labels
        assert [c['kind'] for c in controls] == ['ordinary', 'stale', 'session']
        assert len(events) == (0 if case == 'capture_gap' else 1)
        for i, control in enumerate(controls):
            child, result = control['child'], control['result']
            kind = control['kind']
            fail = kind == 'session'
            pid = child['pid']
            assert child['kind'] == kind and child['pgid'] == pid and pid > 0
            assert child['calls'] == 1 and child['queries'] == child['writes'] == int(fail)
            clean(result, 120 if i == 0 else 30, 8_388_608 if i == 0 else 67_108_864)
            assert result['stage'] == ('compile' if i == 0 else 'runtime')
            assert result['stderr'] == ''
            if fail:
                assert child['result'] is None and child['errno'] == 1
                assert result['status'] == 'exec_error' and result['exit_code'] == 126 and not result['ok']
                assert f'pid={pid} operation=setpgid result=undef errno=1 ' in result['exec_error']
                assert result['stdout'] == ''
            else:
                assert child['result'] == '0 but true'
                assert child['errno'] == (1 if kind == 'stale' else 0)
                assert result['status'] == 'success' and result['exit_code'] == 0 and result['ok']
                assert result['stdout'] == f'control-body={pid}\n'
            label = ('compile_a', 'runtime_b', 'runtime_c')[i]
            if label in expected_labels:
                retained = data['stages'][label]
                assert retained['result'] == result
                work = f'.artifacts/record-input-native-observer-corrected/{row["capture"]}'
                assert retained['arguments'] == [[f'{work}/verilator', '--binary', '--Mdir', f'{work}/obj']
                    if i == 0 else [f'{work}/fixture_binary']]
            expected_postcheck.append({'case': case, 'pid': pid, 'pid_absent': True, 'group_absent': True})
        pid = controls[2]['child']['pid']
        gaps, errors = summary['capture_gaps'], summary['retention_errors']
        if case == 'query_gap':
            assert gaps == [{'kind': 'native_context_query', 'label': 'runtime_c', 'pid': pid, 'error': 'modeled query failure\n'}]
        elif case == 'capture_gap':
            assert gaps == [{'kind': 'missing_or_duplicate_native_event', 'label': 'runtime_c', 'pid': pid}]
        else:
            assert gaps == []
        if case == 'retention_gap':
            assert len(errors) == 1 and errors[0]['label'] == 'compile_a'
            assert 'exclusive observer result: File exists' in errors[0]['error']
            assert data['collision'] == b'exclusive collision control\n'
        else:
            assert errors == []
        if events:
            event = events[0]
            assert event['event'] == 'child_setpgid_failure' and event['label'] == 'runtime_c'
            assert event['pid'] == pid and event['arguments'] == [0, 0] and event['sequence'] == 1
            assert event['result'] is None and event['errno'] == 1
            result = controls[2]['result']
            assert result['started_monotonic_ns'] <= event['observed_monotonic_ns']
            assert event['observed_monotonic_ns'] <= event['context_completed_monotonic_ns'] <= result['finished_monotonic_ns']
            if case == 'query_gap':
                assert event['context'] is None and event['context_error'] == 'modeled query failure\n'
            else:
                assert event['context_error'] is None
                target = {'pid': pid, 'pgid': pid, 'sid': pid, 'pgid_errno': 0, 'sid_errno': 0}
                assert event['context']['target'] == target
                assert event['context']['caller'] == {**target, 'ppid': controls[2]['child']['ppid']}
    assert postcheck == expected_postcheck
    assert len({r['pid'] for r in postcheck}) == len(postcheck)


def main():
    # Consume the existing independent helper/failure-only qualification first.
    spec = importlib.util.spec_from_file_location('failure_check', NATIVE / 'failure-only/verify.py')
    check = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(check)
    check.main()
    manifest = read_json(HERE / 'manifest.json')
    assert manifest['schema'] == 'fsmgen.fixed_record_input_observer_qualification.v1'
    assert digest((NATIVE / 'manifest.json').read_bytes()) == manifest['helper_qualification_sha256']
    assert digest((NATIVE / 'failure-only/manifest.json').read_bytes()) == manifest['failure_qualification_sha256']
    actual = {str(p.relative_to(HERE)) for p in HERE.rglob('*') if p.is_file() and p.name != 'manifest.json'}
    assert actual == set(manifest['sha256'])
    for path, expected in manifest['sha256'].items():
        assert digest((HERE / path).read_bytes()) == expected
    evidence = HERE / 'evidence'
    rows = read_json(evidence / 'results.json')
    cases = {}
    for row in rows:
        if row['case'] not in SCENARIOS:
            assert row['case'] == 'reuse' or not (evidence / row['capture']).exists()
            continue
        path = evidence / row['capture']
        admission_path = evidence / f'{row["capture"]}-admission.json'
        admission = read_json(admission_path)
        assert admission['capture'] == row['capture'] and admission['scenario'] == row['case']
        assert admission['expected_stages'] == {'compile': 1, 'runtime': 2}
        assert admission['target'] == 'docs/audits/native-group-witness-20260927/priority-observer/control.t'
        for name, expected in admission['sha256'].items():
            source = ROOT / name
            data = source.read_bytes() if source.parent == HERE else subprocess.check_output(
                ['git', 'show', f'{manifest["baseline_revision"]}:{name}'], cwd=ROOT)
            assert digest(data) == expected
        summary = read_json(path / 'summary.json')
        stages = {}
        for receipt in summary['receipts']:
            assert receipt['path'] == receipt['label'] + '.json'
            assert receipt['stage'] == receipt['label'].split('_')[0]
            assert digest((path / receipt['path']).read_bytes()) == receipt['sha256']
            stages[receipt['label']] = read_json(path / receipt['path'])
        raw_events = (path / 'events.jsonl').read_bytes()
        assert len(raw_events) <= 1_048_576 and (not raw_events or raw_events.endswith(b'\n'))
        events = [json.loads(line) for line in raw_events.splitlines()]
        cases[row['case']] = {'summary': summary, 'stages': stages, 'events': events,
            'controls': read_json(path / 'control-results.json'), 'admission_digest': digest(admission_path.read_bytes()),
            'collision': (path / 'compile_a.json').read_bytes() if row['case'] == 'retention_gap' else None}
    postcheck = read_json(evidence / 'postcheck.json')
    validate(rows, cases, postcheck)
    assert 'All tests successful.' in (evidence / 'prove.txt').read_text()
    mutations = []
    for label, mutate in (
        ('silent success', lambda c: c['healthy']['controls'][0]['child'].update(queries=1)),
        ('native errno', lambda c: c['healthy']['events'][0].update(errno=5)),
        ('native session', lambda c: c['healthy']['events'][0]['context']['caller'].update(sid=0)),
        ('capture gap', lambda c: c['capture_gap']['summary'].update(capture_gaps=[])),
        ('preserved result', lambda c: c['healthy']['stages']['compile_a']['result'].update(timeout_seconds=121)),
        ('retention gap', lambda c: c['retention_gap']['summary'].update(retention_errors=[])),
    ):
        altered = copy.deepcopy(cases)
        mutate(altered)
        mutations.append((label, rows, altered, postcheck))
    altered = copy.deepcopy(postcheck)
    altered[0]['group_absent'] = False
    mutations.append(('cleanup', rows, cases, altered))
    for label, r, c, p in mutations:
        try:
            validate(r, c, p)
        except AssertionError:
            continue
        raise AssertionError(f'corrupt {label} accepted')
    print('Fixed observer admission, silent success, actual rejection, diagnostic gaps, unchanged stages and independent cleanup verified.')


if __name__ == '__main__':
    main()
