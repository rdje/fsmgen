"""Pure physical-layout oracle; synthetic metadata is never a native observation."""
from __future__ import annotations

import copy
import hashlib

from support import OLD_COMMON, OLD_MODEL, canonical


def directory(path, inode):
    return dict(kind='directory', mode=0o700, uid=501,
                identity=dict(path=path, device=1, inode=inode),
                native=[1, inode, 0o40700, 2, 501, 501, 0, 0, 0, 0, 0, 4096, 0])


def file_node(snapshot, mode):
    identity = snapshot['identity']
    data = bytes.fromhex(snapshot['bytes_hex'])
    assert len(data) == identity['size_bytes'] and hashlib.sha256(data).hexdigest() == identity['sha256']
    native = [identity['device'], identity['inode'], 0o100000 | mode, 1, 501, 501, 0, len(data), 0, 0, 0, 4096, 1]
    return dict(kind='file', mode=mode, uid=501, links=1, bytes_hex=data.hex(), identity=copy.deepcopy(identity),
                native_before=native, native_after=list(native))


def snapshot(path, inode, body):
    return dict(bytes_hex=body.hex(), identity=dict(path=path, device=1, inode=inode,
                size_bytes=len(body), sha256=hashlib.sha256(body).hexdigest()))


def manifest(key, pair):
    return canonical(dict(schema='fsmgen.test.rust_proxy_image.v1', key=key,
                          generated_c={name: pair[0]['identity'][name] for name in ('size_bytes', 'sha256')},
                          executable={name: pair[1]['identity'][name] for name in ('size_bytes', 'sha256')}))


def catalog(seed):
    """Construct explicit hypothetical metadata, using the qualified inert seed."""
    case = seed['observers']['a']['case']
    evidence = seed['observers']['a']['request']['evidence_directory_identity']['path']
    result = {case: directory(case, 1000), case + '/images': directory(case + '/images', 1001),
              case + '/references': directory(case + '/references', 1002), evidence: directory(evidence, 3)}
    lock = case + '/coordination.lock'
    result[lock] = file_node(snapshot(lock, 4, b''), 0o600)
    for index, (key, pair) in enumerate(sorted(seed['images'].items())):
        base = case + '/images/' + key
        result[base] = directory(base, 1010 + index)
        for source, mode in zip(pair, (0o400, 0o500), strict=True):
            result[source['identity']['path']] = file_node(source, mode)
        path = base + '/image.json'
        result[path] = file_node(snapshot(path, 1020 + index, manifest(key, pair)), 0o400)
    for index, runtime in enumerate(seed['runtimes'].values()):
        path = runtime['directory']['path']
        result[path] = directory(path, runtime['directory']['inode'])
        result[path + '/rust-tools'] = directory(path + '/rust-tools', 1030 + index)
        for source, mode in zip(runtime['private'], (0o700, 0o400), strict=True):
            result[source['identity']['path']] = file_node(source, mode)
        source = runtime['source']; result[source['identity']['path']] = file_node(source, 0o400)
    for value in seed['observers'].values():
        hold = value['acquired']['observation_reference']['source']
        result[hold['identity']['path']] = file_node(hold, 0o400)
    value = seed['observers']['a']
    result[value['directory']['path']] = directory(value['directory']['path'], value['directory']['inode'])
    for source in value['snapshots']:
        result[source['identity']['path']] = file_node(source, 0o400)
    identities = [(node['identity']['device'], node['identity']['inode']) for node in result.values()]
    assert len(identities) == len(set(identities)), 'synthetic objects unexpectedly alias'
    return result


def physical_projection(seed, state, objects):
    """Build occupied paths FROM current modeled owners, without removing events."""
    value = seed['observers']['a']
    case = value['case']; evidence = value['request']['evidence_directory_identity']['path']
    paths = {case, case + '/images', case + '/references', case + '/coordination.lock', evidence}
    for key, pair in state['images'].items():
        paths.add(case + '/images/' + key)
        paths.update(source['identity']['path'] for source in pair)
        paths.add(case + '/images/' + key + '/image.json')
    for name, identity in state['workspaces'].items():
        paths.update((identity['path'], identity['path'] + '/rust-tools'))
        paths.update(source['identity']['path'] for source in state['private'][name])
    paths.update(hold['source']['identity']['path'] for hold in state['references'].values())
    if state['archives']:
        paths.add(value['directory']['path'])
        paths.update(source['identity']['path'] for source in value['snapshots'])
    return {path: copy.deepcopy(objects[path]) for path in sorted(paths)}


def stable(nodes):
    return {path: {key: copy.deepcopy(value) for key, value in node.items()
                   if key not in ('native', 'native_before', 'native_after')} for path, node in nodes.items()}


def snapshot_document(nodes, roots):
    return dict(nodes=nodes, absent_roots=[path for path in roots if path not in nodes],
                file_bytes=sum(node['identity']['size_bytes'] for node in nodes.values() if node['kind'] == 'file'))


def context(seed, objects):
    value = seed['observers']['a']
    paths = dict(store=value['case'], target=seed['runtimes']['target']['directory']['path'],
                 other=seed['runtimes']['other']['directory']['path'], evidence=value['directory']['path'].rsplit('/', 1)[0])
    roots = [paths[key] for key in ('store', 'target', 'other', 'evidence')]
    initial = snapshot_document(physical_projection(seed, OLD_MODEL.initial(seed), objects), roots)
    runtimes = {}
    for name, runtime in seed['runtimes'].items():
        key = runtime['record']['image_key']; pair = seed['images'][key]
        entry = objects[paths['store'] + '/images/' + key + '/image.json']
        manifest_snapshot = dict(identity=entry['identity'], bytes_hex=entry['bytes_hex'])
        runtimes[name] = dict(schema='fsmgen.inactive_runtime_reference_acquisition.v1', runtime_authorized=0,
            executable=None, lock=copy.deepcopy(value['acquired']['lock']),
            created=int(name == 'target' or seed['profile'] == 'different_image'),
            reference=dict(record=copy.deepcopy(runtime['record']), global_=copy.deepcopy(runtime['source']),
                           private=copy.deepcopy(runtime['private'][1])),
            image=dict(key=key, snapshots=copy.deepcopy(pair + [manifest_snapshot])))
        runtimes[name]['reference']['global'] = runtimes[name]['reference'].pop('global_')
    return dict(name='synthetic_' + seed['profile'], profile=seed['profile'], paths=paths, roots=roots,
                directories={name: copy.deepcopy(objects[path]['identity']) for name, path in paths.items()},
                runtimes=runtimes, observations={name: copy.deepcopy(row['acquired']) for name, row in seed['observers'].items()},
                requests={name: copy.deepcopy(row['request']) for name, row in seed['observers'].items()},
                selections={name: copy.deepcopy(row['selection']) for name, row in seed['observers'].items()},
                settlements={name: copy.deepcopy(row['settlement']) for name, row in seed['observers'].items()},
                archives={}, completed={}, initial=initial, current=copy.deepcopy(initial))
