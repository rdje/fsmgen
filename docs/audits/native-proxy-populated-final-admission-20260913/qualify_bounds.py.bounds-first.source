"""Conservative fixed-shape byte bounds and controlled stop/deadline models."""
import json
from pathlib import PurePosixPath
import signal
from types import SimpleNamespace
from unittest.mock import patch

from build_plan import build
import admission
from contract import SCOPE, TASK, bounds, canonical, cases
import driver
import records
from qualify_envelope import whole_run

MAX_INTEGER = 9223372036854775807


def widen(value):
    """Upper-bound encodings, not semantically valid replacement acquisitions."""
    if isinstance(value, list):
        return [widen(item) for item in value]
    if not isinstance(value, dict):
        return value
    result = {}
    for key, item in value.items():
        if type(item) is int and key in ('pid', 'ppid', 'uid', 'ruid', 'start_sec', 'device', 'inode', 'descriptor', 'busy_count', 'elapsed_ns', 'size_bytes'):
            result[key] = MAX_INTEGER
        elif key == 'start_usec' and type(item) is int:
            result[key] = 999999
        elif key == 'sequence' and type(item) is int:
            result[key] = bounds()['journal_events'] - 1
        else:
            result[key] = widen(item)
    if 'bytes_hex' in value and 'identity' in value:
        body = records.octets(value['bytes_hex'])
        if body.startswith(b'{'):
            body = canonical(widen(json.loads(body)))
        result['bytes_hex'] = body.hex()
        result['identity'].update(records.file_pin(body))
    return result


def derived():
    plan = build()
    outputs, unused = whole_run(plan)
    rows = [json.loads(line) for line in outputs['journal.jsonl'].splitlines()]
    worker_sizes, event_sizes, event_counts = [], [], []
    activation_sizes, handoff_sizes = [], []
    snapshots = []
    for name, body in outputs.items():
        if name.endswith('.stdout'):
            events = [json.loads(line) for line in body.splitlines()]
            expanded = [len(canonical(widen(event))) + 1 for event in events]
            worker_sizes.append(sum(expanded))
            event_sizes.extend(expanded)
            event_counts.append(len(events))
        elif name.startswith('activation.'):
            activation_sizes.append(len(canonical(widen(json.loads(body)))))
        elif name.startswith('handoff.'):
            handoff_sizes.append(len(canonical(widen(json.loads(body)))))
    snapshots = [widen(row['snapshot']) for row in rows if row['event'] in ('case_snapshot', 'cleanup_snapshot')]
    case_roots = {case['name']: [case['store'], *case['workspaces'].values()] + ([case['evidence']] if case['evidence'] else []) for case in cases()}
    depths = []
    for row in rows:
        if row['event'] != 'case_snapshot':
            continue
        for path in row['snapshot']['nodes']:
            root = next(root for root in case_roots[row['case']] if path == root or path.startswith(root + '/'))
            depths.append(len(PurePosixPath(path).parts) - len(PurePosixPath(root).parts))
    files = [node for snapshot in snapshots for node in snapshot['nodes'].values() if node['kind'] == 'file']
    # A source-failure outcome may request KILL after TERM. Its extra request is
    # counted separately; the accepted fixed schedules otherwise have exact rows.
    extra_signal_rows = bounds()['held_cancellations']
    signal_row = max(len(canonical(widen(row))) + 1 for row in rows if row['event'] == 'controller_child_signal')
    # This dated size observation must not depend on the live pointer changing
    # after a slice completes. The issuer separately bounds the exact new
    # encoded frontier before allocating an output directory.
    source_frontier = dict(schema='fsmgen.inactive_populated_execution_frontier.v1', admission_commit='a' * 40,
        execution_owner=plan['execution_owner'], task=admission.git('show', SCOPE['source_revision'] + ':' + TASK).decode(),
        memory=admission.git('show', SCOPE['source_revision'] + ':MEMORY.md').decode())
    return dict(largest_worker_event=max(event_sizes), largest_worker_output=max(worker_sizes), largest_worker_event_count=max(event_counts),
        largest_activation=max(activation_sizes), largest_handoff=max(handoff_sizes),
        worker_authority=len(canonical(widen(json.loads(outputs['worker-authority.json'])))),
        start_marker=len(canonical(widen(json.loads(outputs['run-start.json'])))),
        largest_owned_tree=max(len(snapshot['nodes']) for snapshot in snapshots), largest_owned_depth=max(depths),
        largest_owned_file=max(len(records.octets(node['bytes_hex'])) for node in files),
        largest_owned_file_total=max(sum(len(records.octets(node['bytes_hex'])) for node in snapshot['nodes'].values() if node['kind'] == 'file') for snapshot in snapshots),
        journal_rows=len(rows) + extra_signal_rows,
        journal_bytes=sum(len(canonical(widen(row))) + 1 for row in rows) + extra_signal_rows * signal_row,
        source_epoch_frontier_bytes=len(canonical(source_frontier)), source_epoch=SCOPE['source_revision'],
        run_files=len(plan['expected_run_files']), reviewed_files=len(plan['expected_reviewed_files']),
        scope='Conservative maximum-width encodings of fixed successful model shapes. These widened records are not valid native acquisitions. Failure outputs remain separately bounded by the controller, journal and local I/O ceilings.')


