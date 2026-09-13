"""Independently join retained worker bytes, admission and native cleanup receipts."""

import argparse
import copy
import hashlib
import json
from pathlib import Path
import subprocess
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
ADMISSION = BASE.parent / 'native-proxy-language-coordination-admission-20260913'
REVISION = '295130388c20c6ee94650c610c2df6d597eeffa7'
OUTPUT = '.artifacts/logs/' + BASE.name
sys.path.insert(0, str(ADMISSION))
from oracle import native_birth, verify_journal
from image_receipts import verify as verify_images


def canonical(value):
    return (json.dumps(value, sort_keys=True, separators=(',', ':')) + '\n').encode()


def pin(path):
    body = path.read_bytes()
    return dict(path=path.relative_to(ROOT).as_posix(), size_bytes=len(body),
                sha256=hashlib.sha256(body).hexdigest())


def decode(files):
    result = {}
    for row in files:
        body = bytes.fromhex(row['bytes_hex'])
        assert len(body) == row['size_bytes']
        assert hashlib.sha256(body).hexdigest() == row['sha256']
        assert row['path'] not in result
        result[row['path']] = body
    return result


def expected_files(plan):
    paths = set(plan['prospective_outputs']) | {OUTPUT + '/execution-admission.json'}
    log = '.artifacts/logs/' + ADMISSION.name
    for stage in ('commit', 'execution-permit', 'actual-execution'):
        paths.update(log + '/' + stage + '.' + suffix for suffix in ('stdout', 'stderr', 'exit'))
    return paths


