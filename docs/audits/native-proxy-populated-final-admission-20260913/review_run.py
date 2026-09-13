"""Review the one admitted run, or reverify its already retained review."""
import argparse
import errno
import hashlib
import json
import os
import re

import admission
from contract import OUTPUT, OWNER, EXECUTION_OWNER, TASK, WORKER_CONTRACT, bounds, canonical, cases, roots, worker_sources
import installed_inputs
import local_files as files
import oracle
import records


def expected_files(review=False):
    names = {'execution-admission.json', 'issuer-inputs.json', 'frontier-inputs.json', 'worker-authority.json',
             'run-start.json', 'driver-inputs.json', 'journal.jsonl', 'result.json'}
    for case in cases():
        names.add(case['activation_path'].removeprefix(OUTPUT + '/'))
        if case['handoff_path']:
            names.add(case['handoff_path'].removeprefix(OUTPUT + '/'))
        for role in case['roles']:
            names.update(case['name'] + '.' + role + '.' + channel for channel in ('stdout', 'stderr'))
    if review:
        names.add('independent-review.json')
    return names


def read_outputs(review=False):
    files.directory_identity(OUTPUT)
    expected, found = expected_files(review), set()
    with os.scandir(files.ROOT / OUTPUT) as directory:
        for entry in directory:
            if len(found) >= len(expected):
                raise ValueError('run output has extra entries')
            found.add(entry.name)
    oracle.require(found == expected, 'run output file census is incomplete or contains extra artifacts')
    result = {}
    for name in sorted(expected):
        limit = bounds()['journal_bytes'] if name == 'journal.jsonl' else 4 * 1024 * 1024 if name in ('result.json', 'frontier-inputs.json') else 1048576
        mode = 0o600 if name == 'journal.jsonl' or name.endswith(('.stdout', '.stderr')) else 0o400
        result[name] = files.read_bytes(OUTPUT + '/' + name, limit, mode)
    return result


def document(outputs, name):
    body = outputs[name]
    result = json.loads(body)
    oracle.require(body == canonical(result), 'execution document lost its exact canonical seal: ' + name)
    return result


def native_absence(original, reader):
    try:
        current = reader.identity(original['pid'])
    except OSError as error:
        if error.errno != errno.ESRCH:
            raise
        current = None
    if current is not None:
        if all(current[key] == original[key] for key in ('pid', 'start_sec', 'start_usec')):
            raise ValueError('an original admitted native process is still present')
        current = {key: current[key] for key in ('pid', 'start_sec', 'start_usec')}
    return dict(original=original, current_birth=current, original_absent=True,
                evidence='native_ESRCH' if current is None else 'different_native_birth')


def group_absence(pid):
    try:
        os.killpg(pid, 0)
    except ProcessLookupError:
        return dict(pgid=pid, absent=True, evidence='group_query_ESRCH')
    raise ValueError('a selected worker group is present during independent review')


