"""Join declared selector domains without conflating matrix-local case IDs."""
from __future__ import annotations

from collections import Counter


def case_name(row):
    if isinstance(row, str):
        return row
    return row['id'] if 'id' in row else row['name']


def categories(plan):
    pairs = [('cases', 'cases')]
    if 'late_cases' in plan:
        pairs.append(('late_cases', 'late_changes'))
    pairs.append(('mutants', 'mutants'))
    return pairs


def exact_records(plan, result):
    names = []
    for planned, recorded in categories(plan):
        expected = [case_name(row) for row in plan[planned]]
        actual = [case_name(row) for row in result[recorded]]
        assert expected == actual, ('missing, extra or reordered cases', recorded)
        names.extend(expected)
    assert len(names) == len(set(names)), 'aliased case ID within matrix'
    return names


def unique_events(flow):
    events = [row if isinstance(row, str) else row['event'] for row in flow]
    assert len(events) == len(set(events)), 'aliased event occurrence'
    return events


def all_cuts(rows, events):
    expected = Counter([None]+events)
    assert Counter(row['cut'] for row in rows) == expected, 'incomplete or repeated selector'


def semantic_label(event):
    # Derive the resource ownership domain from the read operations themselves.
    if not event.endswith(':read'):
        return None
    parts = event.split(':')
    if parts[0] == 'reference':
        assert parts[1] in ('initial', 'closure') and parts[2].isdigit()
        return ('original:' if parts[1] == 'initial' else 'fresh:')+parts[2]
    assert parts[0] == 'image' and parts[3] == 'input'
    return ':'.join(parts[:3]+[parts[4]])


def remaining_label(event):
    parts = event.split(':')
    if event == 'coordinator:lock:open':
        return 'lock'
    if parts[0] == 'census' and len(parts) == 4 and parts[2] == 'source':
        return ':'.join(parts[:2]+parts[3:])
    if parts[:2] == ['admit', 'read']:
        return 'target:'+parts[-1]
    if len(parts) == 4 and parts[1:3] == ['sources', 'read']:
        return 'fresh:'+parts[0]+':'+parts[-1]
    if event == 'finish:hold:read':
        return 'hold'
    return None


def close_sites(rows, events, labeler):
    labels = [labeler(event) for event in events]
    labels = [label for label in labels if label is not None]
    assert len(labels) == len(set(labels)), 'aliased close ownership'
    singles = [next(iter(row['reports'])) for row in rows
               if row['cut'] is None and len(row['reports']) == 1]
    assert Counter(singles) == Counter(labels), 'missing or repeated pure close-report site'
    return sorted(labels)


def coverage(kind, plan):
    result = {}
    if kind in ('snapshot', 'coordinator', 'remaining_close'):
        flows = plan['traces'] if kind == 'snapshot' else plan['flows']
        assert set(flows) == {'fresh', 'reuse'}
        for route, flow in flows.items():
            events = unique_events(flow)
            rows = [row for row in plan['cases'] if row['route'] == route]
            if kind == 'remaining_close':
                result[route] = dict(single_close_sites=close_sites(rows, events, remaining_label))
            else:
                all_cuts(rows, events)
                result[route] = dict(cut_selectors=len(events), healthy_routes=1)
    elif kind in ('semantic_calls', 'semantic_close'):
        assert set(plan['flows']) == {'fresh', 'reuse'}
        for route, phases in plan['flows'].items():
            assert set(phases) == {'pre', 'post'}
            for phase, bindings in phases.items():
                assert bindings
                rows = [row for row in plan['cases']
                        if row['route'] == route and row['phase'] == phase]
                common_events = None
                common_sites = None
                for flow in bindings.values():
                    events = unique_events(flow)
                    if common_events is not None:
                        assert set(events) == common_events
                    common_events = set(events)
                    if kind == 'semantic_calls':
                        all_cuts(rows, events)
                    else:
                        sites = close_sites(rows, events, semantic_label)
                        if common_sites is not None:
                            assert sites == common_sites
                        common_sites = sites
                result[route+':'+phase] = (dict(cut_selectors=len(common_events), healthy_routes=1)
                    if kind == 'semantic_calls' else dict(single_close_sites=common_sites))
        result['ordering_limit'] = 'Each case has its independently checked recorded order; no selector-by-order Cartesian-product claim.'
    else:
        assert kind in ('publication', 'directory', 'handoff', 'fresh', 'reuse')
        result['scope'] = 'Exact declared cases, late changes and mutants; no every-call or every-syscall claim.'
    return result