def validate(value, limits):
    pairs = {'largest_worker_event': 'worker_event_bytes', 'largest_worker_output': 'worker_output_bytes',
        'largest_worker_event_count': 'worker_events', 'largest_activation': 'activation_bytes', 'largest_handoff': 'handoff_bytes',
        'largest_owned_tree': 'owned_tree_nodes', 'largest_owned_depth': 'owned_tree_depth', 'largest_owned_file': 'owned_file_bytes',
        'largest_owned_file_total': 'owned_tree_bytes', 'journal_rows': 'journal_events', 'journal_bytes': 'journal_bytes'}
    for measured, limit in pairs.items():
        if value[measured] > limits[limit]:
            raise ValueError('declared bound is insufficient: ' + limit)
    if value['worker_authority'] > 65536 or value['start_marker'] > 4096 or value['source_epoch_frontier_bytes'] > 4 * 1024 * 1024:
        raise ValueError('declared execution document bound is insufficient')
    if limits['largest_command_bytes'] > limits['command_bytes']:
        raise ValueError('declared command bound is insufficient')
    return pairs


def qualify():
    checks, rejected = [], []
    measured, limits = derived(), bounds()
    pairs = validate(measured, limits)
    for measured_name, limit in pairs.items():
        changed = dict(limits)
        changed[limit] = measured[measured_name] - 1
        try:
            validate(measured, changed)
        except ValueError:
            rejected.append('insufficient ' + limit)
        else:
            raise AssertionError('insufficient bound accepted: ' + limit)
    checks.append('every fixed maximum-width shape fits its declared ceiling')
    before = {signal.SIGINT: 'prior interrupt handler', signal.SIGTERM: 'prior termination handler'}
    handlers, registered = dict(before), []
    def set_handler(number, handler):
        registered.append(number)
        prior, handlers[number] = handlers[number], handler
        return prior
    with patch.object(driver.signal, 'signal', set_handler):
        with driver.StopSignals() as stop:
            stop.receive(signal.SIGTERM, None)
            stop.receive(signal.SIGINT, None)
            try:
                stop.check()
            except driver.StopRequested:
                if stop.requested != [signal.SIGTERM]:
                    raise AssertionError('first stop signal was replaced')
                checks.append('signals defer exceptions until a controlled ownership boundary')
            else:
                raise AssertionError('stop request was ignored')
    if handlers != before or signal.SIGCHLD in registered:
        raise AssertionError('stop handling changed exclusive SIGCHLD ownership or lost previous handlers')
    checks.append('stop handlers restore both original dispositions and preserve SIGCHLD')
    runner = driver.CaseDriver(cases()[0], {}, 'a' * 40, object(), lambda *args, **kwargs: None,
        SimpleNamespace(check=lambda: None), 10, fixture_factory=lambda *args: object(), now=lambda: 10)
    try:
        runner.check_time()
    except TimeoutError:
        if runner.workers:
            raise AssertionError('expired deadline created a worker')
        checks.append('expired work deadline rejects before any worker allocation')
    else:
        raise AssertionError('expired work deadline was ignored')
    return dict(schema='fsmgen.inactive_populated_bounds_qualification.v1', derived=measured,
        declared=limits, checks=checks, rejecting_controls=rejected, actual_worker_execution=False,
        actual_fixture_allocation=False, actual_signals=False, source_geometry_is_not_native_execution_evidence=True)


if __name__ == '__main__':
    print(json.dumps(qualify(), sort_keys=True, indent=2))