def join(outputs, plan, expected_permit):
    permit = document(outputs, 'execution-admission.json')
    frontier = document(outputs, 'frontier-inputs.json')
    oracle.require(frontier['schema'] == 'fsmgen.inactive_populated_execution_frontier.v1'
        and frontier['admission_commit'] == expected_permit['admission_commit'] and frontier['execution_owner'] == EXECUTION_OWNER,
        'saved execution frontier names a different admission or owner')
    oracle.require(admission.owner_status(frontier['task'], OWNER) == 'Status: `done`'
        and admission.owner_status(frontier['task'], EXECUTION_OWNER) == 'Status: `active`'
        and frontier['memory'].splitlines().count('- active_work_unit: `' + EXECUTION_OWNER + '`') == 1,
        'saved frontier did not authorize the exact separate execution owner')
    driver_inputs, issuer_inputs = document(outputs, 'driver-inputs.json'), document(outputs, 'issuer-inputs.json')
    for field in ('inputs', 'project_device', 'complete_native_dependency_closure', 'native_reader_dependency'):
        oracle.require(oracle.same(driver_inputs[field], issuer_inputs[field]), 'installed inputs changed between issue and consume')
    controller = driver_inputs['controller']
    records.fields(controller, 'pid ppid uid ruid start_sec start_usec')
    for number in controller.values():
        records.integer(number)
    oracle.require(0 < controller['pid'] <= 2147483647 and 0 < controller['ppid'] <= 2147483647
        and controller['start_sec'] > 0 and controller['start_usec'] < 1000000
        and controller['uid'] > 0 and controller['ruid'] == controller['uid'], 'driver native owner is not an ordinary user')
    expected = dict(expected_permit, task_sha256=hashlib.sha256(frontier['task'].encode()).hexdigest(),
        memory_sha256=hashlib.sha256(frontier['memory'].encode()).hexdigest(), frontier_sha256=hashlib.sha256(outputs['frontier-inputs.json']).hexdigest(),
        uid=controller['uid'], project_device=driver_inputs['project_device'])
    oracle.require(oracle.same(permit, expected), 'permit does not bind the exact retained frontier and selected input admission')
    expected_installed = {'/usr/bin/git': plan['git_launcher']}
    for tool in plan['toolchains'].values():
        expected_installed[tool['invocation_path']] = tool['invocation_binary']
        expected_installed[tool['native_path']] = tool['native_image']['binary']
    for row in plan['installed_modules']:
        expected_installed[row['installed_path']] = {key: row[key] for key in ('size_bytes', 'sha256')}
    oracle.require(len(driver_inputs['inputs']) == len(expected_installed)
        and {row['installed_path'] for row in driver_inputs['inputs']} == set(expected_installed), 'selected installed input closure is incomplete')
    for row in driver_inputs['inputs']:
        oracle.require(row['read_only'] is True and {key: row[key] for key in ('size_bytes', 'sha256')} == expected_installed[row['installed_path']],
            'fresh installed input receipt differs from the admitted selection')
    authority = document(outputs, 'worker-authority.json')
    expected_authority = dict(schema='fsmgen.inactive_populated_worker_authority.v1', source_revision=permit['admission_commit'],
        controller_pid=controller['pid'], contract_sha256=next(row['sha256'] for row in worker_sources() if row['path'] == WORKER_CONTRACT),
        source_pins=worker_sources(), worker_wall_seconds=bounds()['worker_wall_seconds'], output=OUTPUT)
    oracle.require(oracle.same(authority, expected_authority), 'worker authority differs from the exact committed source closure')
    oracle.require(oracle.same(document(outputs, 'run-start.json'), dict(schema='fsmgen.inactive_populated_run_start.v1',
        source_revision=permit['admission_commit'], controller_pid=controller['pid'],
        worker_authority_sha256=hashlib.sha256(outputs['worker-authority.json']).hexdigest())), 'one-use start marker is not bound to the original controller and authority')
    result = document(outputs, 'result.json')
    oracle.require(result['schema'] == 'fsmgen.inactive_populated_execution_result.v1' and result['success'] is True
        and result['first_error'] is None and not result['secondary_errors'] and result['admission'] == permit,
        'execution did not complete the admitted run successfully')
    oracle.require(result['synthetic_retirement_and_work_records'] is True
        and all(result[key] is False for key in ('compiler_execution', 'proxy_execution', 'live_collector_execution')),
        'execution report promotes inactive records into broader native authority')
    rows = oracle.journal_rows(outputs['journal.jsonl'])
    oracle.require(result['journal'] == dict(path=OUTPUT + '/journal.jsonl', completed_rows=len(rows),
        intended_prefix=records.file_pin(outputs['journal.jsonl']), first_failure=None), 'controller journal receipt differs from retained original bytes')
    begun, finished = oracle.one(rows, 'run_admitted'), oracle.one(rows, 'run_completed')
    oracle.require(begun['sequence'] == 0 and finished['sequence'] == len(rows) - 1 and begun['admission'] == permit
        and begun['controller'] == controller and finished['cases'] == len(cases()), 'global run boundaries omit exact admission or completion')
    oracle.require([value['case'] for value in result['cases']] == [case['name'] for case in cases()], 'run omitted or repeated a selected case')
    counts, births = [], []
    case_outcomes = [row for row in rows if row['event'] == 'case_outcome']
    oracle.require([row['result']['case'] for row in case_outcomes] == [case['name'] for case in cases()], 'journal repeats or omits a selected case outcome')
    preceding = begun['sequence']
    for case, outcome in zip(cases(), result['cases']):
        selected = [row for row in rows if row.get('case') == case['name']]
        oracle.require(selected and selected[0]['sequence'] > preceding, 'case execution overlaps an earlier unfinished case')
        end = next(row for row in rows if row['event'] == 'case_outcome' and row['result']['case'] == case['name'])
        oracle.require(end['result'] == outcome and max(row['sequence'] for row in selected) < end['sequence'], 'case outcome preceded or changed its original records')
        preceding = end['sequence']
        name = case['activation_path'].removeprefix(OUTPUT + '/')
        activation = document(outputs, name)
        records.fields(activation, 'schema execution_revision case store workspaces evidence births all_native_admitted')
        oracle.require(activation['schema'] == 'fsmgen.inactive_populated_activation.v1' and activation['execution_revision'] == permit['admission_commit']
            and activation['case'] == case['name'] and type(activation['all_native_admitted']) is int and activation['all_native_admitted'] == 1,
            'case activation does not bind every native role to the original admission')
        oracle.require(set(activation['births']) == set(case['roles']), 'activation lacks exact selected native roles')
        for role, birth in activation['births'].items():
            records.fields(birth, 'pid ppid uid ruid start_sec start_usec')
            for number in birth.values():
                records.integer(number)
            oracle.require(0 < birth['pid'] <= 2147483647 and birth['ppid'] == controller['pid'] and birth['uid'] == birth['ruid'] == controller['uid']
                and birth['start_sec'] > 0 and birth['start_usec'] < 1000000, 'worker native identity is not an original direct child of the admitted controller')
            births.append(dict(case=case['name'], role=role, identity=birth))
        streams = {role: {channel: outputs[case['name'] + '.' + role + '.' + channel] for channel in ('stdout', 'stderr')} for role in case['roles']}
        handoff = outputs[case['handoff_path'].removeprefix(OUTPUT + '/')] if case['handoff_path'] else None
        counts.append(oracle.check_case(case, outputs[name], selected, streams, outcome, plan['toolchains']['perl'], handoff))
    oracle.require(len({(row['identity']['pid'], row['identity']['start_sec'], row['identity']['start_usec']) for row in births}) == len(births),
        'separate worker roles share an original native birth')
    return dict(cases=counts, controller=controller, workers=births, journal_rows=len(rows),
        journal_bytes=len(outputs['journal.jsonl']), files=[dict(path=OUTPUT + '/' + name, **records.file_pin(body))
            for name, body in sorted(outputs.items()) if name != 'independent-review.json'],
        synthetic_retirement_and_work_records=True, native_proxy_and_live_execution_qualified=False)


