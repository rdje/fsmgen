"""Independent original-row accounting and adversarial checks for the final join."""
from __future__ import annotations

from collections import Counter
import copy
import json
import re

import evidence as E
import replay

TRACED = {'boundaries', 'ordinary-fresh', 'ordinary-existing', 'equal-fresh',
          'equal-existing', 'partial-writes', 'close-reports', 'omitted-closes',
          'namespace', 'replacements'}


def operations(report):
    for case in report['cases']:
        if 'preparation' in case:
            yield case, case['preparation'], False
        yield case, case['operation'], True


def assertions(raw):
    """Parse the original sequential TAP without using the join's parser."""
    lines = raw.decode().splitlines()
    plans = [line for line in lines if line.startswith('1..')]
    assert len(plans) == 1 and re.fullmatch(r'1\.\.[0-9]+', plans[0])
    successful = [line for line in lines if line.startswith('ok ')]
    assert len(successful) == int(plans[0][3:])
    for ordinal, line in enumerate(successful, 1):
        assert line.startswith('ok ' + str(ordinal) + ' - ')
    assert not any(re.search(r'^(not ok|Bail out!)|#\s*(skip|todo)\b', line, re.I) for line in lines)
    return len(successful)


def raw_counts(reports):
    """Count actual subject-handle instances; recovery never heals their verdict."""
    totals = Counter({key: 0 for key in [
        'traced_operations', 'traced_events', 'source_handles', 'writer_handles',
        'directory_handles', 'traced_handles', 'archive_operations',
        'legacy_source_observations', 'omitted_closes', 'implementation_closes',
        'counterimplementation_returns', 'closure_rejections', 'modeled_close_errors',
        'actual_partial_write_calls', 'actual_partial_written_bytes']})
    for name in sorted(TRACED):
        for case, operation, subject in operations(reports[name]):
            totals['traced_operations'] += 1
            events = operation['events']; assert len(events) == len(set(events))
            totals['traced_events'] += len(events)
            handles = operation['handles']
            assert [row['label'] for row in handles] == [event[7:] for event in events if event.startswith('opened:')]
            selected = case['selection']['omissions'] if name == 'omitted-closes' and subject else []
            assert operation['all_observed_handles_closed'] == int(not selected)
            if selected:
                totals['closure_rejections'] += 1
                totals['counterimplementation_returns'] += operation['returned']
            by_label = {row['label']: row for row in handles}
            assert len(by_label) == len(handles) and set(selected) <= by_label.keys()
            for handle in handles:
                kind = handle['kind']; assert kind in ('source', 'writer', 'directory')
                assert handle['label'].startswith('directory_handle:' if kind == 'directory' else kind + ':')
                totals[kind + '_handles'] += 1; totals['traced_handles'] += 1
                omitted = handle['label'] in selected
                assert handle['actual_close_ok'] == handle['closed_after_call'] == handle['closed_at_return'] == int(not omitted)
                assert handle['actual_errno'] == 0
                if omitted:
                    assert handle['actual_close_performed'] == handle['reported_errno'] == 0
                    assert handle['reported_return'] == 1
                    totals['omitted_closes'] += 1
                else:
                    assert 'actual_close_performed' not in handle
                    totals['implementation_closes'] += 1
                if kind == 'directory':
                    assert handle['observer_closed'] == 1 and handle['observer_descriptor'] != handle['descriptor']
            if name == 'omitted-closes' and subject:
                recovery = operation['observer_recovery']; witnesses = operation['open_witnesses']
                assert set(operation['omission_hits']) == set(selected)
                assert [row['label'] for row in recovery] == [row['label'] for row in witnesses] == operation['omission_hits']
                assert operation['recovery_complete'] == 1 and operation['observer_errors'] == []
                for recovered, witness in zip(recovery, witnesses, strict=True):
                    handle = by_label[recovered['label']]
                    assert recovered['descriptor_before'] == handle['descriptor'] == witness['descriptor']
                    assert witness['open_at_return'] == 1
                    assert recovered['performed'] == recovered['actual_return'] == recovered['closed_after'] == 1
                    assert recovered['actual_errno'] == 0
            for row in operation.get('close_reports', []):
                assert row['actual_return'] == row['closed_after_call'] == 1 and row['actual_errno'] == 0
                if row['report_applied']:
                    assert row['report_applied'] == 1 and row['reported_return'] == 0
                    assert row['reported_errno'] > 0
                    totals['modeled_close_errors'] += 1
                else:
                    assert row['reported_return'] == 1 and row['reported_errno'] == 0
            for row in operation.get('syswrites', []):
                if row['syscall_performed']:
                    assert row['syscall_performed'] == 1 and type(row['actual_return']) is int
                    assert 0 < row['actual_return'] <= row['actual_requested']
                    assert len(bytes.fromhex(row['accepted_hex'])) == row['actual_return']
                    assert row['actual_errno'] == row['reported_errno'] == 0
                    assert row['reported_return'] == row['actual_return']
                    totals['actual_partial_write_calls'] += 1
                    totals['actual_partial_written_bytes'] += row['actual_return']
                else:
                    assert row['actual_return'] is None and row['actual_requested'] == 0 and row['accepted_hex'] == ''
    totals['archive_operations'] = totals['traced_operations']
    for _, operation, _ in operations(reports['files']):
        totals['archive_operations'] += 1
        for descriptor in operation['descriptors']:
            assert descriptor['closed'] == descriptor['cloexec'] == 1
            totals['legacy_source_observations'] += 1
    return dict(totals)


