"""Source-scope composition oracle: original primary errors survive all cleanup reports."""
from collections import Counter, defaultdict

RELEASE = 'NativeProxyObservationRelease'
COORD = 'NativeProxyImageCoordination'
CUSTODY = 'NativeProxyImageCustody'
ARCHIVE = 'NativeProxyObservationArchive'
CENSUS = 'NativeProxyReferenceCensus'
SOURCE = CUSTODY + '::_source'
RECHECK = CUSTODY + '::_recheck_source'
LOCAL_OWNERS = {ARCHIVE + '::_source_closure', COORD + '::_census', CENSUS + '::_closure'}
CALL_OWNERS = {CENSUS + '::_image', CENSUS + '::_inspect_locked', CUSTODY + '::read_entry'}
RELEASE_OWNERS = {RELEASE + '::_prepare', RELEASE + '::_retain_live_sources'}
ERRORS = {
    RELEASE + '::_close_owned': 'cannot close retained release descriptor',
    COORD + '::_transaction': 'cannot close permanent lock',
    COORD + '::_names': 'cannot close bounded namespace',
    COORD + '::_census': 'cannot close census reference',
    CUSTODY + '::_members': 'cannot close image directory',
    CUSTODY + '::read_entry': 'cannot close image descriptor',
    ARCHIVE + '::_source_closure': 'cannot close archive reread descriptor',
    CENSUS + '::_image': 'cannot close image input',
    CENSUS + '::_closure': 'cannot close fresh reference',
    CENSUS + '::_inspect_locked': 'cannot close reference',
}


class Failure(Exception):
    """An original source scope reports a failed close return."""