def verify(saved=False):
    outputs = read_outputs(saved)
    permit = document(outputs, 'execution-admission.json')
    revision = permit['admission_commit']
    oracle.require(isinstance(revision, str) and re.fullmatch('[0-9a-f]{40}', revision) is not None, 'review requires a complete literal admission revision')
    selection, unused = admission.load_document(admission.BASE_RELATIVE + '/plan.json', 262144)
    installed_inputs.read_pin('/usr/bin/git', selection['git_launcher'])
    oracle.require(admission.git('log', '-1', '--format=%s', revision).decode().startswith(OWNER + ':'), 'run does not select the final admission work-unit commit')
    task = admission.git('show', revision + ':' + TASK).decode()
    oracle.require(admission.owner_status(task, OWNER) == 'Status: `done`'
        and admission.owner_status(task, EXECUTION_OWNER) == 'Status: `proposed`', 'source commit did not finish admission before the separate execution owner')
    plan, expected = admission.authenticated_sources(revision)
    joined = join(outputs, plan, expected)
    if saved:
        value = document(outputs, 'independent-review.json')
        oracle.require(value['join'] == joined, 'saved independent join does not rederive from retained original output')
    else:
        reader = installed_inputs.native_reader()
        leaders = [native_absence(joined['controller'], reader)] + [native_absence(row['identity'], reader) for row in joined['workers']]
        groups = [group_absence(row['identity']['pid']) for row in joined['workers']]
        absent = [root for root in roots() if files.direct(root, absent_ok=True) is None]
        oracle.require(absent == roots(), 'an owned fixture root remains present after the claimed cleanup')
        value = dict(schema='fsmgen.inactive_populated_independent_actual_review.v1', admission_commit=revision,
            join=joined, native_absence=leaders, groups=groups, absent_roots=absent,
            actual_selected_worker_execution_reviewed=True, compiler_execution=False, proxy_execution=False, live_collector_execution=False)
        files.write_document(OUTPUT + '/independent-review.json', value, 1048576)
    oracle.require(value['schema'] == 'fsmgen.inactive_populated_independent_actual_review.v1' and value['admission_commit'] == revision
        and value['absent_roots'] == roots() and len(value['groups']) == len(joined['workers']), 'review loses its exact original native or filesystem closure')
    oracle.require(value['actual_selected_worker_execution_reviewed'] is True
        and all(value[key] is False for key in ('compiler_execution', 'proxy_execution', 'live_collector_execution')), 'review changes its selected execution boundary')
    expected_leaders = [joined['controller']] + [row['identity'] for row in joined['workers']]
    oracle.require(len(value['native_absence']) == len(expected_leaders), 'native absence review is incomplete')
    for row, original in zip(value['native_absence'], expected_leaders):
        oracle.require(row['original'] == original and row['original_absent'] is True, 'review changes an original process identity')
        if row['current_birth'] is None:
            oracle.require(row['evidence'] == 'native_ESRCH', 'native disappearance is not an explicit no-such-process result')
        else:
            records.fields(row['current_birth'], 'pid start_sec start_usec')
            for number in row['current_birth'].values():
                records.integer(number)
            oracle.require(row['evidence'] == 'different_native_birth' and row['current_birth']['pid'] == original['pid']
                and row['current_birth']['start_sec'] > 0 and row['current_birth']['start_usec'] < 1000000
                and any(row['current_birth'][key] != original[key] for key in ('start_sec', 'start_usec')),
                'review confuses a still-present original process with PID reuse')
    oracle.require(value['groups'] == [dict(pgid=row['identity']['pid'], absent=True, evidence='group_query_ESRCH') for row in joined['workers']], 'review omits an independently absent original worker group')
    return value


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--review', action='store_true')
    group.add_argument('--verify-saved', action='store_true')
    args = parser.parse_args()
    result = verify(args.verify_saved)
    print(canonical(dict(admission_commit=result['admission_commit'], cases=len(result['join']['cases']),
        workers=len(result['join']['workers']), roots_absent=len(result['absent_roots']))).decode())
