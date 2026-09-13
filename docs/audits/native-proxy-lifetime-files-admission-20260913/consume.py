"""Independent, data-only consumer of the prospective actual-file journal.

No fixture producer or lifecycle operation is imported or executed. Native
identities come from retained observations, never from the synthetic catalog.
"""
from __future__ import annotations

import copy
import hashlib
import os
import stat
from collections import Counter

from support import OLD_COMMON, OLD_MODEL, canonical, digest
from oracle import physical_projection, stable


def within(path, roots):
    assert isinstance(path, str) and all(part not in ('', '.', '..') for part in path.split('/'))
    assert any(path == root or path.startswith(root + '/') for root in roots), path


def snapshot(value, roots, bounds, uid, device):
    assert set(value) == {'nodes', 'absent_roots', 'file_bytes'}
    nodes = value['nodes']; assert len(nodes) <= bounds['tree_nodes']
    identities, total = set(), 0
    for path, node in nodes.items():
        within(path, roots)
        root = next(root for root in roots if path == root or path.startswith(root + '/'))
        assert path.count('/') - root.count('/') <= bounds['tree_depth']
        if path != root:
            assert nodes[path.rsplit('/', 1)[0]]['kind'] == 'directory'
        identity = node['identity']; assert identity['path'] == path
        assert identity['device'] == device and node['uid'] == uid
        key = (identity['device'], identity['inode']); assert key not in identities; identities.add(key)
        if node['kind'] == 'directory':
            assert set(node) == {'kind', 'mode', 'uid', 'identity', 'native'}
            assert set(identity) == {'path', 'device', 'inode'} and node['mode'] == 0o700
            native = node['native']; assert stat.S_ISDIR(native[2])
        else:
            assert node['kind'] == 'file'
            assert set(node) == {'kind', 'mode', 'uid', 'links', 'bytes_hex', 'identity', 'native_before', 'native_after'}
            raw = OLD_COMMON.archive.snapshot(dict(identity=identity, bytes_hex=node['bytes_hex']))
            assert len(raw) <= bounds['file_bytes'] and node['links'] == 1
            assert node['mode'] in (0o400, 0o500, 0o600, 0o700)
            native = node['native_before']; after = node['native_after']
            assert stat.S_ISREG(native[2]) and native[3] == 1
            assert all(native[i] == after[i] for i in (0, 1, 2, 3, 4, 7, 9, 10))
            assert native[7] == len(raw); total += len(raw)
        assert len(native) == 13 and native[0] == device and native[1] == identity['inode']
        assert native[4] == uid and stat.S_IMODE(native[2]) == node['mode']
    assert value['absent_roots'] == [root for root in roots if root not in nodes]
    assert value['file_bytes'] == total <= bounds['tree_bytes']
    return stable(nodes)


def trace(value, roots, limits, readonly=False, native_flags=None):
    flags = native_flags or {name: getattr(os, name) for name in ('O_WRONLY', 'O_RDWR', 'O_CREAT', 'O_TRUNC', 'O_EXCL')}
    assert value['returned'] == 1 and value['error_hex'] == ''
    assert value['ownership_registration_error_hex'] == '' and value['recovery'] == []
    calls, handles = value['calls'], value['handles']
    assert len(calls) <= limits['calls'] and len(handles) <= limits['handles']
    opens, closes, created = {}, {}, {}
    for index, call in enumerate(calls):
        operation = call['operation']
        assert operation in ('sysopen', 'opendir', 'close', 'closedir', 'mkdir', 'unlink', 'rmdir', 'syswrite', 'chmod')
        if readonly:
            assert operation in ('sysopen', 'opendir', 'close', 'closedir')
            if operation == 'sysopen':
                assert not call['flags'] & (flags['O_WRONLY'] | flags['O_RDWR'] | flags['O_CREAT'] | flags['O_TRUNC'])
        if 'path' in call: within(call['path'], roots)
        for path in call.get('paths', []): within(path, roots)
        for target in call.get('targets', []):
            if 'path' in target: within(target['path'], roots)
            else: assert target['handle'] in opens and target['handle'] not in closes
        if operation in ('sysopen', 'opendir') and call['returned']:
            ordinal = call['handle']; assert ordinal == len(opens)
            handle = handles[ordinal]; opens[ordinal] = index
            assert handle['ordinal'] == ordinal and handle['opening_call'] == index
            assert handle['path'] == call['path'] and handle['open_caller'] == call['caller']
            assert handle['kind'] == ('file' if operation == 'sysopen' else 'directory')
            native = handle['native_at_open']; assert len(native) == 13
            if operation == 'sysopen' and call['flags'] & flags['O_CREAT'] and call['flags'] & flags['O_EXCL']:
                created[call['path']] = dict(path=call['path'], device=native[0], inode=native[1], kind='file')
            if operation == 'opendir':
                observer = handle['metadata_observer']
                assert observer['returned'] == 1 and observer['closed_after_call'] == 1
        elif operation in ('close', 'closedir'):
            ordinal = call['handle']; assert ordinal in opens and ordinal not in closes
            closes[ordinal] = index
            handle = handles[ordinal]
            assert operation == ('close' if handle['kind'] == 'file' else 'closedir')
            assert call['returned'] == 1 and call['closed_after_call'] == 1
            assert handle['closed_at_return'] == 1
            assert all(call[key] == item for key, item in handle['close'].items())
            if operation == 'close': assert call['cloexec_before_close'] == 1
        elif operation == 'mkdir' and call['returned']:
            native = call['native_after']; assert len(native) == 13 and stat.S_ISDIR(native[2])
            created[call['path']] = dict(path=call['path'], device=native[0], inode=native[1], kind='directory')
        elif operation == 'syswrite':
            assert call['handle'] in opens and call['handle'] not in closes
            assert call['returned'] is not None and 0 <= call['returned'] <= call['requested']
    assert len(opens) == len(handles) and set(opens) == set(closes)
    directories = [row['ordinal'] for row in handles if row['kind'] == 'directory']
    assert [row['parent_ordinal'] for row in value['metadata_observers']] == directories
    assert all(row['closed_at_return'] == 1 for row in value['metadata_observers'])
    # Successful calls may retain nonzero errno. Return values and physical
    # descriptor absence determine completeness; errno is preserved verbatim.
    return created


