"""Re-derive the fixed inert run; altered evidence must fail before cleanup."""
import argparse
import copy
import json
import os
import subprocess
from pathlib import Path

from files import BASE, ROOT, PLAN, LOG, digest, save, census, roots, verify_pins


def read(path):
    return json.loads(path.read_bytes())


def canonical(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=True, separators=(',', ':')).encode('ascii')


def source_contract():
    path = 'docs/audits/native-proxy-runtime-retirement-20260910/PrivateWorkspace.pm'
    original = subprocess.check_output(['git', 'show', PLAN['source_revision'] + ':' + path], cwd=ROOT)
    assert original == (BASE / 'PrivateWorkspace.baseline.source').read_bytes()
    before = b'    my $mode = $metadata[2] & 07777;\n'
    comment = (b'    # T1669 writes this wrapper with 0755 inside its owned private workspace.\n'
               b'    # Keep the exception bound to that producer role, not every executable.\n'
               b'    my $generated_wrapper = $path =~ m{\\A\\.artifacts/tmp/process-supervisor-tests/\n'
               b'        fsmgen-[A-Za-z0-9_]+/rust-tool-resolution\\z}x;\n')
    guard = b'&& ($mode == 0400 || $mode == 0500 || $mode == 0600 || $mode == 0700);'
    expected = original.replace(before, before + comment).replace(guard,
        guard[:-2] + b'\n            || ($mode == 0755 && $generated_wrapper));')
    assert expected != original and (ROOT / path).read_bytes() == expected
    producer = (ROOT / 't/1669-task-acceptance-fixture-runtime.t').read_text()
    assert "my $probe = File::Spec->catfile($mode_workspace, 'rust-tool-resolution');" in producer
    assert "write_executable($probe, <<'PROBE');" in producer
    assert 'chmod 0755, $path' in producer
    return dict(baseline_sha256=digest(original), repaired_sha256=digest(expected),
                exact_guard_only=True, producer_mode='0755')


