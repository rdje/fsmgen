"""Independent fixed-payload and retained-record checks for the populated driver."""
import hashlib
import json
import re
import struct

from contract import CONTRACT, canonical


def fields(value, expected):
    if not isinstance(value, dict) or set(value) != set(expected.split()):
        raise ValueError('record has unexpected fields')


def integer(value):
    if type(value) is not int or not 0 <= value <= 9223372036854775807:
        raise ValueError('expected bounded nonnegative integer')
    return value


def digest(value):
    if not isinstance(value, str) or re.fullmatch('[0-9a-f]{64}', value) is None:
        raise ValueError('expected canonical SHA-256')
    return value


def octets(value, limit=65536):
    if not isinstance(value, str) or len(value) > limit * 2 or re.fullmatch('(?:[0-9a-f]{2})*', value) is None:
        raise ValueError('expected bounded lowercase octet hex')
    return bytes.fromhex(value)


def image_key(c, image):
    return hashlib.sha256(b'fsmgen.rust_proxy_image.v1\0' + struct.pack('>Q', len(c)) + c
                          + struct.pack('>Q', len(image)) + image).hexdigest()


def file_pin(body):
    return dict(size_bytes=len(body), sha256=hashlib.sha256(body).hexdigest())


def payload(kind):
    if kind not in ('a', 'b'):
        raise ValueError('undeclared image payload')
    c = octets(CONTRACT['payloads']['c_hex'])
    image = octets(CONTRACT['payloads']['image_' + kind + '_hex'])
    key = image_key(c, image)
    manifest = canonical(dict(schema='fsmgen.test.rust_proxy_image.v1', key=key,
                              generated_c=file_pin(c), executable=file_pin(image)))
    return dict(key=key, sources={'rustup.c': c, 'rustup': image, 'image.json': manifest})


def runtime_key(workspace):
    return hashlib.sha256(b'fsmgen.rust_proxy_reference.runtime.v1\0' + workspace.encode('utf-8')).hexdigest()


def observation_key(evidence, observer, target):
    return hashlib.sha256(b'fsmgen.rust_proxy_reference.observation.v1\0'
                          + canonical([evidence, observer, target])).hexdigest()


def directory(value, expected):
    fields(value, 'path device inode')
    integer(value['device'])
    integer(value['inode'])
    if value != expected:
        raise ValueError('directory identity differs from activation')


def snapshot(value, path, device, body=None):
    fields(value, 'bytes_hex identity')
    observed = octets(value['bytes_hex'])
    identity = value['identity']
    fields(identity, 'path device inode size_bytes sha256')
    for field in ('device', 'inode', 'size_bytes'):
        integer(identity[field])
    digest(identity['sha256'])
    if identity['path'] != path or identity['device'] != device or file_pin(observed) != {
            key: identity[key] for key in ('size_bytes', 'sha256')} or (body is not None and observed != body):
        raise ValueError('retained snapshot bytes, path or identity differ')
    return observed


def lock(value, expected):
    directory(value, expected)


def inactive(value, schema):
    if value['schema'] != schema or type(value['runtime_authorized']) is not int or value['runtime_authorized'] != 0 or value['executable'] is not None:
        raise ValueError('record grants unexpected execution authority')


def runtime(case, activation, role, value, permanent_lock):
    fields(value, 'schema runtime_authorized executable lock reference created image')
    inactive(value, 'fsmgen.inactive_runtime_reference_acquisition.v1')
    lock(value['lock'], permanent_lock)
    if integer(value['created']) not in (0, 1):
        raise ValueError('invalid creation flag')
    expected = payload(case['roles'][role]['image'])
    image = value['image']
    fields(image, 'key snapshots')
    if image['key'] != expected['key'] or not isinstance(image['snapshots'], list) or len(image['snapshots']) != 3:
        raise ValueError('acquired image selection differs')
    store, device = case['store'], activation['store']['device']
    for source, name in zip(image['snapshots'], ('rustup.c', 'rustup', 'image.json')):
        snapshot(source, store + '/images/' + image['key'] + '/' + name, device, expected['sources'][name])
    reference = value['reference']
    fields(reference, 'record global private')
    workspace = activation['workspaces'][role]
    record = dict(schema='fsmgen.test.rust_proxy_image_reference.v1', reference_key=runtime_key(workspace['path']),
        image_key=image['key'], workspace=workspace['path'], workspace_identity=workspace,
        selected_sources=[source['identity'] for source in image['snapshots'][:2]])
    if reference['record'] != record:
        raise ValueError('runtime reference differs from original activation and image')
    raw = canonical(record)
    snapshot(reference['global'], store + '/references/' + record['reference_key'] + '.json', device, raw)
    snapshot(reference['private'], workspace['path'] + '/rust-tools/image-reference.json', device, raw)
    return value


def observation(case, activation, value, permanent_lock, target_runtime):
    fields(value, 'schema runtime_authorized executable lock observation_reference target_sources')
    inactive(value, 'fsmgen.inactive_observation_acquisition.v1')
    lock(value['lock'], permanent_lock)
    target = case['observation_target']
    workspace, evidence = activation['workspaces'][target], activation['evidence']
    observer, target_birth = activation['births']['observer'], activation['births'][target]
    hold = value['observation_reference']
    fields(hold, 'record source')
    record = dict(schema='fsmgen.test.rust_proxy_image_observation_reference.v1',
        reference_key=observation_key(evidence['path'], observer, target_birth), image_key=target_runtime['image']['key'],
        evidence_directory=evidence['path'], evidence_directory_identity=evidence,
        observer_birth=observer, target_birth=target_birth,
        selected_sources=target_runtime['reference']['record']['selected_sources'])
    if hold['record'] != record:
        raise ValueError('observation reference differs from original native ownership')
    snapshot(hold['source'], case['store'] + '/references/' + record['reference_key'] + '.json', evidence['device'], canonical(record))
    sources = value['target_sources']
    if not isinstance(sources, list) or len(sources) != 5:
        raise ValueError('observation lacks its original source set')
    wrapper = octets(CONTRACT['payloads']['wrapper_hex'])
    snapshot(sources[0], workspace['path'] + '/rust-tool-resolution', evidence['device'], wrapper)
    if sources[1:] != [target_runtime['reference']['private'], target_runtime['reference']['global'], *target_runtime['image']['snapshots'][:2]]:
        raise ValueError('observation replaced the original reference or image snapshots')
    return value


def archive_sources(acquired):
    """Return the exact unique digest-to-octet archive, preserving duplicate roles."""
    result = {}
    for source in acquired['target_sources']:
        body = octets(source['bytes_hex'])
        key = digest(source['identity']['sha256'])
        if hashlib.sha256(body).hexdigest() != key or (key in result and result[key] != body):
            raise ValueError('archive digest does not bind original bytes')
        result[key] = body
    return result