def absent(rows):
    paths = [row['path'] for row in rows]; assert len(set(paths)) == len(paths)
    for name in paths:
        assert name.startswith('.artifacts/') and all(part not in ('', '.', '..') for part in name.split('/'))
        path = E.ROOT / name
        assert not path.exists() and not path.is_symlink()
        for parent in path.parents:
            if parent == E.ROOT: break
            assert not parent.is_symlink()
            if parent.exists(): assert parent.stat().st_dev == E.ROOT.stat().st_dev


def reference(plan, declared, inventory, sources):
    domains = {row['name']: row for row in declared['domains']}
    reports = {}; counts = {}; taps = {}; roots = []
    for name in plan['domain_order']:
        base = domains[name]['source']; report = E.document(base + '/result/qualification.json')
        saved = E.document(base + '/result/audit.json'); assert report['success'] is saved['success'] is True
        reports[name] = report; counts[name] = dict(saved)
        if name == 'boundaries':
            for kind in ('source', 'writer', 'directory'):
                counts[name][kind + '_handles'] = sum(handle['kind'] == kind for case in report['cases'] for handle in case['operation']['handles'])
        taps[name] = assertions(E.read(base + '/result/qualify.tap')[0])
        assert taps[name] == saved['tap_assertions'] and E.read(base + '/result/qualify.exit')[0] == b'0\n'
        if 'allocated' in report:
            allocated = [json.loads(line) for line in E.read(base + '/result/admission.jsonl')[0].splitlines()]
            assert allocated == report['allocated']
            roots.extend(dict(domain=name, **row) for row in allocated)
    strict = {}; support = []
    for phase in ['baseline', 'qualification']:
        base = domains['strict-handoff']['source']; value = E.document(base + '/result/' + phase + '.json')
        strict[phase] = dict(cases=len(value['cases']), mutants=len(value['mutants']),
                             assertions=assertions(E.read(base + '/result/' + phase + '.tap')[0]))
        support.extend(dict(domain='strict-handoff', **row) for row in value['allocated'])
    failed_sources = [row for row in value['cases'] if row['operation'] == 'source' and not row['returned']]
    for row in failed_sources:
        assert row['handles'][0]['closed_before_recovery'] == 1 and row['handles'][0]['recovery_close_ok'] is None
    close = E.document(domains['close-join']['source'] + '/result/audit.json')
    lower = E.document(domains['reader-join']['source'] + '/result/audit.json')
    expected = dict(schema='fsmgen.inactive_archive_final_join.v1', success=True, source_revision=E.REVISION,
                    source_files=len(sources), source_bytes=sum(row['size_bytes'] for row in sources), source_inputs=sources,
                    original_inventory_files=len(inventory['inputs']), source_epoch_comparisons=len(inventory['source_epochs']),
                    current_prospective_pins=len(E.own_pins()), primary_tap_assertions=taps,
                    archive_summary=raw_counts(reports), reachability=counts['guards']['reachability'],
                    strict_handoff=dict(counts=strict, failed_source_closures=len(failed_sources)),
                    prior_joins=dict(close_counts=close['counts'], close_coverage=close['coverage'],
                                     source_entry_counts=lower['selected_archive_counts'], source_entry_selections=lower['selections'],
                                     strict_rejection_observation=lower['original_strict_rejections']),
                    replay=replay.verify(E.document(replay.BASE + '/plan.json'), E.document(replay.BASE + '/result/qualification.json'),
                                         inventory, E.document(str((E.BASE / 'replay-preservation-scope.json').relative_to(E.ROOT)))),
                    primary_allocations=roots, strict_support_allocations=support,
                    all_original_case_roots_absent=True, semantic_archive_join_complete=True, limits=plan['limits'])
    absent(roots + support)
    return expected, reports, counts


def verify(observed, expected, counts):
    assert set(observed) == set(expected) | {'domains'}
    assert {key: value for key, value in observed.items() if key != 'domains'} == expected
    assert set(observed['domains']) == set(counts)
    for name, values in observed['domains'].items():
        assert values and all(counts[name][key] == value for key, value in values.items())
        if name == 'boundaries':
            assert sum(values[kind + '_handles'] for kind in ('source', 'writer', 'directory')) == counts[name]['handles']


