"""Source-scope oracle for reader failures and original consumer validation.

No callback throws at source return. Body controls alter an earlier reported
read buffer; the unchanged caller registers ownership before validating it.
The modeled return boundary describes that later validation failure only.
"""
from collections import Counter, defaultdict
import errno
import os

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
    """The original reader or consumer throws; the observer does not."""


def outcome(calls, selected):
    if selected is None:
        return dict(stop=None, expected_success=True, expected_error='')
    sources = [c for c in calls if c['name'] == SOURCE]
    assert type(selected['occurrence']) is int and 0 <= selected['occurrence'] < len(sources)
    source = sources[selected['occurrence']]
    assert selected['call_id'] == source['id'] and selected['path'] == source['path']
    mode = selected['control']
    if mode in ('first-eio', 'partial-eio', 'early-eof'):
        error = ('fixture changed during its bounded read\n' if mode == 'early-eof'
                 else 'cannot read fixture bytes: ' + os.strerror(errno.EIO) + '\n')
        return dict(stop=dict(call_id=source['id'], point='reader_failure'),
                    expected_success=False, expected_error=error)
    if mode == 'one-byte':
        return dict(stop=None, expected_success=True, expected_error='')
    assert mode == 'body-xor'
    parent = calls[source['parent']]
    if parent['name'] == COORD + '::_census':
        return dict(stop=None, expected_success=True, expected_error='')
    siblings = [c for c in calls if c['parent'] == parent['id']]
    point = 'after_return'
    ident = source['id']
    direct = {
        RELEASE + '::_prepare': 'release archive bytes differ from retained original\n',
        RELEASE + '::_retain_live_sources': 'release live source differs from original custody\n',
        ARCHIVE + '::_source_closure': 'archive reread bytes or native identity changed\n',
        CENSUS + '::_closure': 'reference identity or bytes changed\n',
    }
    if parent['name'] in direct:
        error = direct[parent['name']]
    elif parent['name'] == CENSUS + '::_image':
        target, = [c for c in siblings if c['name'] == CUSTODY + '::read_entry']
        ident, point = target['id'], 'before_body'
        error = 'key does not match compiled bytes\n'
    elif parent['name'] == CENSUS + '::_inspect_locked':
        target = calls[source['id'] + 1]
        assert target['parent'] == parent['id'] and target['name'] == CENSUS + '::_decode_record'
        ident, point = target['id'], 'before_body'
        error = 'expected bounded ASCII reference bytes\n'
    else:
        assert parent['name'] == CUSTODY + '::read_entry'
        reads = [c for c in siblings if c['name'] == SOURCE]
        assert len(reads) == 3
        ident = reads[-1]['id']
        error = ('manifest differs from exact content reconstruction\n' if source['path'].endswith('/image.json')
                 else 'image differs from the actual compiled byte pair\n')
    return dict(stop=dict(call_id=ident, point=point), expected_success=False, expected_error=error)


def derive(calls, context, sealed, selected):
    verdict = outcome(calls, selected)
    stop = verdict['stop']
    children = defaultdict(list)
    for call in calls:
        children[call['parent']].append(call['id'])
    roots = children[None]
    assert len(roots) == 23 and calls[roots[2]]['name'] == CUSTODY + '::_directory'
    assert calls[roots[2]]['path'] == context['store']['path']
    assert calls[roots[3]]['name'] == calls[roots[-1]]['name'] == COORD + '::_lock_identity'
    events = ['operation:begin']
    counters = Counter()
    handles, frames = {}, {}
    active = set()
    scope_sources = defaultdict(list)
    release_sources, completed_tails, observed_calls = [], [], []
    close_after = {}
    readback_hits = 0
    unlinked = False

    def opened(kind, path, caller, source_call=None):
        label = kind + ':' + str(counters[kind])
        counters[kind] += 1
        assert label not in handles
        handles[label] = dict(label=label, kind=kind, path=path, close_caller=caller, source_call=source_call)
        active.add(label)
        events.append('opened:' + label)
        return label

    def close(label):
        assert label in active
        events.extend(['close:' + label + ':before', 'close:' + label + ':after'])
        active.remove(label)

    def boundary(call, phase):
        if phase == 'before':
            for ident in completed_tails:
                frames[ident].update(completion='caller_continuation', continuation=call['name'])
            completed_tails.clear()
            frame = {k: v for k, v in call.items() if k != 'opens'}
            frame.update(occurrence=counters[call['name']], tail=int(call['name'] in sealed))
            counters[call['name']] += 1
            frames[call['id']] = frame
            observed_calls.append(frame)
        else:
            frames[call['id']]['completion'] = 'direct_return'
        events.append('call:' + str(call['id']) + ':' + phase)

    def source(call):
        nonlocal readback_hits
        parent = calls[call['parent']]
        owner = parent['name']
        number = counters['source']
        events.extend(['source_request:' + str(number), 'read:' + str(number)])
        if selected is not None and call['id'] == selected['call_id']:
            readback_hits += 1
            if stop is not None and stop['point'] == 'reader_failure':
                raise Cut()
        label = opened('source', call['path'], RELEASE if owner in RELEASE_OWNERS else owner.rsplit('::', 1)[0], call['id'])
        assert label == call['opens']
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
        nonlocal unlinked
        call = calls[ident]
        try:
            boundary(call, 'before')
            if stop == dict(call_id=ident, point='before_body'):
                raise Cut()
            if call['name'] == SOURCE:
                source(call)
            elif call['name'] in (COORD + '::_names', CUSTODY + '::_members'):
                label = opened('directory', call['path'], call['name'].rsplit('::', 1)[0])
                close(label)
            elif call['name'] == RELEASE + '::_unlink_exact':
                assert 'lock:0' in active and not unlinked
                events.extend(['unlink:0:before', 'unlink:0:after'])
                unlinked = True
            for child in children[ident]:
                visit(child)
                if child in close_after:
                    close(close_after[child])
        finally:
            for label in scope_sources[ident]:
                if label in active:
                    close(label)
        if call['name'] in sealed:
            completed_tails.append(ident)
        else:
            boundary(call, 'after')
        if stop == dict(call_id=ident, point='after_return'):
            assert call['name'] == SOURCE
            raise Cut()

    try:
        for ident in roots:
            visit(ident)
            if ident == roots[2]:
                opened('lock', context['acquired']['lock']['path'], COORD)
    except Cut:
        pass
    finally:
        if 'lock:0' in active:
            close('lock:0')
        for label in release_sources:
            if label in active:
                close(label)
    assert not active and readback_hits == int(selected is not None)
    pending = []
    if stop is not None:
        ident = stop['call_id']
        if stop['point'] == 'after_return':
            ident = calls[ident]['parent']
        while ident is not None:
            pending.append(ident)
            ident = calls[ident]['parent']
        pending.reverse()
    assert {ident for ident, frame in frames.items() if 'completion' not in frame} == set(pending)
    events.append('operation:end')
    return dict(events=events, calls=observed_calls, handles=list(handles.values()),
        interrupted_boundary_ids=pending, injected_hits=0, readback_hits=readback_hits,
        unlinked=unlinked, **verdict)
