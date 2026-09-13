"""Join native opens to observed objects and their recorded mode/length history.

Descriptor ownership and closure retain the original qualified reader. This
module corrects only identity validation across exclusive publication and seal.
"""
import stat
from resources import resources

CREATION_MODES = {
    'NativeProxyLifetimeFiles': 0o600,
    'NativeProxyImageCoordination': 0o600,
    'NativeProxyImagePublication': 0o400,
}


def opened_identities(value, before, after, uid, device, flags):
    states = {path: dict(kind=node['kind'], mode=node['mode'],
                        size=node['identity'].get('size_bytes')) for path, node in before.items()}
    writers = {}
    for call in value['calls']:
        operation = call['operation']
        if operation in ('sysopen', 'opendir') and call['returned']:
            handle = value['handles'][call['handle']]
            path = handle['path']; native = handle['native_at_open']
            assert len(native) == 13 and native[0] == device and native[4] == uid
            assert stat.S_ISDIR(native[2]) if handle['kind'] == 'directory' else stat.S_ISREG(native[2])
            candidates = [nodes[path] for nodes in (before, after) if path in nodes]
            assert any(node['identity']['device'] == native[0] and node['identity']['inode'] == native[1]
                       and node['kind'] == handle['kind'] and node['uid'] == uid for node in candidates)
            created = operation == 'sysopen' and call['flags'] & flags['O_CREAT'] and call['flags'] & flags['O_EXCL']
            if created:
                assert path not in before and path not in states and path in after
                assert call['caller'] in CREATION_MODES
                states[path] = dict(kind='file', mode=CREATION_MODES[call['caller']], size=0)
                writers[call['handle']] = path
            state = states[path]
            assert state['kind'] == handle['kind'] and stat.S_IMODE(native[2]) == state['mode']
            if state['kind'] == 'file': assert native[3] == 1 and native[7] == state['size']
        elif operation == 'mkdir' and call['returned']:
            path = call['path']; native = call['native_after']
            assert path not in states and path in after
            assert native[:2] == [after[path]['identity']['device'], after[path]['identity']['inode']]
            assert native[4] == uid and stat.S_ISDIR(native[2]) and stat.S_IMODE(native[2]) == 0o700
            states[path] = dict(kind='directory', mode=0o700, size=None)
        elif operation == 'syswrite':
            assert call['handle'] in writers and 0 < call['returned'] <= call['requested']
            states[writers[call['handle']]]['size'] += call['returned']
        elif operation == 'chmod':
            assert call['returned'] == len(call['targets']) and call['mode'] in (0o400, 0o500, 0o600, 0o700)
            for target in call['targets']:
                path = target['path'] if 'path' in target else value['handles'][target['handle']]['path']
                assert states[path]['kind'] == 'file'
                states[path]['mode'] = call['mode']
        elif operation in ('unlink', 'rmdir'):
            paths = call['paths'] if operation == 'unlink' else [call['path']]
            assert call['returned'] == len(paths)
            for path in paths: del states[path]
    assert set(states) == set(after)
    for path, state in states.items():
        node = after[path]
        assert state == dict(kind=node['kind'], mode=node['mode'], size=node['identity'].get('size_bytes'))
