"""Accept custody of the failed qualification, never promote its native result."""
from pathlib import Path
import base64
import copy
import gzip
import hashlib
import json
import re
import sys
from run import blob, control_ready
from verify import qualified_sources, unblob, verify

AUDIT = Path('docs/audits/task-acceptance-index-observer-20261017')
FAILED = AUDIT / 'controls.json.gz'
PRIOR = AUDIT / 'pre-source-join-controls.json.gz'


def capture(record, path):
    return json.loads(unblob(record['captures'][path]))


def validate_failure(record):
    assert record['source_conserved'] and record['git_conserved']
    assert record['sources_before'] == record['sources_after'] and record['git_before'] == record['git_after']
    for collection in ('sources_before', 'captures', 'admissions'):
        for row in record[collection].values():
            unblob(row)
    for key in ('index', 'entries', 'fixture_baseline'):
        unblob(record['git_before'][key])
    row = record['rows'][3]
    assert row['selector'] == 'control_retention_gap' and row['status'] != 0
    output = unblob(row['stdout'])
    failures = re.findall(rb'^not ok \d+ - (.+)$', output, re.M)
    assert failures == [b'ordinary failure-only query', b'ordinary failure-only capture',
                        b'ordinary genuine checker success']
    assert re.search(rb'^1\.\.167$', output, re.M)
    stage = capture(record, 'control_retention_gap/stage_k.json')
    result = stage['result']
    assert stage['arguments']['stage'] == 'index_checker'
    assert stage['arguments']['bounds'] == {'timeout_seconds': 10, 'capture_limit_bytes': 4_194_304}
    assert result['status'] == 'exec_error' and result['exit_code'] == 126 and not result['ok']
    assert result['stdout'] == result['stderr'] == '' and result['exec_handoff_monotonic_ns'] is None
    assert result['timeout_seconds'] == 10 and result['capture_limit_bytes'] == 4_194_304
    assert result['cleanup']['leader_reaped'] == result['cleanup']['group_gone'] == 1
    assert result['cleanup']['surviving_descendants'] == result['signal'] == result['timed_out'] == result['output_limited'] == 0
    assert result == capture(record, 'control_retention_gap/case_a.json')['result']['checker']
    events = [json.loads(line) for line in unblob(record['captures']['control_retention_gap/events.jsonl']).splitlines()]
    assert len(events) == 2
    ordinary, intentional = events
    assert ordinary['label'] == 'stage_k' and ordinary['pid'] == 6828
    assert ordinary['arguments'] == [0, 0] and ordinary['result'] is None and ordinary['errno'] == 1
    assert 'pid=6828 operation=setpgid result=undef errno=1 ' in result['exec_error']
    assert ordinary['context_error'] is None
    for who in ('caller', 'target'):
        context = ordinary['context'][who]
        assert context['pid'] == context['pgid'] == 6828 and context['sid'] == 3382
        assert context['pgid_errno'] == context['sid_errno'] == 0
    assert result['started_monotonic_ns'] <= ordinary['observed_monotonic_ns'] <= ordinary['context_completed_monotonic_ns'] <= result['finished_monotonic_ns']
    relay = capture(record, 'control_retention_gap/ordinary-6828.json')
    assert relay == {'calls': 1, 'errno': 1, 'pid': 6828, 'queries': 1, 'result': None, 'writes': 1}
    assert intentional['label'] == 'stage_w' and intentional['pid'] == 7084
    assert intentional['context']['caller']['pid'] == intentional['context']['caller']['sid'] == 7084
    summary = capture(record, 'control_retention_gap/summary.json')
    assert summary['actual'] == [3, 21, 2] and not summary['capture_gaps']
    assert summary['input_error'] is None and summary['test_error'] is None
    assert summary['receipt_coverage_error'] == 'missing retained receipt'
    assert len(summary['retention_errors']) == 1 and summary['retention_errors'][0]['label'] == 'stage_a'
    assert 'exclusive observer retention' in summary['retention_errors'][0]['error']
    # The first unexpected rejection remains visible separately from the
    # predeclared retention collision and deliberate session-leader rejection.
    assert not control_ready(row, 'retention_gap')
    assert (row['status'] == 0) == False  # The old polarity-only predicate continued here.
    return True