def initial(context, payloads, suffix):
    nodes = context['initial']['nodes']; paths = context['paths']; expected = set()

    def directory(path, identity=None):
        expected.add(path); node = nodes[path]
        assert node['kind'] == 'directory' and node['mode'] == 0o700
        if identity is not None: assert identity == node['identity']

    def file(path, raw, mode):
        expected.add(path); node = nodes[path]
        assert node['kind'] == 'file' and node['mode'] == mode and node['bytes_hex'] == raw.hex()
        return dict(bytes_hex=raw.hex(), identity=copy.deepcopy(node['identity']))

    for name, path in paths.items(): directory(path, context['directories'][name])
    for name in ('images', 'references'): directory(paths['store'] + '/' + name)
    lock_file = file(paths['store'] + '/coordination.lock', b'', 0o600)
    lock = {key: lock_file['identity'][key] for key in ('path', 'device', 'inode')}
    sources, images, runtimes = {}, {}, {}
    for name in ('target', 'other'):
        workspace = paths[name]; directory(workspace + '/rust-tools')
        wrapper = file(workspace + '/rust-tool-resolution', payloads['wrapper'], 0o700)
        c = payloads['c']; image = payloads['image']
        if name == 'other' and context['profile'] == 'different_image': image += suffix
        key = OLD_COMMON.image_key(c, image); base = paths['store'] + '/images/' + key
        directory(base)
        pair = [file(base + '/rustup.c', c, 0o400), file(base + '/rustup', image, 0o500)]
        manifest = dict(schema='fsmgen.test.rust_proxy_image.v1', key=key,
            generated_c={k: pair[0]['identity'][k] for k in ('size_bytes', 'sha256')},
            executable={k: pair[1]['identity'][k] for k in ('size_bytes', 'sha256')})
        manifest_source = file(base + '/image.json', canonical(manifest), 0o400)
        reference_key = hashlib.sha256(b'fsmgen.rust_proxy_reference.runtime.v1\0' + workspace.encode()).hexdigest()
        record = dict(schema='fsmgen.test.rust_proxy_image_reference.v1', reference_key=reference_key,
            image_key=key, workspace=workspace, workspace_identity=context['directories'][name],
            selected_sources=[source['identity'] for source in pair])
        private = file(workspace + '/rust-tools/image-reference.json', canonical(record), 0o400)
        global_source = file(paths['store'] + '/references/' + reference_key + '.json', canonical(record), 0o400)
        reference = {'record': record, 'private': private, 'global': global_source}
        assert context['runtimes'][name] == dict(schema='fsmgen.inactive_runtime_reference_acquisition.v1',
            runtime_authorized=0, executable=None, lock=lock,
            created=int(name == 'target' or context['profile'] == 'different_image'),
            reference=reference, image=dict(key=key, snapshots=pair + [manifest_source]))
        images[key] = pair; sources[name] = [wrapper, private, global_source] + pair
        runtimes[name] = dict(directory=context['directories'][name], record=record, source=global_source,
            private=[wrapper, private], cleanup=[OLD_COMMON.settled_owner('failed'), OLD_COMMON.settled_owner(),
                                              [OLD_COMMON.settled_owner('cancelled')]])
    observers = {}
    for name in ('a', 'b'):
        request = context['requests'][name]
        assert request['workspace_identity'] == context['directories']['target']
        assert request['evidence_directory_identity'] == context['directories']['evidence']
        key = hashlib.sha256(b'fsmgen.rust_proxy_reference.observation.v1\0' + canonical(
            [paths['evidence'], request['observer_birth'], request['target_birth']])).hexdigest()
        record = dict(schema='fsmgen.test.rust_proxy_image_observation_reference.v1', reference_key=key,
            image_key=context['runtimes']['target']['image']['key'], evidence_directory=paths['evidence'],
            evidence_directory_identity=context['directories']['evidence'], observer_birth=request['observer_birth'],
            target_birth=request['target_birth'], selected_sources=[row['identity'] for row in sources['target'][3:]])
        hold = file(paths['store'] + '/references/' + key + '.json', canonical(record), 0o400)
        expected_acquired = dict(schema='fsmgen.inactive_observation_acquisition.v1', runtime_authorized=0,
            executable=None, lock=lock, observation_reference=dict(record=record, source=hold), target_sources=sources['target'])
        assert context['observations'][name] == expected_acquired
        value = dict(case=paths['store'], request=request, acquired=expected_acquired,
            selection=context['selections'][name], settlement=context['settlements'][name])
        OLD_COMMON.work.selection(value, value['selection']); OLD_COMMON.work.settlement(value, value['settlement'])
        observers[name] = value
    assert set(nodes) == expected
    return dict(profile=context['profile'], identity_origin='retained_native_file_observations_synthetic_process_ownership',
        images=images, runtimes=runtimes, observers=observers,
        target_image=context['runtimes']['target']['image']['key'], other_image=context['runtimes']['other']['image']['key'])


