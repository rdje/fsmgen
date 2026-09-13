"""Join qualified wrapper policy and actual compiler profiles without execution."""
import argparse
import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
W = BASE.parent / 'native-proxy-wrapper-compatibility-20260913'
E = BASE.parent / 'native-proxy-compiler-census-policy-execution-20260913'
P = BASE.parent / 'native-proxy-compiler-census-policy-admission-20260913'
GUARD = 'docs/audits/native-proxy-runtime-retirement-20260910/PrivateWorkspace.pm'
SCOPE = json.loads((BASE / 'scope.json').read_bytes())
REVISION = SCOPE['source_revision']
spec = importlib.util.spec_from_file_location('completed_compiler_profiles', E / 'audit.py')
compiler = importlib.util.module_from_spec(spec)
spec.loader.exec_module(compiler)


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def read(path):
    return json.loads(path.read_bytes())


def pin(path):
    raw = path.read_bytes()
    return dict(path=str(path.relative_to(ROOT)), size_bytes=len(raw), sha256=digest(raw))


def old(path):
    return subprocess.check_output(['/usr/bin/git', '-c', 'core.excludesFile=.gitignore',
        'show', REVISION + ':' + path], cwd=ROOT,
        env=dict(PATH='/usr/bin:/bin', LC_ALL='C', LANG='C', TMPDIR=str(ROOT / '.artifacts/tmp')))


def validate(bundle):
    source = bundle['source']
    wrapper = bundle['wrapper']
    profile = bundle['compiler']
    assert digest(source) == wrapper['source']['repaired_sha256'] == bundle['compiler_guard_sha256']
    assert digest(bundle['baseline']) == wrapper['source']['baseline_sha256']
    assert wrapper['source']['exact_guard_only'] and wrapper['source']['producer_mode'] == '0755'
    assert wrapper['result']['synthetic_cleanup_only']
    assert wrapper['result']['baseline_retirement_rejected_unchanged']
    assert wrapper['result']['actual_compiler_capacity_qualified'] is False
    assert wrapper['result']['native_or_live_execution'] is False
    limits = {}
    for name, key in [('NODE', 'nodes'), ('DEPTH', 'depth'), ('TOTAL', 'total_file_bytes')]:
        values = re.findall(rb'my \$' + name.encode() + rb'_LIMIT = ([0-9_]+);', source)
        assert len(values) == 1
        limits[key] = int(values[0].replace(b'_', b''))
    match = re.findall(rb'_source\("\$ROOT/\$path", \$mode, ([0-9_]+)\)', source)
    assert len(match) == 1
    limits['file_bytes'] = int(match[0].replace(b'_', b''))
    assert limits == {k: bundle['policy'][k] for k in limits}
    assert limits == dict(nodes=256, depth=8, total_file_bytes=4194304, file_bytes=65536)
    result = compiler.validate(bundle['data'])
    assert all(result[k] == profile[k] for k in result)
    assert profile['roots_absent'] and profile['result']['native_proxy_invocations'] == 0
    assert profile['result']['wrapper_invocations'] == 0
    independent = json.loads(bundle['data']['inner']['independent-first.json'])['nodes']
    joined = []
    for case in profile['result']['cases']:
        root = case['workspace']
        nodes = independent[root]
        wrapper_path = root + '/rust-tool-resolution'
        assert re.fullmatch(r'\.artifacts/tmp/process-supervisor-tests/fsmgen-[A-Za-z0-9_]+/rust-tool-resolution', wrapper_path)
        assert nodes[wrapper_path]['mode'] == 0o755
        assert nodes[wrapper_path]['sha256'] == compiler.PLAN['wrapper']['sha256']
        for path, node in nodes.items():
            if node['kind'] == 'file':
                assert node['mode'] in {0o400, 0o500, 0o600, 0o700} or (path == wrapper_path and node['mode'] == 0o755)
        measured = case['profile']
        used = dict(nodes=measured['nodes'], depth=measured['depth'],
                    file_bytes=measured['maximum_file_bytes'], total_file_bytes=measured['file_bytes'])
        assert all(0 <= used[k] <= limits[k] for k in limits)
        joined.append(dict(mode=case['mode'], workspace=root, measured=used,
                           policy=limits, remaining={k: limits[k] - used[k] for k in limits}))
    assert bundle['authority'] == 'selected workspace compatibility and capacity only'
    return dict(guard_sha256=digest(source), profiles=joined,
                wrapper_inert_receipts_remain_synthetic=True, compiler_profiles_remain_actual=True,
                workspace_parent_can_close=True, native_execution_or_receipt_authority=False)


