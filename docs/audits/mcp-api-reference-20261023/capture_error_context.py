#!/usr/bin/env python3
"""Capture native/public errors with stock and instrumented public entrypoints."""
import gzip
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
assert Path.cwd().resolve() == ROOT
sys.path.insert(0, str(ROOT / 'scripts'))
sys.path.insert(0, str(ROOT / 't/python'))
from generate_pod_reference import local_path
from test_fixture_mcp_stdio import Session

PROBE = 'docs/audits/mcp-api-reference-20261023/probe_error_context.pl'
SELF = 'docs/audits/mcp-api-reference-20261023/capture_error_context.py'
ADAPTER = 'perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm'
FIXTURE = 'fsm/ahb_lite_subordinate.fsm'


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def run(command, work, name, stdin=None):
    out, err = work / (name + '.stdout'), work / (name + '.stderr')
    assert not out.exists() and not err.exists()
    with out.open('wb') as stdout, err.open('wb') as stderr:
        result = subprocess.run(command, cwd=ROOT, input=stdin, stdout=stdout, stderr=stderr, timeout=120)
    assert result.returncode == 0, 'Probe failed; raw output retained: ' + name
    return {'exit_status': result.returncode, 'stdout_utf8': out.read_text(), 'stderr_utf8': err.read_text()}


def capture(output_name, work_name, relocation_name):
    output = local_path(ROOT, output_name)
    work, moved = (local_path(ROOT, name) for name in (work_name, relocation_name))
    assert output.suffix == '.gz' and not output.exists() and not work.exists() and not moved.exists()
    work.mkdir(parents=True)
    moved.mkdir(parents=True)
    assert moved.stat().st_dev == ROOT.stat().st_dev == work.stat().st_dev
    head = subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode().strip()
    native = [p for p in subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', head,
              'perl']).decode().splitlines() if p.endswith('.pm')]
    copies = native + ['README.md', 'bin/fsmgen', 'bin/fsmgen-mcp', FIXTURE, PROBE]
    selected = copies + [SELF, 'scripts/generate_pod_reference.py', 't/python/test_fixture_mcp_stdio.py']
    assert len(selected) == len(set(selected))
    sources = {p: digest((ROOT / p).read_bytes()) for p in selected}
    observer = {p: (ROOT / p).read_text() for p in selected if p not in native}
    native_overrides = {p: (ROOT / p).read_text() for p in native
                        if digest(subprocess.check_output(['git', 'show', head + ':' + p])) != sources[p]}
    for path in copies:
        origin, target = ROOT / path, moved / path
        assert origin.is_file() and not origin.is_symlink()
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(origin.read_bytes())
        target.chmod(origin.stat().st_mode & 0o777)
    assert {p: digest((moved / p).read_bytes()) for p in copies} == {p: sources[p] for p in copies}
    marker = {'owner': 'PERL-POD-API-REFERENCE.6.1.2.2.5.1', 'source_head': head,
              'files': {p: {'sha256': sources[p], 'bytes': (ROOT / p).stat().st_size} for p in copies}}
    (moved / '.error-context-owner.json').write_text(json.dumps(marker, indent=2) + '\n')
    record = {'head': head, 'source_sha256': sources, 'observer_sources': observer,
              'native_source_overrides': native_overrides, 'relocation': marker,
              'relocation_path': moved.relative_to(ROOT).as_posix(), 'runs': []}
    for label, root in (('original', ROOT), ('spaced', moved)):
        invocation = ['perl', '-I' + str(root / 'perl'), str(root / PROBE), '--root', str(root)]
        api = run(invocation + ['--mode', 'api'], work, label + '-api')
        assert not api['stderr_utf8']
        data = json.loads(api['stdout_utf8'])
        errors = [c for c in data['cases'] if c['name'] in ('missing_source', 'quoted_version', 'unknown_tool', 'unknown_method')]
        launcher = ['perl', str(root / 'bin/fsmgen-mcp'), '--repo-root', str(root), '--workspace-root', str(root)]
        one_shot = []
        for i, case in enumerate(errors):
            request = {'jsonrpc': '2.0', 'id': i, 'method': case['method'], 'params': case['params']}
            captured = run(launcher + ['--request-json', json.dumps(request)], work, label + '-one-shot-' + str(i))
            assert not captured['stderr_utf8']
            one_shot.append({'request': request, 'capture': captured, 'response': json.loads(captured['stdout_utf8'])})
        requests, replies = [], []
        with Session(launcher) as server:
            for i, case in enumerate(errors + [next(c for c in data['cases'] if c['name'] == 'ping')]):
                request = {'jsonrpc': '2.0', 'id': i, 'method': case['method'], 'params': case['params']}
                server.send(request)
                requests.append(request)
                replies.append(server.receive())
            persistent = {'requests': requests, 'responses': replies,
                          'sent_utf8': server.sent.decode(), 'received_utf8': server.received.decode()}
        persistent.update(exit_status=server.process.returncode, orderly_eof=True)
        custom = []
        for name in ('callback_plain', 'callback_authored_location', 'callback_fake_suffix', 'callback_quotes',
                     'callback_external_path', 'callback_long_unicode'):
            request = {'jsonrpc': '2.0', 'id': 1, 'method': 'tools/call',
                       'params': {'name': 'fsmgen_check', 'arguments': {'source_id': FIXTURE}}}
            ping = {'jsonrpc': '2.0', 'id': 2, 'method': 'ping', 'params': {}}
            frames = ''.join(json.dumps(r) + '\n' for r in (request, ping))
            captured = run(invocation + ['--mode', 'stdio', '--case', name], work, label + '-custom-' + name,
                           stdin=frames.encode())
            events = json.loads(captured['stderr_utf8'])
            assert set(events) == {'probe_native_events'}
            custom.append({'case': name, 'requests': [request, ping], 'sent_utf8': frames, 'capture': captured,
                           'native_events': events['probe_native_events'],
                           'responses': [json.loads(line) for line in captured['stdout_utf8'].splitlines()]})
        record['runs'].append({'root_kind': label, 'implementation_root_label': str(root),
                               'api_capture': api, 'api': data, 'one_shot': one_shot,
                               'persistent': persistent, 'custom_stdio': custom})
    assert sources == {p: digest((ROOT / p).read_bytes()) for p in selected}, 'Input changed during capture'
    assert head == subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode().strip()
    output.write_bytes(gzip.compress((json.dumps(record, indent=2, ensure_ascii=False) + '\n').encode(), mtime=0))
    print('Complete native/public error contexts retained: ' + output.relative_to(ROOT).as_posix())


if __name__ == '__main__':
    assert len(sys.argv) == 4, 'Usage: capture_error_context.py OUTPUT.gz WORK_DIRECTORY RELOCATION_DIRECTORY'
    capture(*sys.argv[1:])