def verify(prepared, journal, post):
    nodes = prepared['nodes']
    assert prepared['absent'] == []
    sequence = []
    expected_paths = set()
    for case in PLAN['cases']:
        expected_paths.update([case['root'], case['path']])
        if str(Path(case['path']).parent) != case['root']:
            expected_paths.add(str(Path(case['path']).parent))
        if case['hardlink']:
            expected_paths.add(case['root'] + '/alias')
        n = nodes[case['path']]
        assert n['mode'] == case['mode'] and n['size_bytes'] == case['size']
        assert n['sha256'] == digest(b'w' * case['size']) and n['links'] == (2 if case['hardlink'] else 1)
        if case['hardlink']:
            assert n == nodes[case['root'] + '/alias']
        for version in ['baseline', 'repaired']:
            sequence.extend([('reader_intent', case['name'], version), ('reader_result', case['name'], version)])
    work, store = PLAN['workspace'], PLAN['store']
    initial_work = ['', '/rust-tool-resolution', '/rust-tools', '/rust-tools/compiler-cache',
                    '/rust-tools/compiler-cache/cache.dat', '/rust-tools/compiler-temp',
                    '/rust-tools/compiler-temp/scratch.dat', '/rust-tools/rustup.c', '/rust-tools/rustup']
    expected_paths.update(work + suffix for suffix in initial_work)
    expected_paths.update(store + suffix for suffix in ['', '/images', '/references', '/coordination.lock'])
    assert set(nodes) == expected_paths
    assert [(r['event'], r.get('case'), r.get('version')) for r in journal[:len(sequence)]] == sequence
    for case in PLAN['cases']:
        for version in ['baseline', 'repaired']:
            r = next(r for r in journal if r['event'] == 'reader_result' and r['case'] == case['name'] and r['version'] == version)
            accepted = case['accepted'] if version == 'repaired' else case['mode'] in [0o400, 0o500, 0o600, 0o700]
            assert r['accepted'] == int(accepted)
            if accepted:
                assert r['error'] == '' and r['result']['kind'] == 'file'
                assert r['result']['size_bytes'] == case['size']
                assert r['result']['identity'] == dict(path=case['path'], **{k: nodes[case['path']][k] for k in ['device','inode','uid','mode']})
            else:
                error = ('workspace node has shared links\n' if case['hardlink'] else
                         'fixture must be an owned bounded regular file\n' if case['name'] == 'overflow' and version == 'repaired' else
                         'workspace node is not a private regular file\n')
                assert r['error'] == error and r['result'] is None
    tail = journal[len(sequence):]
    assert [r['event'] for r in tail] == ['acquisition_intent', 'acquired', 'baseline_retirement_intent',
        'baseline_retirement', 'retirement_intent', 'retired', 'complete']
    acquired, before = tail[1]['acquired'], tail[1]['census']
    assert before['absent'] == []
    b = before['nodes']
    for p, n in nodes.items():
        assert b[p] == n
    assert acquired['schema'] == 'fsmgen.inactive_runtime_reference_acquisition.v1'
    assert acquired['runtime_authorized'] == 0 and acquired['executable'] is None and acquired['created'] == 1
    vectors = read(BASE.parent / 'native-proxy-image-custody-20260910/vectors.json')
    c, image = (bytes.fromhex(vectors[k]) for k in ['generated_c_hex', 'image_hex'])
    key = digest(b'fsmgen.rust_proxy_image.v1\0' + len(c).to_bytes(8, 'big') + c + len(image).to_bytes(8, 'big') + image)
    image_root = store + '/images/' + key
    manifest = canonical(dict(schema='fsmgen.test.rust_proxy_image.v1', key=key,
        generated_c=dict(size_bytes=len(c), sha256=digest(c)), executable=dict(size_bytes=len(image), sha256=digest(image))))
    snapshots = acquired['image']['snapshots']
    assert acquired['image']['key'] == key and len(snapshots) == 3
    for snapshot, name, raw, mode in zip(snapshots, ['rustup.c','rustup','image.json'], [c,image,manifest], [0o400,0o500,0o400]):
        p = image_root + '/' + name
        assert snapshot['bytes'].encode('latin1') == raw
        assert snapshot['identity'] == dict(path=p, device=b[p]['device'], inode=b[p]['inode'], size_bytes=len(raw), sha256=digest(raw))
        assert b[p]['mode'] == mode and b[p]['links'] == 1 and b[p]['sha256'] == digest(raw)
    for suffix, raw, mode in [('/rust-tool-resolution', b'inert wrapper; never executed', 0o755),
            ('/rust-tools/rustup.c', c, 0o400), ('/rust-tools/rustup', image, 0o500),
            ('/rust-tools/compiler-cache/cache.dat', b'inert cache', 0o400),
            ('/rust-tools/compiler-temp/scratch.dat', b'inert scratch', 0o600)]:
        n = b[work + suffix]
        assert n['sha256'] == digest(raw) and n['size_bytes'] == len(raw) and n['mode'] == mode and n['links'] == 1
    reference_key = digest(b'fsmgen.rust_proxy_reference.runtime.v1\0' + work.encode())
    record = dict(schema='fsmgen.test.rust_proxy_image_reference.v1', reference_key=reference_key, image_key=key,
        workspace=work, workspace_identity=dict(path=work, **{k:nodes[work][k] for k in ['device','inode']}),
        selected_sources=[s['identity'] for s in snapshots[:2]])
    assert acquired['reference']['record'] == record
    global_path = store + '/references/' + reference_key + '.json'
    private_path = work + '/rust-tools/image-reference.json'
    for kind, p in [('global',global_path), ('private',private_path)]:
        raw = canonical(record)
        s = acquired['reference'][kind]
        assert s['bytes'].encode('latin1') == raw
        assert s['identity'] == dict(path=p, device=b[p]['device'], inode=b[p]['inode'], size_bytes=len(raw), sha256=digest(raw))
        assert b[p]['sha256'] == digest(raw) and b[p]['mode'] == 0o400 and b[p]['links'] == 1
    assert set(b) - set(nodes) == {image_root, global_path, private_path, *[s['identity']['path'] for s in snapshots]}
    owner = dict(cleanup=dict(leader_started=1, leader_reaped=1, group_gone=1))
    receipts = dict(compiler=owner, outer=owner, stages=[owner,owner])
    assert tail[2]['synthetic_cleanup'] == tail[4]['synthetic_cleanup'] == receipts
    assert tail[3]['result'] is None and tail[3]['error'] == 'workspace node is not a private regular file\n'
    assert tail[3]['census'] == before
    removed = {p for p in b if p == work or p.startswith(work + '/')} | {global_path}
    expected_post = dict(nodes={p:n for p,n in b.items() if p not in removed}, absent=[work])
    assert tail[5]['census'] == post == expected_post
    result = tail[5]['result']
    assert result['retired_workspace'] == work and result['released_reference'] == global_path
    assert result['removed_nodes'] == len(removed) - 1 and result['image'] == acquired['image']
    assert result['runtime_authorized'] == 0 and result['executable'] is None
    assert tail[6]['forbidden_process_attempts'] == 0 and tail[6]['synthetic_cleanup_only'] == 1
    assert tail[6]['transferred_handles_closed'] > 0
    for table in [nodes, b, post['nodes']]:
        for p,n in table.items():
            assert n['device'] == nodes[work]['device'] and n['uid'] == nodes[work]['uid'] and n['inode'] > 0
            if n['kind'] == 'directory':
                assert n['mode'] == 0o700
    return dict(reader_profiles=len(PLAN['cases']), reader_calls=len(PLAN['cases'])*2,
        baseline_retirement_rejected_unchanged=True, repaired_retirement_removed_nodes=result['removed_nodes'],
        transferred_handles_closed=tail[6]['transferred_handles_closed'], synthetic_cleanup_only=True,
        actual_compiler_capacity_qualified=False, native_or_live_execution=False)


