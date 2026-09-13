"""Source-bound helpers for the final, saved-evidence-only release review."""
from collections import Counter
import copy
import hashlib
import importlib.util
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]


def load(path):
    return json.loads(path.read_bytes())


def module(path):
    spec = importlib.util.spec_from_file_location('final_' + hashlib.sha256(str(path).encode()).hexdigest(), path)
    value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value


def signature(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def rejects(action):
    try:
        action()
    except (AssertionError, KeyError, TypeError, ValueError, IndexError, StopIteration):
        return True
    return False


def subset(actual, expected):
    assert all(actual[key] == value for key, value in expected.items())


def match_domain(required, observed):
    assert len(required) == len(observed) == len(dict(observed))
    assert dict(observed) == required


def absent(roots):
    paths = [row['path'] for row in roots]
    assert len(paths) == len(set(paths))
    for relative in paths:
        assert relative.startswith('.artifacts/')
        assert all(part not in ('', '.', '..') for part in relative.split('/'))
        path = ROOT / relative
        assert not path.exists() and not path.is_symlink()
        while path != ROOT:
            assert not path.is_symlink()
            if path.exists():
                assert path.stat().st_dev == ROOT.stat().st_dev
            path = path.parent


def journal(directory, report, roots):
    assert report['allocated'] == roots
    assert [json.loads(line) for line in (directory / 'result/admission.jsonl').read_bytes().splitlines()] == roots


def copies(directory, prepare):
    records = load(directory / 'result/recovery-copies.json')
    if isinstance(records, dict):
        assert records['all_copies_byte_exact'] is True
        records = records['files']
    assert len(records) == len({record['destination'] for record in records})
    for record in records:
        destination = ROOT / record['destination']
        assert destination.is_relative_to(directory)
        pin = prepare.pin(destination)
        subset(pin, {key: record[key] for key in ('sha256', 'size_bytes')})
    return dict(copies=len(records), bytes=sum(record['size_bytes'] for record in records))


def physical(row, omission=False):
    """Count operation instances and keep implementation and observer closure apart."""
    op = row['operation']
    handles = op['handles']
    labels = [h['label'] for h in handles]
    assert len(labels) == len(set(labels))
    assert [event[7:] for event in op['events'] if event.startswith('opened:')] == labels
    counts = Counter(operations=1, handles=len(handles), calls=len(op.get('boundary_calls', [])),
                     events=len(op['events']), reads=len(op['reads']))
    for handle in handles:
        assert handle['kind'] in ('source', 'directory', 'lock')
        counts[handle['kind'] + '_handles'] += 1
        closed = handle['closed_at_return']
        assert type(closed) is int and closed in (0, 1)
        assert handle['actual_close_ok'] == handle['closed_after_call'] == closed
        assert omission or closed == 1
        counts['implementation_closed'] += closed
        counts['original_open'] += 1 - closed
    assert op['all_observed_handles_closed'] == int(counts['original_open'] == 0)
    reports = op.get('close_reports', [])
    reported_failures = [handle for handle in handles if handle['reported_return'] == 0]
    counts['reported_close_failures'] = len(reported_failures)
    if 'close_reports' in op:
        by_label = {handle['label']: handle for handle in handles}
        assert len(reports) == len({report['label'] for report in reports}) == len(handles)
        for report in reports:
            handle = by_label[report['label']]
            assert report['actual_return'] == report['closed_after_call'] == 1
            assert report['actual_errno'] == 0
            assert report['reported_return'] == handle['reported_return']
            assert report['reported_errno'] == handle['reported_errno']
            assert report['report_applied'] == int(handle['reported_return'] == 0)
        assert sum(report['report_applied'] for report in reports) == len(reported_failures)
    else:
        assert op['modeled_close_hits'] == len(reported_failures)
    result = op.get('result')
    if op['returned']:
        assert isinstance(result, dict) and op['error'] == ''
        success = bool(result['success'])
    else:
        assert result is None and op['error']
        assert row['selection']['expected_public_return'] is False
        assert not handles and not op['unlinks']
        success = False
    counts['public_successes'] = int(success)
    counts['public_rejections'] = int(bool(op['returned']) and not success)
    counts['pre_envelope_rejections'] = int(not op['returned'])
    counts['actual_unlinks'] = sum(item['actual_count'] for item in op['unlinks'])
    counts['post_unlink_rejections'] = int(bool(counts['actual_unlinks']) and not success)
    if omission:
        evidence = row['omission']
        counts['observer_recoveries'] = len(evidence['observer_recovery'])
        assert counts['observer_recoveries'] == counts['original_open']
        assert evidence['original_sha256_before_recovery'] == evidence['original_sha256_after_recovery']
        assert evidence['original_sha256_before_recovery'] == signature({key: value for key, value in op.items() if key not in ('before', 'after')})
    return counts


def falsify_lifetimes(witnesses):
    controls = []
    for kind in ('source', 'directory', 'lock'):
        row = copy.deepcopy(witnesses['healthy'])
        next(h for h in row['operation']['handles'] if h['kind'] == kind)['closed_at_return'] = 0
        assert rejects(lambda: physical(row))
        controls.append('unclosed-' + kind)
    row = copy.deepcopy(witnesses['omission'])
    row['omission']['observer_recovery'].clear()
    assert rejects(lambda: physical(row, True))
    controls.append('omission-without-separate-recovery')
    row = copy.deepcopy(witnesses['omission'])
    next(h for h in row['operation']['handles'] if h['closed_at_return'] == 0).update(
        actual_close_ok=1, closed_after_call=1, closed_at_return=1)
    row['operation']['all_observed_handles_closed'] = 1
    digest = signature({key: value for key, value in row['operation'].items() if key not in ('before', 'after')})
    row['omission'].update(original_sha256_before_recovery=digest, original_sha256_after_recovery=digest)
    assert rejects(lambda: physical(row, True))
    controls.append('recovery-counted-as-implementation-closure')
    return controls
