"""Qualify the separate phase diagnostic and bounded complete-input counterfactual."""
import argparse
import copy
import gzip
import hashlib
import json
import re

import bounded_runtime_inventory as bounded
import capture_runtime_profile as profile
import execute
import prepare
import qualify_bounded_inventory as repaired
import qualify_runtime_inventory as first
import verify_runtime_inventory_failed as failure

PATH = execute.AUDIT / 'runtime-inventory-memory-qualified.json.gz'


def load(name):
    return json.loads(gzip.decompress(execute.read(execute.AUDIT / name)))


def custody(row, started, names):
    assert all(row[key] == value for key, value in started.items())
    assert set(started) == {'command', 'sources', 'tools', 'primary', 'scope'}
    assert set(row) == set(started) | {'status', 'stdout', 'stderr', 'sources_after', 'tools_after', 'primary_after'}
    assert set(row['sources']) == set(names)
    for name, value in row['sources'].items():
        assert prepare.unblob(value) == execute.read(execute.AUDIT / name)
    assert row['sources_after'] == dict(value=started['sources'], error=None)
    assert row['tools_after'] == dict(value=started['tools'], error=None)
    assert row['primary_after']['error'] is None
    assert all(row['primary_after']['value'][key] == row['primary'][key] for key in ('head', 'entries'))
    for state in (row['primary'], row['primary_after']['value']):
        assert re.fullmatch('[0-9a-f]{40}', state['head'])
        prepare.unblob(state['entries'])
        prepare.unblob(state['index'])
    stderr = prepare.unblob(row['stderr'])
    assert re.match(rb'ram-guard: PID [0-9]+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', stderr)


def phases(row):
    assert type(row['status']) is int and row['status'] == 137
    assert b'RSS ' in prepare.unblob(row['stderr']) and b'reached cutoff 4096 MiB:' in prepare.unblob(row['stderr'])
    assert b'ram-guard: terminating PID tree:' in prepare.unblob(row['stderr'])
    events = [json.loads(line) for line in prepare.unblob(row['stdout']).splitlines()]
    for index, event in enumerate(events):
        assert set(event) == {'phase', 'event', 'member', 'monotonic_ns', 'self_maxrss_bytes'}
        assert event['phase'] in ('build', 'selection', 'python_sites', 'validate', 'controls', 'encoded')
        assert event['event'] in ('enter', 'return')
        assert type(event['monotonic_ns']) is int and type(event['self_maxrss_bytes']) is int
        assert event['self_maxrss_bytes'] > 0
        assert (type(event['member']) is str) == (event['phase'] == 'python_sites')
        if index:
            assert event['monotonic_ns'] >= events[index - 1]['monotonic_ns']
            assert event['self_maxrss_bytes'] >= events[index - 1]['self_maxrss_bytes']
    # The original positive build and comparison completed; refusal is later.
    assert (events[0]['phase'], events[0]['event']) == ('build', 'enter')
    build_end = next(i for i, event in enumerate(events) if (event['phase'], event['event']) == ('build', 'return'))
    control_start = next(i for i, event in enumerate(events) if (event['phase'], event['event']) == ('controls', 'enter'))
    assert build_end < control_start and any(event['phase'] == 'validate' and event['event'] == 'return' for event in events[build_end:control_start])
    assert (events[-1]['phase'], events[-1]['event']) == ('encoded', 'enter')
    assert not any(event['phase'] == 'controls' and event['event'] == 'return' for event in events)
    return events


