"""Replay sealed source, native-event, original-result and qualification checks."""
from pathlib import Path
import base64
import copy
import gzip
import hashlib
import json
import re
import sys

AUDIT = Path('docs/audits/task-acceptance-index-observer-20261017')


def unblob(record):
    body = base64.b64decode(record['body_base64'], validate=True)
    assert len(body) == record['bytes'] and hashlib.sha256(body).hexdigest() == record['sha256']
    return body


def qualified_sources(record, current):
    assert record['sources_after'] == current, 'live inputs differ from qualified observation inputs'
    return True


def verify(record):
    assert record['source_conserved'] and record['git_conserved']
    assert record['sources_before'] == record['sources_after']
    assert record['git_before'] == record['git_after']
    for source in record['sources_before'].values():
        unblob(source)
    for field in ('entries', 'index', 'fixture_baseline'):
        unblob(record['git_before'][field])
    captures = {name: unblob(row) for name, row in record['captures'].items()}
    for row in record['admissions'].values():
        admission = json.loads(unblob(row))
        assert admission['sha256'] == {name: source['sha256'] for name, source in record['sources_before'].items()}
    for name, data in captures.items():
        if not name.endswith('/summary.json'):
            continue
        summary = json.loads(data)
        directory = name.rsplit('/', 1)[0]
        admission = json.loads(unblob(record['admissions'][directory + '-admission.json']))
        encoded = json.dumps(admission, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode()
        assert summary['admission_sha256'] == hashlib.sha256(encoded).hexdigest()
        assert summary['input_error'] is None and summary['test_error'] is None
        retained = {}
        for receipt in summary['receipts']:
            body = captures[f"{directory}/{receipt['label']}.json"]
            assert hashlib.sha256(body).hexdigest() == receipt['sha256']
            assert receipt['label'] not in retained
            retained[receipt['label']] = json.loads(body)
        for label, row in retained.items():
            if row['kind'] != 'stage':
                continue
            result, arguments = row['result'], row['arguments']
            stage = arguments['stage']
            assert stage in ('index_git', 'index_checker')
            cap = 1_048_576 if stage == 'index_git' else 4_194_304
            assert arguments['bounds'] == {'timeout_seconds': 10, 'capture_limit_bytes': cap}
            assert result['timeout_seconds'] == 10 and result['capture_limit_bytes'] == cap
            assert result['stage'] == stage
            assert arguments['containment'] == result['cleanup']['containment'] == 'task_acceptance_index_group'
            assert result['cleanup']['leader_reaped'] == result['cleanup']['group_gone'] == 1
            assert result['cleanup']['surviving_descendants'] == 0
            assert result['timed_out'] == result['output_limited'] == result['signal'] == 0
        for row in retained.values():
            if row['kind'] != 'case':
                continue
            result = row['result']
            native = [retained['stage_' + letters(i)]['result']
                      for i in range(row['first_stage'], row['last_stage'] + 1)
                      if 'stage_' + letters(i) in retained]
            nested = [*result['stages'], *([result['checker']] if result['checker'] is not None else [])]
            # T2068's final deliberate synthetic receipt bypasses the native
            # supervisor. Its caller owns removal; never label it native.
            synthetic = directory == 'index' and result['diagnostic'].startswith('fixture Git failed: synthetic unsettled receipt')
            if not synthetic and directory != 'control_retention_gap':
                assert native == nested
            if nested and not synthetic:
                assert result['cleanup']['retired'] == 1 and result['cleanup']['retained'] == 0
        if directory.startswith('control_'):
            assert summary['actual'] == [3, 21, 2] and summary['coverage_error'] is None
            diagnostics = json.dumps([summary['capture_gaps'], summary['retention_errors'], summary['receipt_coverage_error']])
            expected = {'control_query_gap': 'native_context_query', 'control_write_gap': 'missing_or_duplicate_native_event',
                        'control_retention_gap': 'exclusive observer retention', 'control_coverage_gap': 'missing retained receipt'}
            if directory in expected:
                assert expected[directory] in diagnostics
            else:
                assert not summary['capture_gaps'] and not summary['retention_errors']
                assert summary['receipt_coverage_error'] is None
            events = [json.loads(line) for line in captures[f'{directory}/events.jsonl'].splitlines()]
            assert len(events) == (0 if directory == 'control_write_gap' else 1)
            for event in events:
                assert event['result'] is None and event['errno'] == 1 and event['arguments'] == [0, 0]
                if directory != 'control_query_gap':
                    for who in ('caller', 'target'):
                        context = event['context'][who]
                        assert context['pid'] == event['pid'] == context['pgid'] == context['sid']
                        assert context['pgid_errno'] == context['sid_errno'] == 0
    if record['action'] == 'controls':
        assert [row['selector'] for row in record['rows']] == [
            'control_healthy', 'control_query_gap', 'control_write_gap', 'control_retention_gap',
            'control_diagnostic_errno', 'control_coverage_gap', 'reuse']
        assert [row['status'] == 0 for row in record['rows']] == [True, False, False, False, True, False, False]
        for row in record['rows'][:-1]:
            stdout = unblob(row['stdout'])
            assert b'not ok' not in stdout and re.search(rb'^1\.\.167$', stdout, re.M)
            assert len(re.findall(rb'^ok \d+ - ', stdout, re.M)) == 167
        assert b'exclusive observer directory' in unblob(record['rows'][-1]['stderr'])
    else:
        assert len(record['rows']) == 1 and record['rows'][0]['status'] == 0
        assert b'All tests successful' in unblob(record['rows'][0]['stdout'])
        for name, counts in [('index', [14, 57, 6]), ('policy', [40, 342, 36]), ('scope', [20, 199, 20])]:
            summary = json.loads(captures[f'{name}/summary.json'])
            assert summary['actual'] == counts
            assert not summary['retention_errors'] and not summary['capture_gaps']
            assert not summary['coverage_error'] and not summary['receipt_coverage_error']
            assert captures[f'{name}/events.jsonl'] == b''
    return True


def letters(number):
    result = ''
    while number:
        number, remainder = divmod(number - 1, 26)
        result = chr(97 + remainder) + result
    return result


def falsify(record):
    assert qualified_sources(record, record['sources_after'])
    for mutation in ('changed', 'missing'):
        current = copy.deepcopy(record['sources_after'])
        path = next(iter(current))
        if mutation == 'changed':
            current[path]['sha256'] = '0' * 64
        else:
            del current[path]
        try:
            qualified_sources(record, current)
        except AssertionError:
            continue
        raise AssertionError('qualification-source substitution admitted: ' + mutation)
    for label in ('source_digest', 'primary_index', 'lost_capture', 'promoted_query_gap', 'coverage_gap'):
        candidate = copy.deepcopy(record)
        if label == 'source_digest':
            next(iter(candidate['sources_before'].values()))['sha256'] = '0' * 64
        elif label == 'primary_index':
            candidate['git_after']['index']['sha256'] = '0' * 64
        elif label == 'lost_capture':
            del candidate['captures']['control_healthy/events.jsonl']
        elif label == 'promoted_query_gap':
            candidate['rows'][1]['status'] = 0
        else:
            summary = candidate['captures']['control_coverage_gap/summary.json']
            data = json.loads(unblob(summary))
            data['receipt_coverage_error'] = None
            body = json.dumps(data).encode()
            summary.update(bytes=len(body), sha256=hashlib.sha256(body).hexdigest(),
                           body_base64=base64.b64encode(body).decode())
        try:
            verify(candidate)
        except (AssertionError, KeyError, ValueError):
            continue
        raise AssertionError('hostile saved-record control admitted: ' + label)


if __name__ == '__main__':
    assert len(sys.argv) == 2 and sys.argv[1] in ('controls', 'regression', 'first-controls', 'pre-source-join-controls')
    record = json.loads(gzip.decompress((AUDIT / (sys.argv[1] + '.json.gz')).read_bytes()))
    if sys.argv[1] == 'first-controls':
        assert record['source_conserved'] and record['git_conserved']
        assert len(record['rows']) == 1 and record['rows'][0]['status'] == 20
        stdout = unblob(record['rows'][0]['stdout'])
        assert len(re.findall(rb'^not ok \d+ - (ordinary|stale) original child call exactly once$', stdout, re.M)) == 20
        assert len(re.findall(rb'^not ok ', stdout, re.M)) == 20
        for row in record['sources_before'].values():
            unblob(row)
    else:
        verify(record)
        if sys.argv[1] in ('controls', 'pre-source-join-controls'):
            falsify(record)
    print('Sealed index observer evidence verifies:', sys.argv[1])