def verify():
    pins = read(BASE / 'input-pins.json')
    for row in pins:
        assert pin(ROOT / row['path']) == row
        assert old(row['path']) == (ROOT / row['path']).read_bytes()
    checks = read(BASE / 'prior-checks.json')
    assert set(checks) == {'wrapper-saved', 'compiler-saved'}
    assert all(row['exit'] == '0\n' for row in checks.values())
    wrapper, profile = read(W / 'review.json'), read(E / 'review.json')
    assert json.loads(checks['wrapper-saved']['stdout']) == wrapper['result']
    assert json.loads(checks['compiler-saved']['stdout']) == profile
    data = dict(inner={}, outer={})
    for row in read(E / 'first-results.json')['files']:
        path = ROOT / row['path']
        assert pin(path) == {k: row[k] for k in ['path', 'size_bytes', 'sha256']}
        data[path.parent.name][path.name] = path.read_bytes()
    guard_pin = [r for r in read(E / 'source-pins.json') if r['path'] == GUARD]
    assert len(guard_pin) == 1
    bundle = dict(source=(ROOT / GUARD).read_bytes(), baseline=(W / 'PrivateWorkspace.baseline.source').read_bytes(),
                  wrapper=wrapper, compiler=profile, compiler_guard_sha256=guard_pin[0]['sha256'],
                  policy=read(P / 'plan.json')['workspace_policy'], data=data,
                  authority='selected workspace compatibility and capacity only')
    result = validate(bundle)
    mutations = {
        'stale_guard': lambda b: b.update(compiler_guard_sha256='0' * 64),
        'restored_old_guard': lambda b: b.update(source=b['baseline']),
        'raised_policy': lambda b: b['policy'].update(nodes=257),
        'synthetic_promoted': lambda b: b['wrapper']['result'].update(actual_compiler_capacity_qualified=True),
        'synthetic_receipts_hidden': lambda b: b['wrapper']['result'].update(synthetic_cleanup_only=False),
        'native_promoted': lambda b: b['compiler']['result'].update(native_proxy_invocations=1),
        'capacity_normalized': lambda b: b['compiler']['result']['cases'][0]['profile'].update(maximum_file_bytes=1),
        'receipt_authority_promoted': lambda b: b.update(authority='complete native retirement authority'),
    }
    rejected = []
    for name, change in mutations.items():
        altered = copy.deepcopy(bundle)
        change(altered)
        try:
            validate(altered)
        except (AssertionError, ValueError, KeyError):
            rejected.append(name)
        else:
            raise AssertionError('joined altered authority accepted: ' + name)
    assert len(wrapper['rejected_controls']) == 8 and len(profile['rejected_controls']) == 11
    final = json.loads(bytes.fromhex(read(W / 'first-run.json')['final-census.json']['bytes_hex']))
    assert final['nodes'] == {}
    roots = final['absent'] + [c['workspace'] for c in profile['result']['cases']]
    assert len(set(roots)) == len(roots) and all(not os.path.lexists(ROOT / root) for root in roots)
    return dict(owner=SCOPE['owner'], source_revision=REVISION, pinned_inputs=len(pins),
                joined=result, rejected_controls=rejected, retained_wrapper_controls=8,
                retained_actual_controls=11, absent_owned_roots=len(roots),
                compiler_invocations=0, fixture_allocations=0, worker_invocations=0,
                claim_legs=SCOPE['claim_legs'], remaining=SCOPE['remaining'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--verify-saved', required=True, action='store_true')
    parser.parse_args()
    print(json.dumps(verify(), sort_keys=True))
