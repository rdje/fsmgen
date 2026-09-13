"""Pinned inert inputs and record oracles; importing runs no prior qualifier."""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-lifetime-model-20260913'
CONTRACT = 'docs/audits/native-proxy-lifetime-contracts-20260913'
WORK = 'docs/audits/native-proxy-observation-work-records-20260911'
ARCHIVE = 'docs/audits/native-proxy-observation-archive-records-20260911'


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, ROOT / path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


archive = load('lifetime_original_archive', ARCHIVE + '/audit.py')
work = load('lifetime_original_work', WORK + '/audit.py')


def raw(value):
    return json.dumps(value, ensure_ascii=True, sort_keys=True, separators=(',', ':')).encode('ascii')


def digest(value):
    return hashlib.sha256(raw(value)).hexdigest()


def write(path, value):
    with path.open('xb') as handle:
        handle.write(json.dumps(value, ensure_ascii=True, sort_keys=True, indent=2).encode() + b'\n')


def document(path):
    return json.loads(path.read_bytes())


def pin(path):
    data = (ROOT / path).read_bytes()
    return dict(path=path, size_bytes=len(data), sha256=hashlib.sha256(data).hexdigest())


def authenticate(plan, pins):
    for row in plan['inputs'] + pins:
        assert pin(row['path']) == row, row['path']
    for row in plan['inputs']:
        saved = subprocess.check_output(['git', 'show', plan['source_revision'] + ':' + row['path']], cwd=ROOT)
        assert saved == (ROOT / row['path']).read_bytes(), row['path']


def identity(path, inode):
    return dict(path=path, device=1, inode=inode)


def snapshot(path, inode, data):
    return dict(bytes_hex=data.hex(), identity=dict(identity(path, inode), size_bytes=len(data),
                sha256=hashlib.sha256(data).hexdigest()))


def image_key(c, image):
    return hashlib.sha256(b'fsmgen.rust_proxy_image.v1\0' + len(c).to_bytes(8, 'big') + c
                          + len(image).to_bytes(8, 'big') + image).hexdigest()


def settled_owner(outcome='completed'):
    return dict(outcome=outcome, cleanup=dict(leader_started=1, leader_reaped=1, group_gone=1))


def seed(profile):
    """New synthetic identities, never filesystem observations or native payloads."""
    original = document(ROOT / WORK / 'plan.json')['contexts'][0]
    old = original['acquired']['target_sources']
    c, image = [bytes.fromhex(item['bytes_hex']) for item in old[3:]]
    case = '.artifacts/tmp/native-proxy-image-custody/cases/fsmgen-LifetimeModel'
    evidence = identity('.artifacts/logs/native-proxy-observation-acquisition-20260910/cases/fsmgen-LifetimeEvidence', 3)
    lock = identity(case + '/coordination.lock', 4)
    keys = [image_key(c, image), image_key(c, image + b'\0lifetime-other')]
    images = {}
    for index in range(1 if profile == 'same_image' else 2):
        prefix = case + '/images/' + keys[index]
        images[keys[index]] = [snapshot(prefix + '/rustup.c', 10 + index * 2, c),
                              snapshot(prefix + '/rustup', 11 + index * 2,
                                       image + (b'\0lifetime-other' if index else b''))]
    runtimes = {}
    for index, label in enumerate(('target', 'other')):
        workspace = '.artifacts/tmp/process-supervisor-tests/fsmgen-Lifetime' + label.title()
        directory = identity(workspace, 1 + index)
        key = keys[1 if index and profile == 'different_image' else 0]
        record = dict(schema='fsmgen.test.rust_proxy_image_reference.v1',
                      reference_key=hashlib.sha256(b'fsmgen.rust_proxy_reference.runtime.v1\0' + workspace.encode()).hexdigest(),
                      image_key=key, workspace=workspace, workspace_identity=directory,
                      selected_sources=[copy.deepcopy(x['identity']) for x in images[key]])
        data = raw(record)
        runtimes[label] = dict(record=record, source=snapshot(case + '/references/' + record['reference_key'] + '.json', 20 + index, data),
            private=[snapshot(workspace + '/rust-tool-resolution', 30 + index * 2, bytes.fromhex(old[0]['bytes_hex'])),
                     snapshot(workspace + '/rust-tools/image-reference.json', 31 + index * 2, data)],
            cleanup=[settled_owner(), settled_owner(), [settled_owner()]], directory=directory)
    runtime = runtimes['target']
    target_sources = runtime['private'] + [runtime['source']] + images[keys[0]]
    observers = {}
    for index, label in enumerate(('a', 'b')):
        observer = dict(pid=101 + index, ppid=100, uid=501, ruid=501, start_sec=123, start_usec=456 + index)
        target = dict(pid=201, ppid=200, uid=501, ruid=501, start_sec=124, start_usec=789)
        request = dict(workspace_identity=copy.deepcopy(runtime['directory']), evidence_directory_identity=copy.deepcopy(evidence),
                       observer_birth=observer, target_birth=target)
        reference_key = hashlib.sha256(b'fsmgen.rust_proxy_reference.observation.v1\0'
                                       + raw([evidence['path'], observer, target])).hexdigest()
        record = dict(schema='fsmgen.test.rust_proxy_image_observation_reference.v1', reference_key=reference_key,
                      image_key=keys[0], evidence_directory=evidence['path'], evidence_directory_identity=copy.deepcopy(evidence),
                      observer_birth=copy.deepcopy(observer), target_birth=copy.deepcopy(target),
                      selected_sources=[copy.deepcopy(x['identity']) for x in images[keys[0]]])
        acquired = dict(schema='fsmgen.inactive_observation_acquisition.v1', runtime_authorized=0, executable=None,
                        lock=copy.deepcopy(lock), observation_reference=dict(record=record,
                        source=snapshot(case + '/references/' + reference_key + '.json', 40 + index, raw(record))),
                        target_sources=copy.deepcopy(target_sources))
        value = dict(case=case, request=request, acquired=acquired)
        specification = archive.specification(value)
        value['directory'] = identity(specification['archive_directory'], 50)
        value['snapshots'] = [snapshot(row['path'], 51 + number, bytes.fromhex(row['bytes_hex']))
                              for number, row in enumerate(specification['files'])]
        value['archive'] = archive.from_snapshots(value)
        value['entries'] = [dict(work_id=label + ':' + role, role=role,
                           ownership_token=hashlib.sha256(('lifetime:' + label + ':' + role).encode()).hexdigest())
                            for role in ('capture', 'helper', 'query')]
        value['selection'] = work.create_selection(value)
        value['receipts'] = [dict(entry, **settled_owner(outcome)) for entry, outcome in
                             zip(value['entries'], ('completed', 'failed', 'cancelled'), strict=True)]
        value['sealed'] = 1
        value['settlement'] = work.create_settlement(value)
        observers[label] = value
    return dict(profile=profile, identity_origin='synthetic_model_only', images=images, runtimes=runtimes,
                observers=observers, target_image=keys[0], other_image=runtimes['other']['record']['image_key'])