def controls(prepared, journal, post):
    rejected = []
    mutations = {
        'accept_near_name': lambda p,j,a: next(r for r in j if r['event']=='reader_result' and r['case']=='near' and r['version']=='repaired').update(accepted=1),
        'normalize_wrapper': lambda p,j,a: p['nodes'][PLAN['cases'][0]['path']].update(mode=0o700),
        'lost_alias': lambda p,j,a: p['nodes'][PLAN['cases'][-1]['path']].update(links=1),
        'lost_baseline_rejection': lambda p,j,a: next(r for r in j if r['event']=='baseline_retirement').update(error=''),
        'missing_inner_receipt': lambda p,j,a: next(r for r in j if r['event']=='retirement_intent')['synthetic_cleanup']['stages'].pop(),
        'native_authority': lambda p,j,a: next(r for r in j if r['event']=='acquired')['acquired'].update(runtime_authorized=1),
        'lost_result': lambda p,j,a: j.pop(),
        'lost_post_node': lambda p,j,a: a['nodes'].pop(next(iter(a['nodes']))),
    }
    for name, mutate in mutations.items():
        p,j,a = copy.deepcopy((prepared,journal,post))
        mutate(p,j,a)
        try:
            verify(p,j,a)
        except (AssertionError, KeyError, IndexError, StopIteration):
            rejected.append(name)
        else:
            raise AssertionError('accepted altered evidence: ' + name)
    return rejected