def reject(label, action, results):
    try:
        action()
    except (AssertionError, KeyError, ValueError, TypeError):
        results.append(dict(name=label, rejected=True))
    else:
        raise AssertionError('falsifier accepted: ' + label)


def main():
    pins = E.own_pins(); plan = E.document(str((E.BASE / 'plan.json').relative_to(E.ROOT)))
    declared, inventory, sources = E.authenticate(plan)
    observed = json.loads((E.LOG / 'join.json').read_bytes())
    with E.saved_only():
        expected, reports, counts = reference(plan, declared, inventory, sources)
        verify(observed, expected, counts)
        falsifiers = []
        for key in expected['archive_summary']:
            altered = copy.deepcopy(observed); altered['archive_summary'][key] += 1
            reject('altered aggregate ' + key, lambda: verify(altered, expected, counts), falsifiers)
        for key in ['source_inputs', 'primary_allocations', 'strict_support_allocations']:
            altered = copy.deepcopy(observed); altered[key].pop()
            reject('missing ' + key, lambda: verify(altered, expected, counts), falsifiers)
        for key in ['prior_joins', 'replay', 'domains', 'primary_tap_assertions']:
            altered = copy.deepcopy(observed); altered[key].pop(next(iter(altered[key])))
            reject('missing ' + key, lambda: verify(altered, expected, counts), falsifiers)
        altered = copy.deepcopy(observed); altered['semantic_archive_join_complete'] = False
        reject('false completion', lambda: verify(altered, expected, counts), falsifiers)
        omission = next(row for row in reports['omitted-closes']['cases'] if row['selection']['omissions'])
        def changed_operation(name, original, change):
            replacement = copy.deepcopy(original); change(replacement)
            altered_reports = dict(reports)
            altered_reports[name] = dict(reports[name], cases=[replacement if row is original else row for row in reports[name]['cases']])
            raw_counts(altered_reports)
        for label, change in [
            ('recovery heals original verdict', lambda row: row['operation'].update(all_observed_handles_closed=1)),
            ('omitted close becomes actual close', lambda row: next(h for h in row['operation']['handles'] if h['label'] in row['selection']['omissions']).update(actual_close_ok=1)),
            ('missing observer recovery', lambda row: row['operation']['observer_recovery'].pop()),
            ('observer recovery failed', lambda row: row['operation']['observer_recovery'][0].update(actual_return=0))]:
            reject(label, lambda: changed_operation('omitted-closes', omission, change), falsifiers)
        original = reports['boundaries']['cases'][0]
        reject('missing subject handle', lambda: changed_operation('boundaries', original, lambda row: row['operation']['handles'].pop()), falsifiers)
        reject('writer mislabeled as source', lambda: changed_operation('boundaries', original,
               lambda row: next(h for h in row['operation']['handles'] if h['kind'] == 'writer').update(kind='source')), falsifiers)
        partial = next(row for row in reports['partial-writes']['cases'] if any(not call['syscall_performed'] for call in row['operation']['syswrites']))
        reject('modeled write counted as syscall', lambda: changed_operation('partial-writes', partial,
               lambda row: next(call for call in row['operation']['syswrites'] if not call['syscall_performed']).update(syscall_performed=1)), falsifiers)
        replay_plan = E.document(replay.BASE + '/plan.json'); replay_report = E.document(replay.BASE + '/result/qualification.json')
        scope = E.document(str((E.BASE / 'replay-preservation-scope.json').relative_to(E.ROOT)))
        altered = copy.deepcopy(scope); altered['census_only_files'].pop()
        reject('auxiliary preservation boundary erased', lambda: replay.verify(replay_plan, replay_report, inventory, altered), falsifiers)
        recovery = E.document(replay.BASE + '/result/recovery-copies.json'); recovery['reconstructed_seeds'][0]['sha256'] = '0' * 64
        reject('altered saved replay seed', lambda: replay.verify(replay_plan, replay_report, inventory, scope, recovery=recovery), falsifiers)
    assert E.authenticate(plan)[2] == sources
    E.own_pins()
    result = dict(schema='fsmgen.inactive_archive_final_join_audit.v1', success=True,
                  independently_walked_summary=expected['archive_summary'], primary_tap_assertions=sum(expected['primary_tap_assertions'].values()),
                  primary_roots=len(expected['primary_allocations']), strict_support_roots=len(expected['strict_support_allocations']),
                  source_files=len(sources), source_bytes=expected['source_bytes'], current_prospective_pins=len(pins),
                  falsifiers=falsifiers, replay=expected['replay'], all_original_case_roots_absent=True,
                  semantic_archive_join_complete=True, limits=plan['limits'])
    with (E.LOG / 'audit.json').open('x') as stream:
        stream.write(json.dumps(result, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(success=True, falsifiers=len(falsifiers), archive_summary=expected['archive_summary'],
                         primary_roots=result['primary_roots'], strict_support_roots=result['strict_support_roots']), sort_keys=True))


if __name__ == '__main__':
    main()