def positive(row):
    assert type(row['status']) is int and row['status'] == 0
    assert prepare.unblob(row['stdout']) == b'Complete unchanged fixed-source census and bounded strict corruption controls pass; runtime roles remain unresolved.\n'
    assert b'ram-guard: terminating PID tree' not in prepare.unblob(row['stderr'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    old, old_start = load('runtime-inventory-first-actual.json.gz'), load('runtime-inventory-first-started.json.gz')
    assert failure.failed(old, old_start)
    diagnostic, diagnostic_start = load('runtime-inventory-profile-actual.json.gz'), load('runtime-inventory-profile-started.json.gz')
    result, result_start = load('runtime-inventory-bounded-first-actual.json.gz'), load('runtime-inventory-bounded-first-started.json.gz')
    custody(diagnostic, diagnostic_start, profile.NAMES)
    custody(result, result_start, repaired.NAMES)
    for name in first.NAMES:
        assert old['sources'][name] == diagnostic['sources'][name] == result['sources'][name]
    assert diagnostic['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(execute.AUDIT / 'profile_runtime_inventory.py')]
    assert result['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(execute.AUDIT / 'bounded_runtime_inventory.py'), '--write']
    events = phases(diagnostic)
    positive(result)
    value = load('runtime-source-inventory-bounded.json.gz')
    controls = load('runtime-source-inventory-bounded-controls.json.gz')
    raw, members = bounded.original.epoch.tree(bounded.original.epoch.REVISION)
    assert prepare.unblob(value['full_tree']) == raw and value['members'] == members
    names = bounded.original.code_members(members)
    assert set(value['records']) == set(names)
    for name, record in value['records'].items():
        body = prepare.unblob(record['source'])
        assert record['mode'] == members[name]['mode'] and len(body) == members[name]['bytes']
        assert hashlib.sha1(b'blob ' + str(len(body)).encode() + b'\0' + body).hexdigest() == members[name]['oid']
    wanted_python = sorted(name for name, record in value['records'].items() if record['language'] == 'python')
    for event in ('enter', 'return'):
        assert sorted(row['member'] for row in events if row['phase'] == 'python_sites' and row['event'] == event) == wanted_python
    assert controls['canonical_inventory'] == bounded.identity(value)
    assert controls['outcomes'] == bounded.controls(value)
    assert prepare.unblob(controls['programme']) == execute.read(execute.AUDIT / 'bounded_runtime_inventory.py')
    assert list(controls['phases']) == sorted(controls['phases'])  # canonical recorded keys
    assert all(type(size) is int and 0 < size < 4096 * 1024 ** 2 for size in controls['phases'].values())
    assert value['runtime_permission'] is False and value['reachability_qualified'] is False
    outcomes = []
    for label in ('promoted_profile', 'profile_kind', 'lost_build', 'lost_control', 'borrowed_success', 'positive_kind'):
        bad = copy.deepcopy(diagnostic if label not in ('borrowed_success', 'positive_kind') else result)
        if label == 'promoted_profile': bad['status'] = 0
        elif label == 'profile_kind': bad['status'] = 137.0
        elif label in ('lost_build', 'lost_control'):
            kept = [event for event in events if event['phase'] != ('build' if label == 'lost_build' else 'controls')]
            bad['stdout'] = prepare.blob(b''.join(prepare.encoded(event) for event in kept))
        elif label == 'borrowed_success': bad['stdout'] = diagnostic['stdout']
        else: bad['status'] = False
        try:
            (positive if label in ('borrowed_success', 'positive_kind') else phases)(bad)
        except (AssertionError, StopIteration):
            outcomes.append(label)
        else:
            raise AssertionError('invalid phase/native qualification admitted: ' + label)
    if args.write:
        inputs = ('runtime-inventory-profile-started.json.gz', 'runtime-inventory-profile-actual.json.gz',
                  'runtime-inventory-bounded-first-started.json.gz', 'runtime-inventory-bounded-first-actual.json.gz',
                  'runtime-source-inventory-bounded.json.gz', 'runtime-source-inventory-bounded-controls.json.gz')
        execute.save(PATH, dict(inputs={name: prepare.identity(execute.read(execute.AUDIT / name)) for name in inputs},
                                programme=prepare.blob(execute.read(execute.AUDIT / 'verify_inventory_memory.py')),
                                outcomes=outcomes, inventory=controls['canonical_inventory'],
                                scope='Complete fixed input/source custody, separate diagnostic phase and bounded counterfactual only. '
                                      'Original first-process allocation phase stays unobserved. No individual change is proved '
                                      'necessary/sufficient, no allocator cause or live/unsampled peak is inferred, '
                                      'and execution/data/expanded-dynamic-code roles remain open.'))
    print('Separate diagnostic control/encoding refusal and bounded complete-source native0 qualify; original-process attribution and runtime roles remain open.')
