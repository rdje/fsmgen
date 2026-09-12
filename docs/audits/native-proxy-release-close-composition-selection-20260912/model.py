"""Select finite competing-error recipes from the current healthy event flow.

Baseline addresses are witnesses. Execution must apply the recipe again to its
own prospective input flow; archived labels and numeric calls are not targets.
"""
from collections import Counter

RELEASE = 'NativeProxyObservationRelease'
COORD = 'NativeProxyImageCoordination'
CUSTODY = 'NativeProxyImageCustody'
ARCHIVE = 'NativeProxyObservationArchive'
CENSUS = 'NativeProxyReferenceCensus'
SOURCE_SCOPES = (
    RELEASE + '::_close_owned', ARCHIVE + '::_source_closure',
    COORD + '::_census', CENSUS + '::_closure', CENSUS + '::_image',
    CENSUS + '::_inspect_locked', CUSTODY + '::read_entry',
)
DIRECTORY_SCOPES = (COORD + '::_names', CUSTODY + '::_members')
SCOPES = (*SOURCE_SCOPES, *DIRECTORY_SCOPES, COORD + '::_transaction')
ERRORS = {
    RELEASE + '::_close_owned': 'cannot close retained release descriptor',
    ARCHIVE + '::_source_closure': 'cannot close archive reread descriptor',
    COORD + '::_census': 'cannot close census reference',
    CENSUS + '::_closure': 'cannot close fresh reference',
    CENSUS + '::_image': 'cannot close image input',
    CENSUS + '::_inspect_locked': 'cannot close reference',
    CUSTODY + '::read_entry': 'cannot close image descriptor',
    COORD + '::_names': 'cannot close bounded namespace',
    CUSTODY + '::_members': 'cannot close image directory',
    COORD + '::_transaction': 'cannot close permanent lock',
}


def recipes():
    result = [dict(kind='healthy', scope=None, order='none')]
    targets = [('group', scope) for scope in sorted(SCOPES)]
    targets += [('source-primary', scope) for scope in sorted(SOURCE_SCOPES)]
    targets += [('directory-primary', scope) for scope in sorted(DIRECTORY_SCOPES)]
    targets += [('milestone-primary', scope) for scope in
                ('before-unlink', 'after-unlink-unknown', 'final-lock-identity')]
    for kind, scope in targets:
        for order in ('observed', 'reversed'):
            result.append(dict(kind=kind, scope=scope, order=order))
    return result


def resolve(calls, healthy, bindings, recipe):
    assert recipe in recipes()
    events = healthy['events']; by_label = {b['label']: b for b in bindings}
    assert len(by_label) == len(bindings)
    active = set(); open_sets = []
    for event in events:
        if event.startswith('opened:'):
            label = event[len('opened:'):]; assert label not in active
            active.add(label)
        elif event.startswith('close:') and event.endswith(':after'):
            label = event[len('close:'):-len(':after')]; active.remove(label)
        open_sets.append(set(active))
    assert not active
    closing = [e[len('close:'):-len(':after')] for e in events
               if e.startswith('close:') and e.endswith(':after')]
    assert len(closing) == len(set(closing)) == len(bindings)
    occurrences = {}; counts = Counter()
    for call in calls:
        occurrences[call['id']] = counts[call['name']]; counts[call['name']] += 1
    kind, scope = recipe['kind'], recipe['scope']
    cut = len(events) - 2; first = None; primary = None
    if kind == 'group':
        candidates = [label for label in closing if by_label[label]['close_scope'] == scope
                      and len(open_sets[events.index('close:' + label + ':after')]) >= 1]
        assert candidates, scope
        first = candidates[0]; cut = events.index('close:' + first + ':after')
    elif kind == 'directory-primary':
        first = next(label for label in closing if by_label[label]['close_scope'] == scope)
        cut = events.index('opened:' + first)
        primary = dict(kind='directory-read', address=by_label[first]['address'],
            errno='EIO', error_prefix='cannot read bounded namespace' if scope == COORD + '::_names'
            else 'cannot read image members')
        first = None
    elif kind in ('source-primary', 'milestone-primary'):
        if kind == 'source-primary':
            candidates = [c for c in calls if c['name'] == CUSTODY + '::_recheck_source'
                and by_label[c['source_handle']]['close_scope'] == scope
                and len(open_sets[events.index('call:' + str(c['id']) + ':before')]) >= 2]
        elif scope == 'before-unlink':
            candidates = [c for c in calls if c['name'] == RELEASE + '::_unlink_exact']
        elif scope == 'after-unlink-unknown':
            candidates = [c for c in calls if c['name'] == 'NativeProxyPrivateWorkspace::_absent'
                and calls[c['parent']]['name'] == RELEASE + '::_assert_absent'
                and calls[c['parent']]['phase'] == 'after_unlink']
        else:
            candidates = [c for c in calls if c['name'] == COORD + '::_lock_identity'][-1:]
        assert candidates, (kind, scope)
        call = candidates[0]; cut = events.index('call:' + str(call['id']) + ':before')
        primary = dict(kind='call', symbol=call['name'], occurrence=occurrences[call['id']],
            phase='before', address=call['name'] + '#' + str(occurrences[call['id']]) + ':before')
    prefix = events[:cut + 1]
    remaining = open_sets[cut]
    suffix = ([first] if first else []) + [label for label in closing if label in remaining]
    assert len(suffix) == len(set(suffix))
    if kind == 'group': assert len(suffix) >= 2
    if primary: assert suffix
    reports = []
    for index, label in enumerate(suffix):
        bound = by_label[label]
        report = {k: bound[k] for k in ('address', 'kind', 'symbol', 'occurrence')}
        report['errno'] = ('EIO', 'ENOSPC')[index % 2] if not primary else ('ENOSPC', 'EIO')[index % 2]
        reports.append(report)
    winner = None
    if primary:
        winner = dict(kind=primary['kind'], value=primary['address'] if primary['kind'] == 'call'
                      else primary['error_prefix'], errno=primary.get('errno'))
    elif first:
        winner = dict(kind='close', value=ERRORS[by_label[first]['close_scope']], errno=reports[0]['errno'])
    if recipe['order'] == 'reversed': reports.reverse()
    entered = {int(e.split(':')[1]) for e in prefix if e.startswith('call:') and e.endswith(':before')}
    checks = [c for c in calls if c['name'] == RELEASE + '::_assert_absent' and c['id'] in entered]
    last = None
    if checks:
        check = checks[-1]
        last = dict(phase=check['phase'], state='absent' if 'call:' + str(check['id']) + ':after' in prefix else 'unknown')
    unlinked = int('unlink:0:after' in prefix)
    historical = int(any('call:' + str(c['id']) + ':after' in prefix for c in checks))
    return dict(primary=primary, reports=reports, cut_event=events[cut], winner=winner,
        cleanup_order=[by_label[label]['address'] for label in suffix],
        effects=dict(unlink_attempted=unlinked, unlink_completed=unlinked,
                     reference_absence_verified=historical, last_reference_check=last))