def stage_names(case):
    names = ['create_owned_roots', 'prepare_private_wrappers', 'acquire_runtime_target',
             'acquire_runtime_other', 'acquire_observation_a', 'acquire_observation_b']
    completed = set()
    for event in case['order']:
        for name in ('a', 'b'):
            if 'retire_target' not in completed and 'release_' + name not in completed:
                names.append('reuse_' + name + '_before_' + event)
        names.append(event); completed.add(event)
    return names + ['owned_cleanup']


def probe(value, roots, selection, uid, device, native_flags):
    trace(value, roots, selection['trace_limits'], readonly=True, native_flags=native_flags)
    nodes = snapshot(value['result'], roots, selection['bounds'], uid, device)
    expected = Counter({(path, node['kind']): 1 if node['kind'] == 'file' else 2 for path, node in nodes.items()})
    assert Counter((row['path'], row['kind']) for row in value['handles']) == expected
    for handle in value['handles']:
        identity = nodes[handle['path']]['identity']
        assert handle['native_at_open'][:2] == [identity['device'], identity['inode']]
    return nodes


def event_input(name, context, seed):
    base = dict(store=context['paths']['store'])
    if name.startswith('retire_'):
        owners = seed['runtimes'][name.removeprefix('retire_')]['cleanup']
        return dict(base, acquired=context['runtimes'][name.removeprefix('retire_')],
                    cleanup=dict(compiler=owners[0], outer=owners[1], stages=owners[2]))
    if name == 'maintain_target': return dict(base, image_key=seed['target_image'])
    observer = name.split('_')[1] if name.startswith('reuse_') else name[-1]
    value = seed['observers'][observer]
    result = dict(base, request=value['request'], acquired=value['acquired'])
    if name.startswith('release_'):
        result.update(archive=value['archive'], selection=value['selection'], settlement=value['settlement'])
    return result


