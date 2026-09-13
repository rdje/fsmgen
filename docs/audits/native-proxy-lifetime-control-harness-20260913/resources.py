"""Descriptor/call closure only; the control reader separately verifies verdicts.

Copied from the qualified complete-file trace reader with only its successful
API-return precondition removed. No primary data field is rewritten.
"""
import os
import stat
from support_controls import CONSUME
within=CONSUME.within

def resources(value, roots, limits, readonly=False, native_flags=None):
    flags = native_flags or {name: getattr(os, name) for name in ('O_WRONLY', 'O_RDWR', 'O_CREAT', 'O_TRUNC', 'O_EXCL')}
    assert type(value['returned']) is int and value['returned'] in (0, 1)
    assert isinstance(value['error_hex'], str)
    bytes.fromhex(value['error_hex'])
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


def opened_identities(value, before, after, uid, device, flags):
    """Join each opened object to an independently observed named object.

    New files can still have their initial writable mode and length at open;
    their identity must join the after-state. Existing objects must preserve
    the captured kind, ownership, mode and file size through observation.
    """
    for handle in value['handles']:
        path=handle['path'];native=handle['native_at_open']
        assert native[0]==device and native[4]==uid
        assert (stat.S_ISDIR(native[2]) if handle['kind']=='directory' else stat.S_ISREG(native[2]))
        candidates=[nodes[path] for nodes in (before,after) if path in nodes]
        candidates=[node for node in candidates if node['identity']['device']==native[0] and node['identity']['inode']==native[1]]
        assert candidates, path
        assert all(node['kind']==handle['kind'] and node['uid']==uid for node in candidates)
        call=value['calls'][handle['opening_call']]
        created=(call['operation']=='sysopen' and call['flags']&flags['O_CREAT'] and call['flags']&flags['O_EXCL'])
        if created:
            assert path not in before and path in after
            assert stat.S_IMODE(native[2])==0o600 and native[3]==1 and native[7]==0
        else:
            assert any(node['mode']==stat.S_IMODE(native[2]) and (node['kind']=='directory' or
                (node['links']==native[3]==1 and node['identity']['size_bytes']==native[7])) for node in candidates)

