"""Verify retained actual compiler profiles without launching or allocating anything."""
import argparse
import copy
import hashlib
import json
import os
from pathlib import Path
import re
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
ADMISSION = BASE.parent / 'native-proxy-compiler-census-policy-admission-20260913'
sys.path.insert(0, str(ADMISSION))
import admission
import review_profile

PLAN = admission.PLAN
REVISION = '25a4a19646e1786d854d826ae11958ca4f495ae6'


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def read(name):
    return json.loads((BASE / name).read_bytes())


def pin(path):
    raw = path.read_bytes()
    return dict(path=str(path.relative_to(ROOT)), size_bytes=len(raw), sha256=digest(raw))


def cleanup_check(rows, nodes):
    position = 0
    removed = 0
    for case in PLAN['cases']:
        root = case['workspace']
        remaining = copy.deepcopy(nodes[root])
        # The initial capture fixes this selected filesystem's directory counts.
        # Every subsequent recorded remaining-map digest must independently agree
        # with removing exactly one direct child at each step.
        for path, node in remaining.items():
            if node['kind'] == 'directory':
                children = sum(str(Path(p).parent) == path for p in remaining if p != path)
                assert node['links'] == children + 2
        for path in sorted(remaining, key=lambda p: (p.count('/'), p), reverse=True):
            intent, done = rows[position:position + 2]
            position += 2
            assert set(intent) == {'event', 'path', 'node', 'remaining_sha256'}
            assert intent['event'] == 'remove_intent' and intent['path'] == path
            assert intent['node'] == nodes[root][path]
            assert intent['remaining_sha256'] == digest(json.dumps(remaining, sort_keys=True).encode())
            del remaining[path]
            parent = str(Path(path).parent)
            if parent in remaining:
                assert remaining[parent]['kind'] == 'directory'
                remaining[parent]['links'] -= 1
            assert done == dict(event='removed', path=path, remaining_nodes=len(remaining))
            removed += 1
        assert rows[position] == dict(event='root_absent', path=root)
        position += 1
    assert position == len(rows)
    return removed


def validate(data):
    outer = data['outer']
    for stage in ['issuer', 'runner', 'review']:
        assert outer[stage + '.exit'] == b'0\n'
    assert outer['runner.stdout'] == b''
    inner = data['inner']
    assert inner['runner.exit'] == b'0\n' and inner['runner.stderr'] == b''
    issuer = json.loads(outer['issuer.stdout'])
    assert issuer == dict(action='emit', admission_revision=REVISION, compiler_invocations=0, qualified=True)
    assert json.loads(inner['runner.stdout']) == dict(issuer, action='check-run')
    permit = json.loads(inner['permit.json'])
    admission.validate_permit(permit, admission.expected_permit(REVISION, digest((ADMISSION / 'implementation-pins.json').read_bytes())))
    start = json.loads(inner['run-start.json'])
    assert start['permit'] == permit and start['uid'] == PLAN['normal_user']['uid'] and start['pid'] > 0
    epoch = json.loads(inner['epoch-before.json'])
    assert epoch == json.loads((ADMISSION / 'installed-inputs-first.json').read_bytes())['inputs']
    independent = json.loads(inner['independent-first.json'])
    assert independent['epoch_after'] == epoch
    assert independent['journal_sha256'] == digest(inner['journal.jsonl'])
    journal = [json.loads(line) for line in inner['journal.jsonl'].splitlines()]
    result = review_profile.validate(journal, independent['nodes'])
    assert json.loads(inner['accepted-profile.json']) == json.loads(outer['review.stdout']) == result
    # Re-derive full file totals from the retained original byte captures as a
    # separate check of the independent node-map statistics.
    totals = []
    for case in result['cases']:
        final = next(r for r in journal if r['event'] == 'complete_profile' and r['workspace'] == case['workspace'])
        files = [n for n in final['capture']['nodes'] if n['kind'] == 'file']
        sizes = [len(n['bytes'].encode('latin1')) for n in files]
        assert sum(sizes) == case['profile']['file_bytes']
        assert max(sizes) == case['profile']['maximum_file_bytes']
        totals.append(sum(sizes))
    cleanup = [json.loads(line) for line in inner['cleanup.jsonl'].splitlines()]
    removed = cleanup_check(cleanup, independent['nodes'])
    reviewed = json.loads(inner['reviewed.json'])
    assert reviewed == dict(result=result, roots_absent=True,
        journal_sha256=digest(inner['journal.jsonl']), cleanup_sha256=digest(inner['cleanup.jsonl']))
    return dict(result=result, journal_events=len(journal), cleanup_events=len(cleanup),
                removed_nodes=removed, rederived_file_bytes=totals,
                complete_remaining_map_hashes_verified=removed)


