"""In-memory whole-run evidence, admission and native-absence review models."""
import copy
from contextlib import ExitStack
import errno
import hashlib
import json
from pathlib import PurePosixPath
import stat
from types import SimpleNamespace
from unittest.mock import patch

import admission
from build_plan import build
from contract import ROOT, OWNER, EXECUTION_OWNER, OUTPUT, TASK, WORKER_CONTRACT, canonical, cases, roots, worker_sources
import installed_inputs
from qualify_admission import state as active_state
from qualify_driver import run_case
from qualify_files import World, ModelPath
import records
import review_run


def remap_model(previous, offset):
    """Give each synthetic case distinct births while retaining all byte bindings."""
    replacements = {}

    def birth(value):
        return dict(value, pid=value['pid'] + offset * 10000, start_sec=value['start_sec'] + offset)

    for row in previous['trace']:
        if row['kind'] == 'result' and row['operation'] == 'observe':
            record = row['result']['result']['value']['observation_reference']['record']
            replacements[record['reference_key']] = records.observation_key(record['evidence_directory'], birth(record['observer_birth']), birth(record['target_birth']))

    def walk(value):
        if isinstance(value, list):
            return [walk(item) for item in value]
        if isinstance(value, str):
            for old, new in replacements.items():
                value = value.replace(old, new)
            return value
        if not isinstance(value, dict):
            return value
        if set(value) == {'pid', 'ppid', 'uid', 'ruid', 'start_sec', 'start_usec'}:
            return birth(value)
        result = {key: walk(item) for key, item in value.items()}
        if set(value) == {'identity', 'bytes_hex'}:
            body = records.octets(value['bytes_hex'])
            if body.startswith(b'{'):
                body = canonical(walk(json.loads(body)))
            result['bytes_hex'] = body.hex()
            result['identity'].update(records.file_pin(body))
        return result

    result = walk(previous)
    result['native_model_offset'] = offset
    return result


def whole_run(plan):
    original = json.loads((ROOT / WORKER_CONTRACT).with_name('qualification.json').read_bytes())
    state = active_state()
    frontier = dict(schema='fsmgen.inactive_populated_execution_frontier.v1', admission_commit=state['revision'],
        execution_owner=EXECUTION_OWNER, task=state['current_task'], memory=state['memory'])
    expected = dict(schema='fsmgen.inactive_populated_execution_permit.v1', admission_commit=state['revision'],
        execution_owner=EXECUTION_OWNER, output=OUTPUT, plan_sha256=records.file_pin(canonical(plan))['sha256'],
        source_pins_sha256='b' * 64, reusable=False, compiler_execution=False, proxy_execution=False, live_collector_execution=False)
    controller = dict(pid=999, ppid=777, uid=501, ruid=501, start_sec=99, start_usec=999)
    permit = dict(expected, task_sha256=records.file_pin(frontier['task'].encode())['sha256'],
        memory_sha256=records.file_pin(frontier['memory'].encode())['sha256'], frontier_sha256=records.file_pin(canonical(frontier))['sha256'], uid=501, project_device=7)
    selected = {'/usr/bin/git': plan['git_launcher']}
    for tool in plan['toolchains'].values():
        selected[tool['invocation_path']] = tool['invocation_binary']
        selected[tool['native_path']] = tool['native_image']['binary']
    for row in plan['installed_modules']:
        selected[row['installed_path']] = {key: row[key] for key in ('size_bytes', 'sha256')}
    installed = dict(schema='fsmgen.inactive_populated_fresh_installed_inputs.v1', controller=controller, project_device=7,
        inputs=[dict(installed_path=path, **pin, device=8, inode=index + 1, mode=0o555, uid=0, read_only=True)
                for index, (path, pin) in enumerate(sorted(selected.items()))], complete_native_dependency_closure=False,
        native_reader_dependency='/usr/lib/libproc.dylib')
    issuer = copy.deepcopy(installed)
    issuer['controller'].update(pid=888, start_usec=888)
    authority = dict(schema='fsmgen.inactive_populated_worker_authority.v1', source_revision=state['revision'],
        controller_pid=controller['pid'], contract_sha256=next(row['sha256'] for row in worker_sources() if row['path'] == WORKER_CONTRACT),
        source_pins=worker_sources(), worker_wall_seconds=plan['bounds']['worker_wall_seconds'], output=OUTPUT)
    outputs = {name: canonical(value) for name, value in {
        'execution-admission.json': permit, 'frontier-inputs.json': frontier, 'issuer-inputs.json': issuer,
        'driver-inputs.json': installed, 'worker-authority.json': authority,
        'run-start.json': dict(schema='fsmgen.inactive_populated_run_start.v1', source_revision=state['revision'],
            controller_pid=controller['pid'], worker_authority_sha256=records.file_pin(canonical(authority))['sha256'])}.items()}
    rows, outcomes = [dict(event='run_admitted', admission=permit, controller=controller)], []
    for index, (case, previous) in enumerate(zip(cases(), original['cases'])):
        machine, result = run_case(case, remap_model(previous, index), plan['toolchains'])
        if not result['success']:
            raise AssertionError('whole-run model failed: ' + str(result['first_error']))
        rows.extend(machine.journal)
        rows.append(dict(event='case_outcome', result=result))
        outcomes.append(result)
        for path, value in machine.documents.items():
            outputs[path.removeprefix(OUTPUT + '/')] = canonical(value)
        for role, worker in machine.workers.items():
            for channel, body in worker.buffers.items():
                outputs[case['name'] + '.' + role + '.' + channel] = bytes(body)
    rows.append(dict(event='run_completed', cases=len(outcomes)))
    rows = [dict(row, sequence=index, elapsed_ns=index * 1000) for index, row in enumerate(rows)]
    outputs['journal.jsonl'] = b''.join(canonical(row) + b'\n' for row in rows)
    result = dict(schema='fsmgen.inactive_populated_execution_result.v1', admission=permit, success=True,
        first_error=None, secondary_errors=[], cases=outcomes, journal=dict(path=OUTPUT + '/journal.jsonl',
            completed_rows=len(rows), intended_prefix=records.file_pin(outputs['journal.jsonl']), first_failure=None),
        synthetic_retirement_and_work_records=True, compiler_execution=False, proxy_execution=False, live_collector_execution=False)
    outputs['result.json'] = canonical(result)
    if set(outputs) != review_run.expected_files():
        raise AssertionError('whole-run model file closure differs')
    return outputs, expected