def event_result(name, result, context, seed, before):
    base = dict(runtime_authorized=0, executable=None, lock=context['runtimes']['target']['lock'])
    if name.startswith('retire_'):
        runtime = context['runtimes'][name.removeprefix('retire_')]
        workspace = runtime['reference']['record']['workspace']
        assert result == dict(base, schema='fsmgen.inactive_runtime_retirement.v1', retired_workspace=workspace,
            released_reference=runtime['reference']['global']['identity']['path'], image=runtime['image'],
            removed_nodes=sum(path == workspace or path.startswith(workspace + '/') for path in before))
    elif name == 'maintain_target':
        assert result == dict(base, schema='fsmgen.inactive_image_maintenance.v1', removed_image=seed['target_image'],
                             removed_sources=context['runtimes']['target']['image']['snapshots'])
    elif name.startswith('release_'):
        value = seed['observers'][name[-1]]
        release = dict(base, schema='fsmgen.inactive_observation_release.v1',
            released_reference=value['acquired']['observation_reference']['source']['identity']['path'],
            image=context['runtimes']['target']['image'], archive=value['archive'], settlement=value['settlement'])
        assert result == dict(schema='fsmgen.inactive_observation_release_attempt.v1', runtime_authorized=0,
            executable=None, success=1, error='', unlink_attempted=1, unlink_completed=1,
            reference_absence_verified=1, last_reference_check=dict(phase='finish', state='absent'), release=release)
    else:
        assert result == seed['observers'][name[-1]]['archive']