def verify():
    manifest = read('first-results.json')
    assert manifest['admission_revision'] == REVISION
    source_pins = read('source-pins.json')
    for row in source_pins:
        raw = (ROOT / row['path']).read_bytes()
        assert pin(ROOT / row['path']) == row
        assert admission.git('show', REVISION + ':' + row['path']) == raw
    data = dict(inner={}, outer={})
    for row in manifest['files']:
        path = ROOT / row['path']
        assert path.parent.parent == BASE / 'first-results'
        assert pin(path) == {k: row[k] for k in ['path', 'size_bytes', 'sha256']}
        group = path.parent.name
        assert group in data and path.name not in data[group]
        data[group][path.name] = path.read_bytes()
    assert set(data['inner']) == {'accepted-profile.json', 'cleanup.jsonl', 'epoch-before.json',
        'independent-first.json', 'journal.jsonl', 'permit.json', 'reviewed.json', 'run-start.json',
        'runner.exit', 'runner.stderr', 'runner.stdout'}
    assert set(data['outer']) == {stage + '.' + ext for stage in ['issuer', 'runner', 'review']
                                 for ext in ['stdout', 'stderr', 'exit']}
    result = validate(data)
    rejected = []

    def reject(name, mutate):
        altered = copy.deepcopy(data)
        mutate(altered)
        try:
            validate(altered)
        except (AssertionError, ValueError, KeyError, IndexError):
            rejected.append(name)
        else:
            raise AssertionError('altered actual evidence accepted: ' + name)

    def edit_json(data, name, mutate):
        value = json.loads(data['inner'][name]); mutate(value)
        data['inner'][name] = json.dumps(value).encode()

    def edit_rows(data, name, mutate):
        value = [json.loads(line) for line in data['inner'][name].splitlines()]; mutate(value)
        data['inner'][name] = b''.join(json.dumps(r).encode() + b'\n' for r in value)

    reject('outer_runner_failure', lambda d: d['outer'].__setitem__('runner.exit', b'1\n'))
    reject('inner_error_output', lambda d: d['inner'].__setitem__('runner.stderr', b'failure\n'))
    reject('permit_revision', lambda d: edit_json(d, 'permit.json', lambda v: v.__setitem__('admission_revision', '0' * 40)))
    reject('installed_epoch', lambda d: edit_json(d, 'epoch-before.json', lambda v: v['git_launcher'].__setitem__('sha256', '0' * 64)))
    root = PLAN['cases'][0]['workspace']
    reject('missing_independent_node', lambda d: edit_json(d, 'independent-first.json', lambda v: v['nodes'][root].pop(root + '/rust-tools/rustup')))
    reject('changed_image_size', lambda d: edit_json(d, 'independent-first.json', lambda v: v['nodes'][root][root + '/rust-tools/rustup'].__setitem__('size_bytes', 1)))
    reject('omitted_cleanup', lambda d: edit_rows(d, 'cleanup.jsonl', lambda v: v.pop()))
    reject('changed_remaining_map_hash', lambda d: edit_rows(d, 'cleanup.jsonl', lambda v: v[0].__setitem__('remaining_sha256', '0' * 64)))
    reject('cleanup_foreign_path', lambda d: edit_rows(d, 'cleanup.jsonl', lambda v: v[0].__setitem__('path', 'unowned')))
    reject('cleanup_remaining_count', lambda d: edit_rows(d, 'cleanup.jsonl', lambda v: v[1].__setitem__('remaining_nodes', 999)))
    reject('hidden_root_residue', lambda d: edit_json(d, 'reviewed.json', lambda v: v.__setitem__('roots_absent', False)))
    assert all(manifest['roots_absent'].values())
    assert set(manifest['roots_absent']) == {c['workspace'] for c in PLAN['cases']}
    assert all(not os.path.lexists(ROOT / path) for path in manifest['roots_absent'])
    return dict(admission_revision=REVISION, source_pins=len(source_pins),
                retained_files=len(manifest['files']), retained_bytes=sum(r['size_bytes'] for r in manifest['files']),
                **result, rejected_controls=rejected, roots_absent=True,
                claim_legs=dict(rederive='Original full bytes, independent node maps, original compiler settlement and every remaining-map digest.',
                                falsify='Altered actual permit, epoch, output, membership, image and cleanup evidence.',
                                durability='Exact first inner and outer bytes plus immutable admission source pins retained in Git.'),
                limits='Selected compiler workspaces and unexecuted controlled roles only; native/live, loaded-image receipt binding and startup qualification remain open.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--verify-saved', required=True, action='store_true')
    parser.parse_args()
    result = verify()
    print(json.dumps(result, sort_keys=True))
