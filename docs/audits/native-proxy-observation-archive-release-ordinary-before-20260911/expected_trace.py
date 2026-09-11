"""Pure source-scope oracle for ordinary selected-call interruptions.

This interprets the independently derived call forest and each original owning
scope. It predicts real source/directory/lock opens and closes, including the
cleanup suffix after one before-call exception. No trace verdict is an input.
"""
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


class Cut(Exception):
    """One prospective source-level exception, never an OS-close model."""


def derive(calls, context, sealed, selected):
    children = defaultdict(list)
    for call in calls: children[call['parent']].append(call['id'])
    roots = children[None]
    assert len(roots) == 23 and calls[roots[2]]['name'] == CUSTODY + '::_directory'
    assert calls[roots[2]]['path'] == context['store']['path']
    assert calls[roots[3]]['name'] == COORD + '::_lock_identity'
    assert calls[roots[-1]]['name'] == COORD + '::_lock_identity'
    if selected is not None: assert selected['phase'] == 'before'
    events = ['operation:begin']; counters = Counter(); handles = {}; active = set()
    scope_sources = defaultdict(list); release_sources = []; close_after = {}
    observed_calls = []; frames = {}; completed_tails = []; hits = 0; unlinked = False

    def opened(kind, path, caller, source_call=None):
        label = kind + ':' + str(counters[kind]); counters[kind] += 1
        assert label not in handles
        handles[label] = dict(label=label, kind=kind, path=path, close_caller=caller, source_call=source_call)
        active.add(label); events.append('opened:' + label)
        return label

    def close(label):
        assert label in active
        events.extend(['close:' + label + ':before', 'close:' + label + ':after']); active.remove(label)

    def boundary(call, phase):
        nonlocal hits
        if phase == 'before':
            for ident in completed_tails:
                frames[ident].update(completion='caller_continuation', continuation=call['name'])
            completed_tails.clear()
            frame = {k: v for k, v in call.items() if k != 'opens'}
            frame.update(occurrence=counters[call['name']], tail=int(call['name'] in sealed))
            counters[call['name']] += 1
            frames[call['id']] = frame; observed_calls.append(frame)
        else: frames[call['id']]['completion'] = 'direct_return'
        events.append('call:' + str(call['id']) + ':' + phase)
        if selected is not None and call['id'] == selected['call_id'] and phase == selected['phase']:
            assert call['name'] == selected['symbol'] and frames[call['id']]['occurrence'] == selected['occurrence']
            hits += 1; assert hits == 1
            raise Cut()

    def source(call):
        parent = calls[call['parent']]; owner = parent['name']; package = owner.rsplit('::', 1)[0]
        number = counters['source']
        events.extend(['source_request:' + str(number), 'read:' + str(number)])
        label = opened('source', call['path'], RELEASE if owner in RELEASE_OWNERS else package, call['id'])
        assert label == call['opens']
        if owner in RELEASE_OWNERS: release_sources.append(label)
        else:
            assert owner in LOCAL_OWNERS | CALL_OWNERS, owner
            scope_sources[parent['id']].append(label)
            if owner in LOCAL_OWNERS:
                following = calls[call['id'] + 1]
                assert following['name'] == RECHECK and following['source_handle'] == label
                assert following['parent'] == parent['id']
                close_after[following['id']] = label

    def visit(ident):
        nonlocal unlinked
        call = calls[ident]
        try:
            boundary(call, 'before')
            if call['name'] == SOURCE: source(call)
            elif call['name'] in (COORD + '::_names', CUSTODY + '::_members'):
                label = opened('directory', call['path'], call['name'].rsplit('::', 1)[0]); close(label)
            elif call['name'] == RELEASE + '::_unlink_exact':
                assert 'lock:0' in active and not unlinked
                events.extend(['unlink:0:before', 'unlink:0:after']); unlinked = True
            for child in children[ident]:
                visit(child)
                if child in close_after: close(close_after[child])
        finally:
            # Inner source-owning calls unwind first. Fresh single-read scopes
            # have at most their current descriptor left here; already closed
            # iterations are retained as history and skipped.
            for label in scope_sources[ident]:
                if label in active: close(label)
        if call['name'] in sealed: completed_tails.append(ident)
        else: boundary(call, 'after')

    try:
        for ident in roots:
            visit(ident)
            if ident == roots[2]: opened('lock', context['acquired']['lock']['path'], COORD)
    except Cut:
        pass
    finally:
        if 'lock:0' in active: close('lock:0')
        for label in release_sources:
            if label in active: close(label)
    assert not active and hits == int(selected is not None)
    events.append('operation:end')
    pending = []
    if selected is not None:
        ident = selected['call_id']
        while ident is not None: pending.append(ident); ident = calls[ident]['parent']
        pending.reverse()
    assert {ident for ident, frame in frames.items() if 'completion' not in frame} == set(pending)
    return dict(events=events, calls=observed_calls, handles=list(handles.values()),
                interrupted_boundary_ids=pending, injected_hits=hits, unlinked=unlinked)