def verify(records, selection, payloads):
    assert records[0]['kind'] == 'run-started' and records[-1]['kind'] == 'run-final'
    start = records[0]['value']; final = records[-1]['value']
    assert start['runtime_qualification'] == 0 and start['synthetic_ownership_only'] == 1
    uid = start['normal_uid']; assert type(uid) is int and uid > 0
    native_flags = start['admission']['native_open_flags']
    assert set(native_flags) == {'O_WRONLY', 'O_RDWR', 'O_CREAT', 'O_TRUNC', 'O_EXCL'}
    assert all(type(value) is int and value > 0 for value in native_flags.values())
    assert final['success'] == 1 and final['forbidden_process_attempts'] == 0 and final['runtime_qualification'] == 0
    assert len(final['cases']) == len(selection['cases'])
    assert 0 <= final['elapsed_ns'] <= selection['bounds']['total_wall_seconds'] * 1_000_000_000
    for sequence, record in enumerate(records):
        assert set(record) == {'schema', 'sequence', 'kind', 'monotonic_ns', 'value'}
        assert record['schema'] == 'fsmgen.inactive_lifetime_files_event.v1' and record['sequence'] == sequence
        assert sequence == 0 or record['monotonic_ns'] >= records[sequence - 1]['monotonic_ns']
    cursor, summaries = 1, []
    for case in selection['cases']:
        begin = cursor
        assert records[cursor]['kind'] == 'case-intent' and records[cursor]['value']['case'] == case
        cursor += 1
        while cursor < len(records) and records[cursor]['kind'] != 'case-final': cursor += 1
        assert cursor < len(records) - 1
        rows = records[begin:cursor + 1]; cursor += 1
        stages = [row['value'] for row in rows if row['kind'] == 'stage']
        assert [row['name'] for row in stages] == stage_names(case)
        initial_rows = [row['value'] for row in rows if row['kind'] == 'case-initial']; assert len(initial_rows) == 1
        context = initial_rows[0]
        assert context['name'] == case['name'] and context['paths'] == case['roots'] and context['profile'] == case['profile']
        roots = [case['roots'][key] for key in ('store', 'target', 'other', 'evidence')]
        assert context['roots'] == roots and context['current'] == context['initial']
        assert records[begin]['value']['roots_absent_before_creation'] == roots
        device = context['directories']['store']['device']
        snapshot(context['initial'], roots, selection['bounds'], uid, device)
        seed = initial(context, payloads, bytes.fromhex(selection['payload_source']['different_image_suffix_hex']))
        objects = copy.deepcopy(context['initial']['nodes'])
        for name in ('a', 'b'):
            archived = next(row for row in stages if row['name'] == 'archive_' + name)
            value = seed['observers'][name]; receipt = archived['operation']['result']
            OLD_COMMON.archive.validate(value, receipt)
            spec = OLD_COMMON.archive.specification(value); nodes = archived['after']['result']['nodes']
            value['directory'] = nodes[spec['archive_directory']]['identity']
            value['snapshots'] = [dict(identity=nodes[row['path']]['identity'], bytes_hex=nodes[row['path']]['bytes_hex'])
                                  for row in spec['files']]
            value['archive'] = OLD_COMMON.archive.from_snapshots(value); assert value['archive'] == receipt
            archive_paths = {spec['archive_directory']} | {row['path'] for row in spec['files']}
            for path in archive_paths:
                if path in objects: assert stable({path: objects[path]}) == stable({path: nodes[path]})
                objects[path] = nodes[path]
        state = OLD_MODEL.initial(seed); owned = {}; previous = {}; prefix = []
        prefix_rows = [row['value'] for row in rows if row['kind'] == 'prefix-verified']
        assert len(prefix_rows) == len(case['order'])
        for index, row in enumerate(stages):
            assert row['case'] == case['name'] and row['input_before'] == row['input_after']
            assert row['started_monotonic_ns'] <= row['ended_monotonic_ns']
            before, operation, after = row['before'], row['operation'], row['after']
            created = trace(operation, roots, selection['trace_limits'], native_flags=native_flags)
            before_state = probe(before, roots, selection, uid, device, native_flags)
            after_state = probe(after, roots, selection, uid, device, native_flags)
            assert before_state == previous
            removed = []
            for call in operation['calls']:
                if call['operation'] == 'unlink':
                    assert call['returned'] == len(call['paths']); removed.extend(call['paths'])
                elif call['operation'] == 'rmdir':
                    assert call['returned'] == 1; removed.append(call['path'])
            assert len(removed) == len(set(removed)) and set(removed) == set(before_state) - set(after_state)
            for path, identity in created.items():
                assert path not in owned or owned[path] == identity
                owned[path] = identity
            for path, node in after_state.items():
                assert owned[path] == dict(path=path, device=node['identity']['device'], inode=node['identity']['inode'], kind=node['kind'])
            name = row['name']
            if index < 6:
                initial_state = stable(context['initial']['nodes'])
                assert all(initial_state[path] == node for path, node in after_state.items())
                assert all(after_state[path] == node for path, node in before_state.items())
                if index == 5: assert after_state == initial_state
                if name.startswith('acquire_runtime_'):
                    assert operation['result'] == context['runtimes'][name.removeprefix('acquire_runtime_')]
                elif name.startswith('acquire_observation_'):
                    assert operation['result'] == context['observations'][name[-1]]
            elif name.startswith('reuse_'):
                assert row['input_before'] == event_input(name, context, seed)
                observer = name.split('_')[1]
                assert OLD_MODEL.live_matches(seed, state, observer, True)
                assert operation['result'] == context['observations'][observer] and before_state == after_state
            elif name == 'owned_cleanup':
                assert after_state == {} and operation['result']['absent_roots'] == roots
                assert set(operation['result']['removed']) == set(before_state)
                assert len(operation['result']['removed']) == len(before_state)
            else:
                assert name == case['order'][len(prefix)]
                assert row['input_before'] == event_input(name, context, seed)
                event_result(name, operation['result'], context, seed, before_state)
                if name.startswith('retire_'):
                    runtime = context['runtimes'][name.removeprefix('retire_')]
                    assert removed[-1] == runtime['reference']['global']['identity']['path']
                result = OLD_MODEL.transition(seed, state, name); assert result['returned']
                expected = stable(physical_projection(seed, state, objects)); assert after_state == expected
                prefix.append(name); declared = prefix_rows[len(prefix) - 1]
                assert declared == dict(case=case['name'], completed=sorted(prefix), stable_state_sha256=digest(expected))
            previous = after_state
        cleanup_rows = [row['value'] for row in rows if row['kind'] == 'cleanup-admission']; assert len(cleanup_rows) == 1
        cleanup = cleanup_rows[0]
        assert cleanup['case'] == case['name'] and cleanup['created_identities'] == owned
        assert probe(cleanup['observed'], roots, selection, uid, device, native_flags) == stable(stages[-1]['before']['result']['nodes'])
        primary = [row['value'] for row in rows if row['kind'] == 'case-primary']
        assert primary == [dict(case=case['name'], returned=1, error_hex='')]
        result = rows[-1]['value']
        assert result['case'] == case['name'] and result['primary_returned'] == result['cleanup_returned'] == 1
        assert result['error_hex'] == result['cleanup_error_hex'] == '' and result['cleanup'] == stages[-1]['operation']['result']
        assert result == final['cases'][len(summaries)]
        assert rows[-1]['monotonic_ns'] - rows[0]['monotonic_ns'] <= (
            selection['bounds']['case_wall_seconds'] + selection['bounds']['cleanup_wall_seconds']) * 1_000_000_000
        assert all(row['kind'] in ('case-intent', 'stage', 'case-initial', 'prefix-verified', 'case-primary',
                                   'cleanup-admission', 'case-final') for row in rows)
        summaries.append(dict(case=case['name'], stages=len(stages), prefixes=len(prefix), roots=roots))
    assert cursor == len(records) - 1
    return dict(cases=summaries, stages=sum(row['stages'] for row in summaries),
                prefixes=sum(row['prefixes'] for row in summaries), journal_records=len(records),
                runtime_qualification=False, native_process_authentication=False)