def verify_run(files, plan, task, census):
    assert set(files) == expected_files(plan)
    permit = json.loads(files[OUTPUT + '/execution-admission.json'])
    assert permit == dict(schema='fsmgen.language_coordination_execution_admission.v1',
        execution_owner=plan['execution_owner'], admission_commit=REVISION,
        plan_sha256=pin(ADMISSION / 'plan.json')['sha256'],
        preflight_sha256=pin(ADMISSION / 'preflight-pins.json')['sha256'],
        task_sha256=hashlib.sha256(task).hexdigest())
    marker = ('- ID: `' + plan['execution_owner'] + '`\n').encode()
    assert task.count(marker) == 1
    assert b'Status: `active`' in task.split(marker)[1].split(b'- ID: `', 1)[0]
    log = '.artifacts/logs/' + ADMISSION.name
    for stage in ('commit', 'execution-permit', 'actual-execution'):
        assert files[log + '/' + stage + '.exit'] == b'0\n'
    assert b'[doctrine] all doctrine checks passed' in files[log + '/commit.stdout'] + files[log + '/commit.stderr']
    assert json.loads(files[log + '/actual-execution.stdout']) == dict(
        cases=12, native_proxy_execution=False, remaining_objects=0, success=True, workers=20)

    raw = files[OUTPUT + '/journal.jsonl']
    assert len(raw) <= plan['bounds']['journal_bytes']
    rows = [json.loads(line) for line in raw.splitlines()]
    assert b''.join(map(canonical, rows)) == raw
    first, last = rows[0], rows[-1]
    assert first['admission_commit'] == REVISION
    assert first['plan_sha256'] == permit['plan_sha256']
    assert first['preflight_sha256'] == permit['preflight_sha256']
    uid = first['controller']['uid']
    result = verify_journal(rows, plan, uid)
    result.update(verify_images(rows, plan))
    assert last['event'] == 'run_finished' and last['success'] is True
    assert last['result'] == result
    assert len([row for row in rows if row['event'] == 'run_finished']) == 1
    reaps = [row for row in rows if row['event'] == 'reaped']
    stream_paths = set()
    for row in reaps:
        for channel, receipt in row['streams'].items():
            body = files[receipt['path']]
            assert len(body) == receipt['size_bytes']
            assert hashlib.sha256(body).hexdigest() == receipt['sha256']
            assert receipt['path'] not in stream_paths
            stream_paths.add(receipt['path'])
    assert len(stream_paths) == 40
    attempt = json.loads(files[OUTPUT + '/attempt.json'])
    assert attempt == dict(schema='fsmgen.language_coordination_first_attempt.v1',
        success=True, first_failure=None, separate_recovery_errors=[], remaining_objects=[],
        launched_workers=20, all_worker_outcomes_consumed=True,
        journal=dict(path=OUTPUT + '/journal.jsonl', size_bytes=len(raw),
                     sha256=hashlib.sha256(raw).hexdigest()),
        runtime_qualification=False, native_proxy_execution=False)

    spawned = [row for row in rows if row['event'] == 'native_spawned']
    owners = [first['controller']] + [row['identity'] for row in rows
        if row['event'] in ('native_spawned', 'probe_native_admitted')]
    assert [row['original'] for row in census['original_births_absent']] == owners
    assert len({native_birth(value) for value in owners}) == 25
    for row in census['original_births_absent']:
        if row['disposition'] == 'native_esrch':
            assert row['errno'] == 3
        else:
            assert row['disposition'] == 'pid_reused_by_different_birth'
            assert native_birth(row['current']) != native_birth(row['original'])
    assert census['groups'] == [dict(pgid=row['pgid'], disposition='numeric_group_absent') for row in spawned]
    assert census['absent_objects'] == plan['prospective_objects']
    assert census['owner'] == plan['execution_owner']
    assert census['original_producer_replayed'] is census['native_proxy_execution'] is False
    # Compare only values from the same controller clock; worker-local clocks stay local.
    case_walls = {}
    for case in plan['cases']:
        start = next(row['controller_ns'] for row in rows if row['event'] == 'case_started' and row['case'] == case['name'])
        end = next(row['controller_ns'] for row in rows if row['event'] == 'case_finished' and row['case'] == case['name'])
        assert 0 <= end - start <= plan['bounds']['case_seconds'] * 1_000_000_000
        case_walls[case['name']] = end - start
    total = last['controller_ns'] - first['controller_ns']
    assert 0 <= total <= plan['bounds']['total_seconds'] * 1_000_000_000
    return dict(**result, journal_records=len(rows), journal_bytes=len(raw),
        worker_stream_bytes=sum(len(files[path]) for path in stream_paths),
        native_owner_births_absent=len(owners), native_groups_absent=len(spawned),
        case_controller_ns=case_walls, total_controller_ns=total,
        first_outcome_success=True, original_producer_replayed=False)


