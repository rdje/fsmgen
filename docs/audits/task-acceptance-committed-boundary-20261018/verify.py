"""Verify committed boundary custody and its original positive/negative case oracle."""
from pathlib import Path
import gzip
import hashlib
import json
import re
import sys

if not __debug__:
    raise SystemExit('Verification assertions must be enabled.')
ROOT = Path(__file__).resolve().parents[3]
AUDIT = Path('docs/audits/task-acceptance-committed-boundary-20261018')
BASE = Path('docs/audits/task-acceptance-index-observer-20261017')
QUALIFIED = Path('docs/audits/task-acceptance-index-prospective-20261018/corrected-controls.json.gz')
TARGET = 't/2072-task-acceptance-box-boundaries.t'
CASES = [('box_root_sibling', 1), ('box_regression_sibling', 1), ('box_indented_sibling', 1),
         ('box_wrapped', 0), ('box_blank_wrapped', 0), ('box_nested', 0), ('box_tab_wrapped', 0),
         ('box_peer_checkbox', 1), ('box_heading', 1)]
sys.path.insert(0, str(ROOT / BASE))
from verify import unblob, verify as verify_qualification, qualified_sources, letters


def case_oracle(result, name, code):
    assert result['schema'] == 'fsmgen.test.task_acceptance_index_case.v1'
    assert result['case'] == name and result['status'] == 'checker_returned'
    assert result['main_index_conserved'] == 1 and result['registry_co_staged'] == 0
    assert result['cleanup'] == {'retired': 1, 'retained': 0}
    assert len(result['stages']) == 10
    checked = result['checker']
    assert checked['exit_code'] == code and checked['exec_error'] is None
    assert checked['ok'] == (1 if code == 0 else 0)
    if code == 0:
        assert 'root=git_history, no-regression=prove_summary' in checked['stdout']
    else:
        box = 'ROOT CAUSE' if name == 'box_root_sibling' else 'NO REGRESSION'
        assert 'fresh checked ' + box + ' box' in checked['stderr']
    return True


def validate(record):
    assert record['schema'] == 'fsmgen.committed_boundary_observation.v1'
    assert record['owner'] == 'TASK-ACCEPTANCE-CHECKLIST-BODY-BOUNDARY.2.2'
    assert record['source_conserved'] and record['git_conserved']
    assert record['sources_before'] == record['sources_after'] and record['git_before'] == record['git_after']
    for row in record['sources_before'].values():
        unblob(row)
    for key in ('entries', 'index', 'fixture_baseline'):
        unblob(record['git_before'][key])
    proof = (ROOT / QUALIFIED).read_bytes()
    assert record['qualification'] == {'path': str(QUALIFIED), 'sha256': hashlib.sha256(proof).hexdigest()}
    qualified = json.loads(gzip.decompress(proof))
    assert verify_qualification(qualified)
    assert qualified_sources(qualified, {name: record['sources_before'][name] for name in qualified['sources_after']})
    required = {str(AUDIT / name) for name in
                ('BoundaryIndexObserver.pm', 'run.py', 'verify.py', 'preflight.t', 'preflight.py', 'contract.json')}
    assert set(record['sources_before']) == set(qualified['sources_after']) | required | {TARGET}
    row = record['row']
    assert row['status'] == 0 and row['command'][-1] == TARGET
    assert '-MBoundaryIndexObserver' in row['command']
    output = unblob(row['stdout'])
    unblob(row['stderr'])
    assert re.search(rb'^1\.\.3$', output, re.M)
    assert len(re.findall(rb'^ok \d+ - ', output, re.M)) == 3
    assert not re.search(rb'^\s*(?:not ok\b|Bail out!)', output, re.M)
    captured = {name: unblob(value) for name, value in record['captures'].items()}
    summary = json.loads(captured['summary.json'])
    admission = json.loads(unblob(record['admission']))
    assert summary['schema'] == 'fsmgen.fixed_index_observation.v1'
    assert admission['schema'] == 'fsmgen.fixed_index_observer_admission.v1'
    assert admission['selector'] == admission['target'] == TARGET and admission['scenario'] == 'none'
    assert admission['expected'] == summary['actual'] == [9, 90, 9]
    assert admission['sha256'] == {name: value['sha256'] for name, value in record['sources_before'].items()}
    canonical = json.dumps(admission, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode()
    assert summary['admission_sha256'] == hashlib.sha256(canonical).hexdigest()
    for key in ('coverage_error', 'receipt_coverage_error', 'input_error', 'test_error'):
        assert summary[key] is None
    assert not summary['capture_gaps'] and not summary['retention_errors']
    assert captured['events.jsonl'] == b''
    retained = {}
    for receipt in summary['receipts']:
        body = captured[receipt['label'] + '.json']
        assert receipt['label'] not in retained and hashlib.sha256(body).hexdigest() == receipt['sha256']
        retained[receipt['label']] = json.loads(body)
    assert len(retained) == 108
    assert set(captured) == {'events.jsonl', 'summary.json'} | {label + '.json' for label in retained}
    assert {row['kind'] for row in retained.values()} == {'stage', 'case'}
    for i, (name, code) in enumerate(CASES, 1):
        case = retained['case_' + letters(i)]
        assert case['kind'] == 'case' and case['arguments'] == [name]
        assert case['first_stage'] == (i - 1) * 11 + 1 and case['last_stage'] == i * 11
        result = case['result']
        assert case_oracle(result, name, code)
        native = [retained['stage_' + letters(n)] for n in range(case['first_stage'], case['last_stage'] + 1)]
        assert [item['result'] for item in native] == [*result['stages'], result['checker']]
        for n, item in enumerate(native):
            kind = 'index_git' if n < 10 else 'index_checker'
            cap = 1_048_576 if n < 10 else 4_194_304
            stage, arguments = item['result'], item['arguments']
            assert item['kind'] == 'stage' and arguments['stage'] == stage['stage'] == kind
            assert arguments['bounds'] == {'timeout_seconds': 10, 'capture_limit_bytes': cap}
            assert stage['timeout_seconds'] == 10 and stage['capture_limit_bytes'] == cap
            assert arguments['containment'] == stage['cleanup']['containment'] == 'task_acceptance_index_group'
            assert stage['cleanup']['leader_reaped'] == stage['cleanup']['group_gone'] == 1
            assert stage['cleanup']['surviving_descendants'] == 0
            assert stage['timed_out'] == stage['output_limited'] == stage['signal'] == 0
            assert stage['exec_error'] is None
            if n < 10:
                assert stage['ok'] == 1 and stage['exit_code'] == 0
    return True


if __name__ == '__main__':
    assert sys.argv[1:] in ([], ['--current'])
    record = json.loads(gzip.decompress((ROOT / AUDIT / 'result.json.gz').read_bytes()))
    started = json.loads(gzip.decompress((ROOT / AUDIT / 'started.json.gz').read_bytes()))
    assert all(record[key] == value for key, value in started.items())
    assert validate(record)
    if sys.argv[1:]:
        assert all((ROOT / name).read_bytes() == unblob(row) for name, row in record['sources_after'].items())
    print('Committed-only boundary source/receipt/native/case acceptance passes; historical and independent gates remain open.')
