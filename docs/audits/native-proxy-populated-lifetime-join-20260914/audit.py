"""Join the two preserved cooperative-lifetime qualifications without replay."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

import inventory
import qualify_actual

BASE, ROOT, SCOPE = inventory.BASE, inventory.ROOT, inventory.SCOPE


def read(name):
    return json.loads((BASE / name).read_bytes())


def require(condition, message):
    if not condition:
        raise ValueError(message)


def saved_reviewer(directory):
    argv = [sys.executable, '-B', directory + '/audit.py', '--verify-saved']
    result = subprocess.run(argv, cwd=ROOT, capture_output=True, timeout=60,
        env=dict(PATH='/usr/bin:/bin', LC_ALL='C', LANG='C', TMPDIR=str(ROOT / '.artifacts/tmp')))
    require(len(result.stdout) <= 65536 and len(result.stderr) <= 65536,
        'saved reviewer exceeded its selected output envelope')
    require(result.returncode == 0, 'saved reviewer failed: ' + directory + ': ' + result.stderr.decode())
    require(result.stdout, 'saved reviewer returned no result')
    return dict(argv=argv, exit_code=result.returncode, stdout=result.stdout.decode(), stderr=result.stderr.decode())


def verify():
    for row in read('source-pins.json'):
        require(inventory.pin(row['path']) == row, 'current join source or retained first proof changed: ' + row['path'])
    inputs = inventory.derive()
    require(inputs == read('input-pins.json'), 'selected committed input closure changed')
    empty_directory, populated_directory = SCOPE['empty_store_directory'], SCOPE['populated_directory']
    # Separate processes keep the historical private module namespaces isolated.
    empty_output = saved_reviewer(empty_directory)
    populated_output = saved_reviewer(populated_directory)
    empty = inventory.read(empty_directory + '/review.json')
    populated = inventory.read(populated_directory + '/review.json')
    require(json.loads(empty_output['stdout']) == dict(cases=empty['result']['cases'],
        journal_records=empty['result']['journal_records'], rejected_controls=len(empty['rejected_controls']),
        original_producer_replayed=False, success=True), 'empty-store reviewer result was omitted or promoted')
    require(json.loads(populated_output['stdout']) == populated, 'populated reviewer result no longer matches its original review')
    actual = qualify_actual.qualify()
    require(actual == read('actual-final.json')['result'], 'actual-evidence rejection controls no longer reconstruct')
    old_plan = inventory.read('docs/audits/native-proxy-language-coordination-admission-20260913/plan.json')
    new_plan = inventory.read('docs/audits/native-proxy-populated-final-admission-20260913/plan.json')
    selections = {}
    for language in ('perl', 'python'):
        old_tool, new_tool = old_plan['toolchains'][language], new_plan['toolchains'][language]
        selected = {key: old_tool[key] for key in ('invocation_binary', 'native_image', 'selected_sibling_basename')}
        require(selected == {key: new_tool[key] for key in selected}, 'recorded interpreter byte selections differ across the qualified epochs')
        selections[language] = selected
    require(empty['admission_commit'] == SCOPE['empty_store_admission_commit']
        and populated['admission_commit'] == SCOPE['populated_admission_commit'], 'the join changed an original admission epoch')
    require(empty['result']['first_outcome_success'] is True and empty['result']['original_producer_replayed'] is False
        and empty['result']['native_proxy_execution'] is False, 'empty-store qualification was replayed or promoted')
    require(populated['actual_selected_worker_execution_reviewed'] is True and populated['producer_replayed'] is False
        and populated['synthetic_retirement_and_work_records'] is True
        and all(populated[key] is False for key in ('compiler_execution', 'proxy_execution', 'live_collector_execution')),
        'populated qualification lost the exact actual/synthetic boundary')
    require(empty['native_proxy_startup_cause_established'] is False and empty['native_live_integration_pending'] is True
        and populated['native_live_startup_qualification_open'] is True, 'the join promoted broader native/live/startup authority')
    counts = {key: sum(case[key] for case in actual['cases']) for key in populated['counts']}
    require(counts == populated['counts'] and len(actual['cases']) == populated['cases'] == len(new_plan['cases']),
        'actual populated operation or ownership counts disagree')
    require(empty['result']['cases'] == len(old_plan['cases']), 'empty-store case count differs from its selected admission')
    old_roots, new_roots = empty['absent_fixture_roots'], populated['absent_roots']
    require(not set(old_roots) & set(new_roots), 'the two original qualification domains overlap')
    require(len(set(old_roots + new_roots)) == len(old_roots) + len(new_roots), 'an original root was counted twice')
    for relative in old_roots + new_roots:
        path = ROOT / relative
        require(not path.exists() and not path.is_symlink(), 'an original owned fixture root is present: ' + relative)
    files = qualify_actual.load_actual()
    worker_outputs = [body for name, body in files.items() if name.endswith('.stdout')]
    event_lines = [line for body in worker_outputs for line in body.splitlines(keepends=True)]
    geometry = dict(largest_worker_output=max(map(len, worker_outputs)),
        largest_worker_event=max(map(len, event_lines)),
        largest_worker_event_count=max(len(body.splitlines()) for body in worker_outputs),
        journal_bytes=populated['journal_bytes'], journal_rows=populated['journal_rows'])
    limits = new_plan['bounds']
    for field, bound in [('largest_worker_output', 'worker_output_bytes'), ('largest_worker_event', 'worker_event_bytes'),
                          ('largest_worker_event_count', 'worker_events'), ('journal_bytes', 'journal_bytes'),
                          ('journal_rows', 'journal_events')]:
        require(geometry[field] <= limits[bound], 'actual retained geometry exceeds its admitted limit: ' + field)
    first = read('actual-first.json')
    require(first['outputs']['exit'] == '0\n' and json.loads(first['outputs']['stdout']) == first['result'],
        'initial actual-evidence controls were omitted or normalized')
    require(inventory.pin(first['source']['path']) == first['source'], 'initial qualifier source changed')
    return dict(schema='fsmgen.cooperative_populated_lifetime_join.v1', owner=SCOPE['owner'],
        parent_owner=SCOPE['parent_owner'], next_owner=SCOPE['next_owner'], source_revision=SCOPE['source_revision'],
        selected_inputs=len(inputs['pins']), common_original_inputs=inputs['common_original_inputs'],
        shared_recorded_interpreter_selection=selections,
        empty_store=dict(admission_commit=empty['admission_commit'], execution_commit=SCOPE['empty_store_execution_commit'],
            result=empty['result'], scope=empty['scope'], rejected_controls=empty['rejected_controls'], roots_absent=old_roots),
        populated=dict(admission_commit=populated['admission_commit'], execution_commit=SCOPE['source_revision'],
            cases=populated['cases'], counts=counts, actual_geometry=geometry,
            retained_files=populated['retained_files'], retained_bytes=populated['retained_bytes'],
            native_absence_receipts=populated['native_absence_receipts'], group_absence_receipts=populated['group_absence_receipts'],
            roots_absent=new_roots, case_rejections=actual['case_rejections'], whole_run_rejections=actual['whole_run_rejections']),
        reviewer_outputs=dict(empty_store=empty_output, populated=populated_output),
        cooperative_populated_lifetime_qualified=True, python_populated_api_qualified=False,
        synthetic_retirement_and_work_records=True, producer_replayed=False, native_resampled=False,
        fixture_mutated=False, compiler_execution=False, proxy_execution=False, live_collector_execution=False,
        native_live_startup_qualification_open=True, remaining=SCOPE['missing_legs'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--save', action='store_true')
    group.add_argument('--verify-saved', action='store_true')
    args = parser.parse_args()
    result = verify()
    if args.save:
        with (BASE / 'review.json').open('x') as stream:
            json.dump(result, stream, sort_keys=True, indent=2)
            stream.write('\n')
    else:
        require(result == read('review.json'), 'saved cooperative-lifetime join changed')
    print(json.dumps(result, sort_keys=True, indent=2))