def qualify():
    checks, rejected = [], []
    plan = build()

    def check(name, value):
        if not value or name in checks:
            raise AssertionError(name)
        checks.append(name)

    def reject(name, operation, expected=(ValueError, KeyError, TypeError), contains=None):
        try:
            operation()
        except expected as error:
            if contains and contains not in str(error):
                raise AssertionError(name + ': wrong primary failure') from error
            rejected.append(dict(name=name, error=str(error)))
            return error
        raise AssertionError(name + ': unexpectedly accepted')

    outputs, expected = whole_run(plan)
    joined = review_run.join(outputs, plan, expected)
    check('whole-run envelope reconstructs every fixed original worker', len(joined['workers']) == 15 and len(joined['cases']) == 6)
    check('whole-run envelope retains the original file census', len(joined['files']) == len(plan['expected_run_files']) == 46)
    for name, file, mutation in [
        ('changed saved execution owner', 'frontier-inputs.json', lambda value: value.update(execution_owner=OWNER)),
        ('changed saved task bytes', 'frontier-inputs.json', lambda value: value.update(task=value['task'] + '\n')),
        ('incomplete installed inputs', 'driver-inputs.json', lambda value: value['inputs'].pop()),
        ('changed native interpreter bytes', 'driver-inputs.json', lambda value: value['inputs'][0].update(sha256='0' * 64)),
        ('changed worker source closure', 'worker-authority.json', lambda value: value['source_pins'].pop()),
        ('changed one-use controller', 'run-start.json', lambda value: value.update(controller_pid=1)),
        ('missing selected case', 'result.json', lambda value: value['cases'].pop()),
        ('promoted native proxy authority', 'result.json', lambda value: value.update(proxy_execution=True))]:
        changed = copy.deepcopy(outputs)
        value = json.loads(changed[file])
        mutation(value)
        changed[file] = canonical(value)
        reject(name, lambda: review_run.join(changed, plan, expected))

    reader = SimpleNamespace(identity=lambda pid: (_ for _ in ()).throw(OSError(errno.ESRCH, 'model absent')))
    check('native ESRCH independently proves original absence', review_run.native_absence(joined['controller'], reader)['original_absent'])
    reader.identity = lambda pid: copy.deepcopy(joined['controller'])
    reject('still-live original controller', lambda: review_run.native_absence(joined['controller'], reader))
    reader.identity = lambda pid: dict(joined['controller'], start_usec=998)
    check('different native birth keeps PID reuse distinct', review_run.native_absence(joined['controller'], reader)['evidence'] == 'different_native_birth')
    reader.identity = lambda pid: (_ for _ in ()).throw(OSError(errno.EPERM, 'model denied'))
    reject('native permission error is not absence', lambda: review_run.native_absence(joined['controller'], reader), OSError)
    with patch.object(review_run.os, 'killpg', side_effect=ProcessLookupError(errno.ESRCH, 'model absent')):
        check('group query ESRCH proves absence without sending a signal', review_run.group_absence(1001)['absent'])
    with patch.object(review_run.os, 'killpg', return_value=None):
        reject('present group is not absence', lambda: review_run.group_absence(1001))

    # Exercise the full review and saved reverify entrypoints with only in-memory
    # files and explicit native/group query models. Nothing is written or signaled.
    saved_outputs = copy.deepcopy(outputs)
    reader.identity = lambda pid: (_ for _ in ()).throw(OSError(errno.ESRCH, 'model absent'))
    def save(path, value, limit):
        name = path.removeprefix(OUTPUT + '/')
        body = canonical(value)
        if name in saved_outputs or len(body) > limit:
            raise ValueError('model review output is not exclusive or bounded')
        saved_outputs[name] = body
        return dict(path=path, **records.file_pin(body))
    with ExitStack() as stack:
        stack.enter_context(patch.object(review_run, 'read_outputs', lambda saved: copy.deepcopy(saved_outputs)))
        stack.enter_context(patch.object(admission, 'git', lambda *args: (OWNER + ': final admission\n').encode() if args[0] == 'log' else active_state()['committed_task'].encode()))
        stack.enter_context(patch.object(admission, 'load_document', lambda *args: (plan, canonical(plan))))
        stack.enter_context(patch.object(admission, 'authenticated_sources', lambda revision: (plan, expected)))
        stack.enter_context(patch.object(installed_inputs, 'read_pin', lambda *args: None))
        stack.enter_context(patch.object(installed_inputs, 'native_reader', lambda: reader))
        stack.enter_context(patch.object(review_run.os, 'killpg', side_effect=ProcessLookupError(errno.ESRCH, 'model absent')))
        stack.enter_context(patch.object(review_run.files, 'direct', lambda *args, **kwargs: None))
        stack.enter_context(patch.object(review_run.files, 'write_document', save))
        reviewed = review_run.verify(False)
        check('full review retains all original process and group absence rows', len(reviewed['native_absence']) == 16 and len(reviewed['groups']) == 15)
        check('saved review rederives without repeating native queries', review_run.verify(True) == reviewed)
        reject('independent review output is one use', lambda: review_run.verify(False))
        altered = copy.deepcopy(reviewed)
        altered['native_absence'][0]['original_absent'] = False
        saved_outputs['independent-review.json'] = canonical(altered)
        reject('saved review cannot promote missing native absence', lambda: review_run.verify(True))

    # Full issuer/consumer models: the real local I/O implementation runs only
    # against the memory filesystem used by its separate bounded-I/O qualifier.
    world = World()
    for root in roots():
        for parent in reversed(PurePosixPath(root).parents):
            path = str(parent)
            if path != '.' and path not in world.nodes:
                world.add(path, stat.S_IFDIR | 0o700)
    state = active_state()
    current_inputs = json.loads(outputs['driver-inputs.json'])
    with ExitStack() as stack:
        world.activate(stack)
        stack.enter_context(patch.object(admission, 'ROOT', ModelPath(world)))
        stack.enter_context(patch.object(admission, 'current_state', lambda: copy.deepcopy(state)))
        stack.enter_context(patch.object(admission, 'authenticated_sources', lambda revision: (plan, expected)))
        model_reviews = []
        stack.enter_context(patch.object(admission, 'verify_models', lambda: model_reviews.append('source qualification verified')))
        original_loader = admission.load_document
        stack.enter_context(patch.object(admission, 'load_document', lambda path, *args: (plan, canonical(plan))
            if path.endswith('/plan.json') else original_loader(path, *args)))
        stack.enter_context(patch.object(installed_inputs, 'read_pin', lambda *args: None))
        stack.enter_context(patch.object(installed_inputs, 'native_reader', lambda: object()))
        stack.enter_context(patch.object(installed_inputs, 'resolve', lambda *args: copy.deepcopy(current_inputs)))
        stack.enter_context(patch.object(admission, 'output_members', lambda: {path.removeprefix(OUTPUT + '/')
            for path in world.nodes if path.startswith(OUTPUT + '/')}))
        with patch.object(admission, 'verify_models', side_effect=ValueError('model source proof missing')):
            reject('issuer rejects missing source qualification before allocation', admission.issue)
            check('missing source proof allocates no output', OUTPUT not in world.nodes)
        permit = admission.issue()
        check('issuer rederives source qualification before granting authority', model_reviews == ['source qualification verified'])
        check('issuer retains exactly the original frontier and input authority', {path for path in world.nodes if path.startswith(OUTPUT + '/')}
            == {OUTPUT + '/' + name for name in ('execution-admission.json', 'issuer-inputs.json', 'frontier-inputs.json')})
        consumed = admission.preflight('consume', object())
        check('consumer reauthenticates the exact one-use original state', consumed[1] == permit)
        reject('issuer cannot reuse its output', admission.issue, FileExistsError)
        state['memory'] += '\n'
        reject('consumer rejects changed live frontier bytes', lambda: admission.preflight('consume', object()))
        state['memory'] = active_state()['memory']
        current_inputs['inputs'][0]['inode'] += 1
        reject('consumer rejects changed installed identity after issue', lambda: admission.preflight('consume', object()))
        current_inputs['inputs'][0]['inode'] -= 1
        world.add(OUTPUT + '/run-start.json', stat.S_IFREG | 0o400, b'consumed')
        reject('consumer cannot reuse a consumed start state', lambda: admission.preflight('consume', object()))

    return dict(schema='fsmgen.inactive_populated_envelope_qualification.v1', checks=checks, rejecting_controls=rejected,
        joined_files=len(joined['files']), journal_rows=joined['journal_rows'], journal_bytes=joined['journal_bytes'],
        actual_worker_execution=False, actual_fixture_allocation=False, actual_signals=False, actual_permit_issued=False,
        scope='Whole-run admission and review in memory; no actual permit, native child or filesystem fixture.')


if __name__ == '__main__':
    print(json.dumps(qualify(), sort_keys=True, indent=2))