def validate_guards(record, prior):
    verify(prior)
    for row in prior['rows'][:-1]:
        assert control_ready(row, row['selector'].removeprefix('control_'))
    decisions = [control_ready(row, row['selector'].removeprefix('control_')) for row in record['rows'][:-1]]
    assert decisions == [True, True, True, False, True, True]
    assert [row['selector'] for row in record['rows'][:4]] == [
        'control_healthy', 'control_query_gap', 'control_write_gap', 'control_retention_gap']
    # Old actual collection continued diagnostic_errno and coverage_gap. The
    # new predicate stops before them; no new native collection is executed.
    old_program = unblob(record['sources_before'][str(AUDIT / 'run.py')]).decode()
    assert "if (row['status'] == 0) != success:" in old_program
    pool = copy.deepcopy(record['sources_after'])
    assert qualified_sources(record, pool)
    for mutation in ('changed', 'missing'):
        candidate = copy.deepcopy(pool)
        path = 'scripts/check_task_acceptance.sh'
        if mutation == 'changed':
            candidate[path] = blob(unblob(candidate[path]) + b'\n# consistent source substitution\n')
            unblob(candidate[path])  # Valid bytes/hash/length, not a corrupt digest control.
        else:
            del candidate[path]
        try:
            qualified_sources(record, candidate)
        except AssertionError:
            continue
        raise AssertionError('source substitution was admitted')
    for output in (b'', b'Bail out! held\n', b'not ok 1 - deliberate\n1..167\n'):
        candidate = copy.deepcopy(prior['rows'][1])
        candidate['stdout'] = blob(output)
        assert not control_ready(candidate, 'query_gap')
    return True


def hostile_controls(record):
    for mutation in ('status', 'tap', 'event', 'bounds'):
        candidate = copy.deepcopy(record)
        if mutation == 'status':
            candidate['rows'][3]['status'] = 0
        elif mutation == 'tap':
            row = candidate['rows'][3]
            row['stdout'] = blob(unblob(row['stdout']).replace(b'not ok ', b'ok '))
        else:
            path = 'control_retention_gap/' + ('events.jsonl' if mutation == 'event' else 'stage_k.json')
            if mutation == 'event':
                events = [json.loads(line) for line in unblob(candidate['captures'][path]).splitlines()]
                events[0]['errno'] = 0
                raw = b''.join(json.dumps(value).encode() + b'\n' for value in events)
            else:
                stage = capture(candidate, path)
                stage['arguments']['bounds']['timeout_seconds'] = 20
                raw = json.dumps(stage).encode()
            candidate['captures'][path] = blob(raw)
        try:
            validate_failure(candidate)
        except AssertionError:
            continue
        raise AssertionError('failed native result promotion was admitted: ' + mutation)


if __name__ == '__main__':
    assert sys.argv[1:] in ([], ['--seal'])
    record = json.loads(gzip.decompress(FAILED.read_bytes()))
    prior = json.loads(gzip.decompress(PRIOR.read_bytes()))
    validate_failure(record)
    validate_guards(record, prior)
    hostile_controls(record)
    proof = {'schema': 'fsmgen.failed_index_observer_custody.v1',
             'failed_capture_sha256': hashlib.sha256(FAILED.read_bytes()).hexdigest(),
             'prior_capture_sha256': hashlib.sha256(PRIOR.read_bytes()).hexdigest(),
             'source': {str(AUDIT / name): blob((AUDIT / name).read_bytes())
                        for name in ('verify_failure.py', 'run.py', 'verify.py')},
             'scope': 'Failed qualification remains failed. Source-join and early-stop predicates qualify on complete retained inputs. Native cause and full observer qualification remain open. No original tests or native retry.'}
    seal = AUDIT / 'failure-reader.json.gz'
    if sys.argv[1:]:
        with seal.open('xb') as stream:
            stream.write(gzip.compress(json.dumps(proof, sort_keys=True).encode(), mtime=0))
    else:
        assert json.loads(gzip.decompress(seal.read_bytes())) == proof, 'saved reader inputs changed'
    print('Failed qualification preserved; native custody, source join and immediate-stop controls pass. Native cause remains unknown.')