def cleanup(expected):
    assert census() == expected
    remaining = copy.deepcopy(expected['nodes'])
    path = LOG / 'cleanup.jsonl'
    with path.open('x') as stream:
        for p in sorted(remaining, key=lambda x:(len(Path(x).parts),x), reverse=True):
            assert census()['nodes'] == remaining
            n = remaining[p]
            stream.write(json.dumps(dict(event='intent', path=p, node=n), sort_keys=True)+'\n'); stream.flush(); os.fsync(stream.fileno())
            if n['kind'] == 'directory':
                (ROOT / p).rmdir()
            else:
                (ROOT / p).unlink()
            del remaining[p]
            for other in remaining.values():
                if other['kind']=='file' and (other['device'],other['inode']) == (n['device'],n['inode']):
                    other['links'] -= 1
            assert not os.path.lexists(ROOT / p)
            stream.write(json.dumps(dict(event='removed', path=p), sort_keys=True)+'\n'); stream.flush(); os.fsync(stream.fileno())
    final = census()
    assert final == dict(nodes={}, absent=roots())
    save(LOG / 'final-census.json', final)


def main():
    parser = argparse.ArgumentParser()
    g = parser.add_mutually_exclusive_group(required=True)
    g.add_argument('--review-and-clean', action='store_true')
    g.add_argument('--verify-saved', action='store_true')
    args = parser.parse_args()
    verify_pins()
    contract = source_contract()
    if args.review_and_clean:
        prepared = read(LOG/'prepared.json')
        journal = [json.loads(line) for line in (LOG/'qualification.jsonl').read_bytes().splitlines()]
        post = census()
        # Preserve first independent observation before any oracle assertion or deletion.
        save(LOG/'post-census.json', post)
        result = verify(prepared,journal,post)
        rejected = controls(prepared,journal,post)
        save(LOG/'review-before-cleanup.json', dict(result=result,rejected_controls=rejected))
        cleanup(post)
        raw = {}
        for name in ['allocation.jsonl','prepared.json','qualification.jsonl','post-census.json',
                     'review-before-cleanup.json','cleanup.jsonl','final-census.json',
                     'prepare.stdout','prepare.stderr','prepare.exit','qualify.stdout','qualify.stderr','qualify.exit']:
            body = (LOG/name).read_bytes()
            raw[name] = dict(size_bytes=len(body),sha256=digest(body),bytes_hex=body.hex())
        save(BASE/'first-run.json', raw)
        report = dict(source=contract,result=result,rejected_controls=rejected,
                      owned_roots_absent=len(roots()),raw_files=len(raw),first_run_sha256=digest((BASE/'first-run.json').read_bytes()))
        save(BASE/'review.json',report)
    else:
        saved = read(BASE/'first-run.json')
        raw = {}
        for name,row in saved.items():
            body = bytes.fromhex(row['bytes_hex'])
            assert len(body)==row['size_bytes'] and digest(body)==row['sha256']
            raw[name] = body
        for name in ['prepare','qualify']:
            assert raw[name+'.exit']==b'0\n'
        prepared = json.loads(raw['prepared.json'])
        journal = [json.loads(line) for line in raw['qualification.jsonl'].splitlines()]
        post = json.loads(raw['post-census.json'])
        result = verify(prepared,journal,post)
        rejected = controls(prepared,journal,post)
        final = json.loads(raw['final-census.json'])
        assert final == dict(nodes={},absent=roots())
        rows = [json.loads(line) for line in raw['cleanup.jsonl'].splitlines()]
        remaining = copy.deepcopy(post['nodes'])
        for intent,done in zip(rows[::2],rows[1::2]):
            p = intent['path']; n = remaining.pop(p)
            assert intent == dict(event='intent',path=p,node=n) and done == dict(event='removed',path=p)
            for other in remaining.values():
                if other['kind']=='file' and (other['device'],other['inode']) == (n['device'],n['inode']):
                    other['links'] -= 1
        assert not remaining and len(rows)%2==0
        report = read(BASE/'review.json')
        assert report == dict(source=contract,result=result,rejected_controls=rejected,
            owned_roots_absent=len(roots()),raw_files=len(raw),first_run_sha256=digest((BASE/'first-run.json').read_bytes()))
    print(json.dumps(report['result'],sort_keys=True))


if __name__ == '__main__':
    main()
