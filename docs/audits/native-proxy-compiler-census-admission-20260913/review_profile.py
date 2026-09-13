"""Independent compiler-profile review and exact, successful-case-only cleanup."""
import argparse
import copy
import hashlib
import json
import os
from pathlib import Path

import admission
import profile_files as files

BASE, ROOT, PLAN, OUTPUT = admission.BASE, admission.ROOT, admission.PLAN, admission.OUTPUT


def projection(nodes):
    result = []
    for node in nodes:
        row = copy.deepcopy(node)
        if row['kind'] == 'file':
            raw = row.pop('bytes').encode('latin1')
            row.update(size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
        result.append(row)
    return result


def compiler_receipt(receipt):
    assert receipt['state_observed'] == receipt['settled'] == receipt['leader_reaped'] == 1
    assert receipt['original_result_equal'] == receipt['raw_result_equal'] == 1
    assert receipt['phase'] == 'finished' and type(receipt['pid']) is int and receipt['pid'] > 0
    assert receipt['native_wait_status'] == 0
    result = receipt['result']
    assert result['schema'] == 'fsmgen.test.rust_proxy_compilation.v1' and result['stage'] == 'compile_proxy'
    assert result['ok'] == 1 and result['status'] == 'success' and result['exit_code'] == result['signal'] == 0
    assert result['timeout_seconds'] == 10 and result['capture_limit_bytes'] == 4096
    assert not any(result[k] for k in ['timed_out', 'output_limited', 'exec_failed'])
    assert result['started_monotonic_ns'] <= result['exec_handoff_monotonic_ns'] <= result['finished_monotonic_ns']
    for channel in ['stdout', 'stderr']:
        assert len(result[channel].encode('latin1')) == result[channel + '_bytes'] <= 4096
    cleanup = result['cleanup']
    assert cleanup['containment'] == 'rust_proxy_compiler_group'
    assert cleanup['leader_started'] == cleanup['leader_reaped'] == cleanup['group_gone'] == 1
    assert cleanup['surviving_descendants'] == 0
    return result


def validate(rows, independent):
    events = ['start'] + ['workspace_intent', 'workspace_owned', 'before_compiler', 'compiler_settled',
        'prepared', 'compiler_profile', 'controlled_roles_intent', 'complete_profile'] * 2 + ['finished']
    assert [r['event'] for r in rows] == events
    assert [r['sequence'] for r in rows] == list(range(1, len(events) + 1))
    assert rows[0]['selection'] == PLAN['selection'] and rows[0]['compiler_invocations'] == 0
    assert rows[-1] == dict(event='finished', sequence=len(events), compiler_invocations=2,
                           proxy_invocations=0, wrapper_invocations=0)
    assert set(independent) == {c['workspace'] for c in PLAN['cases']}
    results = []
    for i, case in enumerate(PLAN['cases']):
        root = case['workspace']
        intent, owned, before, settled, prepared, compiler, roles, final = rows[1 + 8*i:9 + 8*i]
        assert all(r['workspace'] == root for r in [intent, owned, before, settled, prepared, compiler, roles, final])
        assert intent['mode'] == case['mode']
        result = compiler_receipt(settled['receipt'])
        build = prepared['result']
        assert build['ok'] == 1 and build['status'] == 'success' and build['implementation'] == 'native'
        assert build['selection_reason'] == PLAN['selection']['reason'] and build['compilation'] == result
        assert build['executable'] == root + '/rust-tools/rustup'
        assert build['compilation_argv'] == [PLAN['selection']['compiler'], '--no-default-config', '-isysroot',
            PLAN['selection']['sdk'], '-arch', 'arm64', '-mmacosx-version-min=11.0', '-O2', '-Wall', '-Wextra',
            '-Werror', '-fno-builtin', '-fno-modules', root+'/rust-tools/rustup.c', '-o', root+'/rust-tools/rustup']
        assert before['capture']['ok'] == final['capture']['ok'] == compiler['ok'] == 1
        assert before['capture']['error'] == final['capture']['error'] == compiler['error'] == ''
        nodes = independent[root]
        stats = files.compare_prototype(root, nodes, final['capture']['nodes'], final['capture']['file_bytes'])
        assert stats['maximum_file_bytes'] <= PLAN['workspace_policy']['file_bytes']
        assert stats['nodes'] <= PLAN['workspace_policy']['nodes'] and stats['depth'] <= PLAN['workspace_policy']['depth']
        assert stats['file_bytes'] <= PLAN['workspace_policy']['total_file_bytes']
        for path, node in nodes.items():
            if node['kind'] == 'file':
                assert node['mode'] in {0o400, 0o500, 0o600, 0o700} or (
                    path == root + '/rust-tool-resolution' and node['mode'] == 0o755)
        assert owned['node'] == final['capture']['nodes'][0] == before['capture']['nodes'][0]
        controlled = {root + '/rust-tool-resolution', root + '/rust-tools/cargo'}
        native = [n for n in final['capture']['nodes'] if n['identity']['path'] not in controlled]
        assert compiler['nodes_count'] == len(native)
        assert compiler['nodes_sha256'] == admission.digest(json.dumps(projection(native),sort_keys=True,
            ensure_ascii=True,separators=(',', ':')).encode())
        assert compiler['file_bytes'] == sum(len(n['bytes'].encode('latin1')) for n in native if n['kind'] == 'file')
        prior = {n['identity']['path']: n for n in before['capture']['nodes']}
        assert set(prior) == {root, root+'/rust-tools', root+'/rust-tools/rustup.c',
                              root+'/rust-tools/compiler-temp', root+'/rust-tools/compiler-cache'}
        final_by_path = {n['identity']['path']: n for n in final['capture']['nodes']}
        assert all(n == final_by_path[p] for p, n in prior.items())
        source = final_by_path[root + '/rust-tools/rustup.c']['bytes'].encode('latin1')
        assert source == bytes.fromhex(case['generated_c']['bytes_hex'])
        assert before['capture']['file_bytes'] == len(source)
        wrapper = nodes[root + '/rust-tool-resolution']
        assert wrapper['kind'] == 'file' and wrapper['mode'] == PLAN['wrapper']['mode']
        assert wrapper['size_bytes'] == PLAN['wrapper']['size_bytes'] and wrapper['sha256'] == PLAN['wrapper']['sha256']
        cargo = nodes[root + '/rust-tools/cargo']
        assert cargo['kind'] == 'symlink' and cargo['target'] == PLAN['cargo_role']['relative_target']
        assert [s['path'] for s in build['sources']] == [root+'/rust-tools/rustup.c', root+'/rust-tools/rustup']
        for source in build['sources']:
            assert source == dict(path=source['path'], **{k:nodes[source['path']][k]
                                  for k in ['device', 'inode', 'size_bytes', 'sha256']})
        assert nodes[root+'/rust-tools/rustup']['mode'] == 0o500
        results.append(dict(mode=case['mode'], workspace=root, profile=stats,
                            compiler_pid=settled['receipt']['pid'], native_wait_status=0))
    return dict(cases=results, compiler_invocations=2, native_proxy_invocations=0, wrapper_invocations=0,
                authority='complete current compiler profiles plus controlled unexecuted roles only')


def remove_exact(root, initial, capture=files.capture, remove=None, record=None):
    remaining = copy.deepcopy(initial)
    if remove is None:
        remove = lambda path, kind: (ROOT / path).rmdir() if kind == 'directory' else (ROOT / path).unlink()
    if record is None:
        raise ValueError('durable cleanup journal required')
    assert files.deletion_projection(capture(root)) == files.deletion_projection(remaining)
    for path in sorted(remaining, key=lambda p: (p.count('/'), p), reverse=True):
        observed = capture(root)
        assert files.deletion_projection(observed) == files.deletion_projection(remaining)
        node = remaining[path]
        record(dict(event='remove_intent', path=path, node=node,
                    remaining_sha256=admission.digest(json.dumps(observed, sort_keys=True).encode())))
        remove(path, node['kind'])
        del remaining[path]
        if remaining:
            assert files.deletion_projection(capture(root)) == files.deletion_projection(remaining)
        record(dict(event='removed', path=path, remaining_nodes=len(remaining)))
    return len(initial)


def review_and_clean():
    # Caller must first consume the actual runner's terminal tool result and
    # retain the shell's exit status. This is not native driver-image attestation.
    assert admission.local_file(OUTPUT / 'runner.exit', 32) == b'0\n'
    assert len(admission.local_file(OUTPUT / 'runner.stdout', 4096)) <= 4096
    assert admission.local_file(OUTPUT / 'runner.stderr', 32768) == b''
    revision, pins = admission.sources()
    permit = json.loads(admission.local_file(OUTPUT / 'permit.json', 65536))
    admission.validate_permit(permit, admission.expected_permit(revision, pins))
    start = json.loads(admission.local_file(OUTPUT / 'run-start.json', 65536))
    assert start['permit'] == permit and start['uid'] == os.getuid() and start['pid'] > 0
    epoch = admission.epoch_now()
    raw = admission.local_file(OUTPUT / 'journal.jsonl', PLAN['evidence_limits']['journal_bytes'])
    rows = [json.loads(line) for line in raw.splitlines()]
    independent = {c['workspace']: files.capture(c['workspace']) for c in PLAN['cases']}
    # Preserve the first independent capture before accepting any claims or
    # deleting a node. A failed review cannot silently replay this entrypoint.
    admission.save(OUTPUT / 'independent-first.json', dict(epoch_after=epoch, nodes=independent,
                   journal_sha256=admission.digest(raw)))
    result = validate(rows, independent)
    admission.save(OUTPUT / 'accepted-profile.json', result)
    journal = OUTPUT / 'cleanup.jsonl'
    fd = os.open(journal, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    with os.fdopen(fd, 'wb') as stream:
        def record(row):
            raw = (json.dumps(row, sort_keys=True) + '\n').encode()
            assert stream.tell() + len(raw) <= 8388608
            stream.write(raw); stream.flush(); os.fsync(stream.fileno())
        for case in PLAN['cases']:
            root = case['workspace']
            remove_exact(root, independent[root], record=record)
            assert not os.path.lexists(ROOT / root)
            record(dict(event='root_absent', path=root))
    admission.save(OUTPUT / 'reviewed.json', dict(result=result, roots_absent=True,
        journal_sha256=admission.digest(raw), cleanup_sha256=admission.digest(journal.read_bytes())))
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--review-and-clean', required=True, action='store_true')
    parser.parse_args()
    print(json.dumps(review_and_clean(), sort_keys=True))