def reseal(files, rows):
    """Keep altered carriers coherent, forcing semantic rather than stale-hash rejection."""
    for index, row in enumerate(rows):
        row['sequence'] = index
    for row in rows:
        if row['event'] != 'reaped':
            continue
        raw = b''.join(canonical(event['value']) for event in rows
            if event['event'] == 'worker_event' and event['worker'] == row['worker'])
        receipt = row['streams']['stdout']
        receipt.update(size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
        files[receipt['path']] = raw
    raw = b''.join(map(canonical, rows))
    files[OUTPUT + '/journal.jsonl'] = raw
    attempt = json.loads(files[OUTPUT + '/attempt.json'])
    attempt['journal'].update(size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
    files[OUTPUT + '/attempt.json'] = canonical(attempt)


def falsify(files, plan, task, census):
    rows = [json.loads(line) for line in files[OUTPUT + '/journal.jsonl'].splitlines()]
    choose = lambda values, predicate: next(row for row in values if predicate(row))
    mutations = (
        ('lost_group_settlement', lambda r: choose(r, lambda v: v['event'] == 'reaped').update(group_gone=False)),
        ('changed_native_image', lambda r: choose(r, lambda v: v['event'] == 'native_admitted')['native_image'].update(path='/different/Python')),
        ('cancellation_promoted_to_success', lambda r: choose(r, lambda v: v['event'] == 'reaped' and v['exit_code'] == -15).update(exit_code=0)),
        ('omission_control_promoted_to_sealed', lambda r: choose(r, lambda v: v['event'] == 'worker_event' and v['value']['event'] == 'probe_result' and v['value']['inherited'])['value'].update(closed=True, inherited=False)),
        ('missing_removal', lambda r: r.remove(choose(r, lambda v: v['event'] == 'removed'))),
        ('hidden_recovery', lambda r: choose(r, lambda v: v['event'] == 'reaped').update(separate_recovery=True)),
        ('native_proxy_authority_promoted', lambda r: r[0].update(native_proxy_execution=True)),
    )
    rejected = []
    for name, mutate in mutations:
        changed_rows, changed_files = copy.deepcopy(rows), dict(files)
        mutate(changed_rows)
        reseal(changed_files, changed_rows)
        try:
            verify_run(changed_files, plan, task, census)
        except (AssertionError, KeyError, ValueError):
            rejected.append(name)
        else:
            raise AssertionError('altered actual join accepted: ' + name)
    first_stdout = next(path for path in sorted(files) if path.startswith(OUTPUT + '/') and path.endswith('.stdout'))
    variants = [
        ('missing_retained_stream', {key: value for key, value in files.items() if key != first_stdout}, census),
        ('changed_retained_stream', dict(files, **{first_stdout: files[first_stdout] + b'\n'}), census),
        ('missing_owner_absence', files, dict(census, original_births_absent=census['original_births_absent'][:-1])),
    ]
    for name, changed_files, changed_census in variants:
        try:
            verify_run(changed_files, plan, task, changed_census)
        except (AssertionError, KeyError, ValueError):
            rejected.append(name)
        else:
            raise AssertionError('altered raw/native join accepted: ' + name)
    return rejected


def verify():
    for row in json.loads((BASE / 'audit-pins.json').read_bytes()):
        assert pin(ROOT / row['path']) == row
    inputs = json.loads((BASE / 'inputs.json').read_bytes())
    for row in inputs:
        assert pin(ROOT / row['path']) == row
        body = subprocess.check_output(['git', 'show', REVISION + ':' + row['path']], cwd=ROOT)
        assert len(body) == row['size_bytes'] and hashlib.sha256(body).hexdigest() == row['sha256']
    plan = json.loads((ADMISSION / 'plan.json').read_bytes())
    retained = json.loads((BASE / 'first-run.json').read_bytes())
    assert retained['owner'] == plan['execution_owner'] and retained['admission_commit'] == REVISION
    files = decode(retained['files'])
    task = (BASE / 'execution-task.md.source').read_bytes()
    census = json.loads((BASE / 'post-run-census.json').read_bytes())
    result = verify_run(files, plan, task, census)
    controls = falsify(files, plan, task, census)
    for relative in plan['prospective_objects']:
        path = ROOT / relative
        assert not path.exists() and not path.is_symlink()
    return dict(schema='fsmgen.language_coordination_actual_review.v1',
        owner=plan['execution_owner'], admission_commit=REVISION, source_inputs=len(inputs),
        retained_files=len(files), result=result, rejected_controls=controls,
        absent_fixture_roots=plan['prospective_objects'],
        scope=plan['scope'], native_proxy_startup_cause_established=False,
        native_live_integration_pending=True)


def main():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain', action='store_true')
    group.add_argument('--verify-saved', action='store_true')
    args = parser.parse_args()
    result = verify()
    if args.retain:
        with (BASE / 'review.json').open('x') as stream:
            json.dump(result, stream, sort_keys=True, indent=2)
            stream.write('\n')
    else:
        assert result == json.loads((BASE / 'review.json').read_bytes())
    print(json.dumps(dict(cases=result['result']['cases'],
        journal_records=result['result']['journal_records'], rejected_controls=len(result['rejected_controls']),
        original_producer_replayed=False, success=True), sort_keys=True))


if __name__ == '__main__':
    main()