def derive(calls, context, sealed, resolved, errno_text):
    selected = {r["label"]: r for r in resolved["resolved_reports"]}
    assert len(selected) == len(resolved["resolved_reports"])
    primary = resolved["resolved_primary"]
    primary_hits = 0; directory_hits = 0; hit_addresses = []
    children = defaultdict(list)
    for call in calls: children[call['parent']].append(call['id'])
    roots = children[None]
    assert len(roots) == 23 and calls[roots[2]]['name'] == CUSTODY + '::_directory'
    assert calls[roots[2]]['path'] == context['store']['path']
    events = ['operation:begin']; counters = Counter(); handles = {}; active = set()
    scope_sources = defaultdict(list); release_sources = []; close_after = {}
    observed_calls = []; frames = {}; completed_tails = []; hits = 0; reports = []
    effects = dict(unlink_attempted=0, unlink_completed=0, reference_absence_verified=0, last_reference_check=None)

    def opened(kind, path, scope, source_call=None):
        label = kind + ':' + str(counters[kind]); counters[kind] += 1
        assert label not in handles
        handles[label] = dict(label=label, kind=kind, path=path,
            close_caller=scope.rsplit('::', 1)[0], source_call=source_call, close_scope=scope)
        active.add(label); events.append('opened:' + label)
        return label

    def close(label):
        nonlocal hits
        assert label in active
        events.extend(['close:' + label + ':before', 'close:' + label + ':after']); active.remove(label)
        target = selected.get(label); applied = target is not None
        reports.append(dict(label=label, applied=applied, errno=target["errno"] if target else None))
        if applied:
            h = handles[label]
            assert all(h[k] == target[k] for k in ('kind', 'path', 'close_caller', 'close_scope'))
            hits += 1; hit_addresses.append(target['address'])
            assert len(hit_addresses) == len(set(hit_addresses))
            return Failure(ERRORS[h['close_scope']] + ': ' + errno_text[target['errno']] + '\n')
        return None

    def boundary(call, phase):
        nonlocal primary_hits
        if phase == 'before':
            for ident in completed_tails:
                frames[ident].update(completion='caller_continuation', continuation=call['name'])
            completed_tails.clear()
            frame = {k: v for k, v in call.items() if k != 'opens'}
            frame.update(occurrence=counters[call['name']], tail=int(call['name'] in sealed))
            counters[call['name']] += 1
            frames[call['id']] = frame; observed_calls.append(frame)
        else:
            frames[call['id']]['completion'] = 'direct_return'
        events.append('call:' + str(call['id']) + ':' + phase)
        if primary is not None and primary['kind'] == 'call' and call['id'] == primary['call_id'] and phase == 'before':
            assert call['name'] == primary['symbol'] and frames[call['id']]['occurrence'] == primary['occurrence']
            primary_hits += 1; assert primary_hits == 1
            raise Failure('injected release call: ' + primary['address'] + '\n')

    def source(call):
        parent = calls[call['parent']]; owner = parent['name']
        number = counters['source']; events.extend(['source_request:' + str(number), 'read:' + str(number)])
        scope = RELEASE + '::_close_owned' if owner in RELEASE_OWNERS else owner
        label = opened('source', call['path'], scope, call['id']); assert label == call['opens']
        if owner in RELEASE_OWNERS:
            release_sources.append(label)
        else:
            assert owner in LOCAL_OWNERS | CALL_OWNERS
            scope_sources[parent['id']].append(label)
            if owner in LOCAL_OWNERS:
                following = calls[call['id'] + 1]
                assert following['name'] == RECHECK and following['source_handle'] == label
                assert following['parent'] == parent['id']
                close_after[following['id']] = label

    def visit(ident):
        nonlocal directory_hits
        call = calls[ident]; failure = None
        try:
            boundary(call, 'before')
            if call['name'] == SOURCE:
                source(call)
            elif call['name'] in (COORD + '::_names', CUSTODY + '::_members'):
                label = opened('directory', call['path'], call['name'])
                read_failure = None
                if primary is not None and primary['kind'] == 'directory-read' and label == primary['binding']['label']:
                    assert primary['binding']['path'] == call['path']
                    directory_hits += 1; assert directory_hits == 1
                    read_failure = Failure(primary['error_prefix'] + ': ' + errno_text['EIO'] + '\n')
                failure = close(label)
                # The original reader saves its body error before closedir.
                if read_failure is not None: raise read_failure
                if failure: raise failure
            elif call['name'] == RELEASE + '::_unlink_exact':
                assert 'lock:0' in active and effects['unlink_completed'] == 0
                events.extend(['unlink:0:before', 'unlink:0:after'])
                effects.update(unlink_attempted=1, unlink_completed=1)
            elif call['name'] == RELEASE + '::_assert_absent':
                effects['last_reference_check'] = dict(phase=call['phase'], state='unknown')
            for child in children[ident]:
                visit(child)
                if child in close_after:
                    failure = close(close_after[child])
                    if failure: raise failure
            if call['name'] == RELEASE + '::_assert_absent':
                effects['last_reference_check']['state'] = 'absent'
                effects['reference_absence_verified'] = 1
        except Failure as caught:
            failure = caught
        finally:
            # Every scope closes all its actual owned handles. A body error
            # remains primary; otherwise only its first close error escapes.
            for label in scope_sources[ident]:
                if label in active:
                    error = close(label)
                    if failure is None and error is not None: failure = error
        if failure is not None: raise failure
        if call['name'] in sealed: completed_tails.append(ident)
        else: boundary(call, 'after')

    failure = None
    try:
        for ident in roots:
            visit(ident)
            if ident == roots[2]: opened('lock', context['acquired']['lock']['path'], COORD + '::_transaction')
    except Failure as caught:
        failure = caught
    finally:
        if 'lock:0' in active:
            error = close('lock:0')
            if failure is None and error is not None: failure = error
        for label in release_sources:
            if label in active:
                error = close(label)
                if failure is None and error is not None: failure = error
    assert not active and hits == len(selected)
    assert primary_hits + directory_hits == int(primary is not None)
    events.append('operation:end')
    pending = [call['id'] for call in observed_calls if 'completion' not in call]
    return dict(events=events, calls=observed_calls, handles=list(handles.values()), reports=reports,
        interrupted_boundary_ids=pending, injected_hits=primary_hits, directory_primary_hits=directory_hits,
        reported_error_hits=hits, reported_error_addresses=hit_addresses,
        effects=effects, success=int(failure is None), error='' if failure is None else str(failure))
