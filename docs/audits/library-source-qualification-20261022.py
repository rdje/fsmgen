#!/usr/bin/env python3
"""Retain focused preservation checks and representative real public transports."""
import gzip
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import copy
import runpy
import datetime
import time
import tempfile
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
os.chdir(ROOT)
OUTPUT = Path('docs/audits/library-source-qualification-20261022.json.gz')
RECIPE = 'docs/audits/library-source-qualification-20261022.py'
PUBLIC = 'docs/audits/library-source-public-20261022.pl'
FOUNDATION = Path('docs/audits/library-source-foundation-20261022.json.gz')
WORK = Path('.artifacts/library-source-retention-qualified-20261022')
TESTS = [
    't/1092-isf-lispish-adapter.t', 't/1281-isf-enum-member-library-use-params.t',
    't/1352-isf-library-use-package-constants.t', 't/2094-isf-authored-width-declarations.t',
    't/2096-isf-authored-static-references.t', 't/2097-isf-nested-aggregate-normalization.t',
    't/2098-isf-authored-library-override-sources.t', 't/1112-isf-public-interface-contract.t',
    't/1117-isf-public-lower-result-files-audit.t', 't/1118-isf-public-parse-source-facade-audit.t',
    't/2044-isf-conditional-origin-source-authority.t', 't/2045-isf-same-source-library-origins.t',
]
FOCUS = Path('.artifacts/library-source-focused-20261022.json')
FOCUS_COMMANDS = {
    'focused': ['prove', '-Iperl', '-It/lib', *TESTS],
    'book_tasks': ['prove', '-Iperl', 't/1376-isf-book-example-lowering-audit.t', 't/1549-task-tree-integrity-doctrine.t'],
    'syntax': ['perl', '-Iperl', '-c', 'perl/FSM/Adapter/ISF/Parser.pm'],
}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def normalized(value):
    if type(value) is dict:
        return {key: normalized(item) for key, item in value.items()}
    if type(value) is list:
        return [normalized(item) for item in value]
    if type(value) is str:
        if value in ('<repo>', str(ROOT)):
            return '.'
        return value.replace('<repo>/', '').replace(str(ROOT) + '/', '')
    return value


def capture(argv, stdin=None, timeout=300):
    started = datetime.datetime.now(datetime.timezone.utc).isoformat()
    t0 = time.monotonic_ns()
    try:
        result = subprocess.run(argv, input=stdin, capture_output=True, timeout=timeout)
        status, stdout, stderr = result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired as error:
        status, stdout, stderr = 'timeout', error.stdout or b'', error.stderr or b''
    return {'argv': argv, 'exit': status, 'controller_pid': os.getpid(), 'subprocess_timeout_seconds': timeout,
            'started_utc': started, 'ended_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
            'elapsed_ns': time.monotonic_ns() - t0, **{
        label: {'text': raw.decode().replace(str(ROOT), '<repo>'), 'raw_sha256': sha(raw), 'raw_bytes': len(raw)}
        for label, raw in (('stdout', stdout), ('stderr', stderr))}}


def capture_controls():
    # No process launch: a supplied TimeoutExpired proves both partial streams
    # survive without depending on the host's interpreter startup latency.
    error = subprocess.TimeoutExpired(['fixture'], 300, output=b'partial\n', stderr=b'diagnostic\n')
    with patch.object(subprocess, 'run', side_effect=error):
        expired = capture(['fixture'])
    with patch.object(subprocess, 'run', return_value=subprocess.CompletedProcess(['fixture'], 7, b'out', b'err')):
        ordinary = capture(['fixture'])
    if expired['exit'] != 'timeout' or expired['stdout']['text'] != 'partial\n' or expired['stderr']['text'] != 'diagnostic\n':
        raise ValueError('timeout stream control failed')
    if ordinary['exit'] != 7 or ordinary['stdout']['text'] != 'out' or ordinary['stderr']['text'] != 'err':
        raise ValueError('ordinary capture control failed')
    return {'timeout': expired, 'ordinary': ordinary}


def prepare_public_inputs(after, foundation, work=WORK):
    work.resolve().relative_to(ROOT)
    selected = {'alias', 'nested', 'defaults'}
    inputs = {work / (name + '.isf'): after['cases'][name]['private']['source'].encode() for name in selected}
    package = foundation['public_package']
    raw = package['text'].encode()
    if sha(raw) != package['sha256']:
        raise ValueError('saved package digest')
    inputs[work / 'shared.fsm'] = raw
    # Preflight every target before creating anything. Matching existing bytes
    # are reusable; a conflicting path is never overwritten.
    for path, raw in inputs.items():
        if any(parent.is_symlink() for parent in (path, *path.parents)):
            raise ValueError('public input symlink: ' + str(path))
        if path.exists() and (not path.is_file() or path.read_bytes() != raw):
            raise ValueError('conflicting public input: ' + str(path))
    for path, raw in inputs.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        if not path.exists():
            with path.open('xb') as stream:
                stream.write(raw)
    return {str(path): sha(raw) for path, raw in inputs.items()}


def input_controls():
    _, after = runpy.run_path('docs/audits/library-source-retention-20261022.py')['qualification_pair']()
    foundation = json.loads(gzip.decompress(FOUNDATION.read_bytes()))
    with tempfile.TemporaryDirectory(dir='.artifacts/tmp', prefix='library-public-inputs-') as directory:
        base = Path(directory)
        work = base / 'fresh'
        expected = prepare_public_inputs(after, foundation, work)
        if len(expected) != 4 or any(sha(Path(p).read_bytes()) != digest for p, digest in expected.items()):
            raise ValueError('cache-free restoration failed')
        if prepare_public_inputs(after, foundation, work) != expected:
            raise ValueError('matching input reuse changed')
        bad = base / 'conflict'
        bad.mkdir()
        (bad / 'defaults.isf').write_bytes(b'owned-conflicting-input')
        try:
            prepare_public_inputs(after, foundation, bad)
        except ValueError:
            pass
        else:
            raise ValueError('conflicting input accepted')
        if {p.name: p.read_bytes() for p in bad.iterdir()} != {'defaults.isf': b'owned-conflicting-input'}:
            raise ValueError('conflict preflight wrote another file')
        link = base / 'symlink'
        link.mkdir()
        (link / 'target').write_bytes(b'owned-target')
        (link / 'alias.isf').symlink_to('target')
        try:
            prepare_public_inputs(after, foundation, link)
        except ValueError:
            pass
        else:
            raise ValueError('symlink input accepted')
        if (link / 'target').read_bytes() != b'owned-target' or len(list(link.iterdir())) != 2:
            raise ValueError('symlink preflight changed its target or other inputs')
    return {'fresh_restored': True, 'matching_reused': True, 'conflict_refused_without_writes': True,
            'symlink_refused_without_writes': True}


def focus():
    record = {'inputs': {path: {'text': Path(path).read_text(), 'sha256': sha(Path(path).read_bytes())}
                        for path in (RECIPE, 'perl/FSM/Adapter/ISF/Parser.pm', *TESTS)}, 'results': {}}
    try:
        for label, argv in FOCUS_COMMANDS.items():
            print('qualifying', label, flush=True)
            record['results'][label] = capture(argv)
            if record['results'][label]['exit'] != 0:
                raise ValueError(label + ' qualification failed')
    finally:
        with FOCUS.open('x') as stream:
            json.dump(record, stream, sort_keys=True, indent=2)
    print('library source focused qualification: PASS')


def validate(record):
    after_path = Path('docs/audits/library-source-retention-after-20261022.json.gz')
    _, after = runpy.run_path('docs/audits/library-source-retention-20261022.py')['qualification_pair']()
    if record.get('qualified') is not True or 'error' in record or record['after_sha256'] != sha(after_path.read_bytes()):
        raise ValueError('qualification boundary')
    if record['qualification_join'] != after['_qualification_join']:
        raise ValueError('interrupted/recovery boundary changed')
    if record['foundation_sha256'] != sha(FOUNDATION.read_bytes()):
        raise ValueError('foundation identity')
    initial_path = Path('docs/audits/library-source-retention-initial-20261022.json.gz')
    initial = json.loads(gzip.decompress(initial_path.read_bytes()))
    if record['initial_capture_sha256'] != sha(initial_path.read_bytes()) or 'error' not in initial:
        raise ValueError('first refused capture identity')
    if set(record['initial_private']) != set(after['cases']):
        raise ValueError('first private capture completeness')
    for name, row in initial['cases'].items():
        if record['initial_private'][name] != row['private']:
            raise ValueError('first private/native join')
    for path, value in record['inputs'].items():
        if value['sha256'] != sha(value['text'].encode()):
            raise ValueError('stored input digest: ' + path)
    focused = record['focus_capture']
    if focused['inputs']['perl/FSM/Adapter/ISF/Parser.pm']['sha256'] != after['inputs']['perl/FSM/Adapter/ISF/Parser.pm']['sha256']:
        raise ValueError('focused parser identity')
    for label, argv in FOCUS_COMMANDS.items():
        if focused['results'][label]['argv'] != argv or focused['results'][label] != record['results'][label]:
            raise ValueError('focused result identity')
    for path, value in focused['inputs'].items():
        if value['sha256'] != sha(value['text'].encode()):
            raise ValueError('focused input digest')
        if path in record['inputs'] and path != RECIPE and value != record['inputs'][path]:
            raise ValueError('focused input changed')
    if set(record['results']) != {'saved', 'public', 'focused', 'book_tasks', 'syntax'}:
        raise ValueError('qualification stage membership')
    if any(type(value['exit']) is not int or value['exit'] != 0 for value in record['results'].values()):
        raise ValueError('qualification stage failed')
    for name in ('focused', 'book_tasks'):
        if 'All tests successful.' not in record['results'][name]['stdout']['text']:
            raise ValueError('successful focused tests absent')
    expected = {name: {kind: normalized(json.loads(query['stdout']['text'])) for kind, query in row['queries'].items()}
                for name, row in after['cases'].items() if name in ('alias', 'nested', 'defaults')}
    if json.dumps(record['expected_native'], sort_keys=True) != json.dumps(expected, sort_keys=True):
        raise ValueError('native authority changed')
    rows = [json.loads(line) for line in record['results']['public']['stdout']['text'].splitlines()]
    if len(rows) != 9 or {(r['name'], r['kind']) for r in rows} != {(n, k) for n in expected for k in expected[n]}:
        raise ValueError('public membership')
    if len({r['observation']['programme_pid'] for r in rows}) != 1:
        raise ValueError('public programme identity changed')
    controls = record['capture_controls']
    if controls['timeout']['exit'] != 'timeout' or controls['timeout']['stdout']['text'] != 'partial\n' or controls['timeout']['stderr']['text'] != 'diagnostic\n' or controls['ordinary']['exit'] != 7:
        raise ValueError('capture control outcomes')
    foundation = json.loads(gzip.decompress(FOUNDATION.read_bytes()))
    expected_inputs = {str(WORK / (name + '.isf')): after['cases'][name]['source_sha256'] for name in expected}
    expected_inputs[str(WORK / 'shared.fsm')] = foundation['public_package']['sha256']
    if record['materialized_inputs'] != expected_inputs:
        raise ValueError('materialized source/package identity')
    for row in rows:
        name, kind = row['name'], row['kind']
        response, wire = row['api'], row['wire']
        if row['source_sha256_before'] != row['source_sha256_after'] or row['source_sha256_before'] != after['cases'][name]['source_sha256']:
            raise ValueError('public source identity')
        if response.get('error') or response['result'].get('isError'):
            raise ValueError('API refusal')
        structured = response['result']['structuredContent']
        if json.dumps(normalized(structured['report']), sort_keys=True) != json.dumps(expected[name][kind], sort_keys=True):
            raise ValueError('native/API mismatch')
        if json.dumps(json.loads(response['result']['content'][0]['text']), sort_keys=True) != json.dumps(structured, sort_keys=True):
            raise ValueError('API text mismatch')
        if wire['exit_code'] != 0 or wire['stderr'] or len(wire['stdout'].splitlines()) != 1 or not wire['stdout'].endswith('\n'):
            raise ValueError('newline framing/outcome')
        if json.dumps(json.loads(wire['stdout']), sort_keys=True) != json.dumps(response, sort_keys=True):
            raise ValueError('API/newline mismatch')
        observation = row['observation']
        if type(observation['programme_pid']) is not int or observation['programme_pid'] <= 0:
            raise ValueError('programme identity')
        if not observation['api_started_monotonic'] <= observation['api_finished_monotonic'] <= observation['newline_finished_monotonic']:
            raise ValueError('method observation order')


def verify():
    record = json.loads(gzip.decompress(OUTPUT.read_bytes()))
    validate(record)
    for mutation in ('membership', 'native', 'kind', 'text-kind', 'source', 'framing', 'status-kind', 'inputs'):
        bad = copy.deepcopy(record)
        rows = [json.loads(line) for line in bad['results']['public']['stdout']['text'].splitlines()]
        if mutation == 'membership':
            rows.pop()
        elif mutation == 'native':
            bad['expected_native']['alias']['check']['success'] = False
        elif mutation == 'kind':
            rows[0]['api']['result']['structuredContent']['report']['success'] = 1
        elif mutation == 'source':
            rows[0]['source_sha256_after'] = '0' * 64
        elif mutation == 'text-kind':
            structured = json.loads(rows[0]['api']['result']['content'][0]['text'])
            structured['report']['success'] = 1
            rows[0]['api']['result']['content'][0]['text'] = json.dumps(structured)
        elif mutation == 'status-kind':
            bad['results']['public']['exit'] = False
        elif mutation == 'inputs':
            bad['materialized_inputs'][str(WORK / 'shared.fsm')] = '0' * 64
        else:
            rows[0]['wire']['stdout'] += '\n'
        bad['results']['public']['stdout']['text'] = '\n'.join(json.dumps(row) for row in rows) + '\n'
        try:
            validate(bad)
        except (ValueError, KeyError, TypeError):
            continue
        raise ValueError('hostile public control accepted: ' + mutation)
    print('library source public qualification: PASS; hostile saved controls rejected')


def qualify_controls():
    record = {'owner': 'ISF-REDUCTION-DELIVERY.2.3.2.1.2.3.2', 'schema_version': 1,
              'recipe': Path(RECIPE).read_text(), 'public_packet_sha256': sha(OUTPUT.read_bytes()),
              'scope': 'Saved-product verification and isolated repository-local materialization/capture controls only; no source query is replayed. Read-only oracles were strengthened after the immutable public capture; its original complete instrument remains in that packet.'}
    try:
        record['inputs'] = input_controls()
        record['capture'] = capture_controls()
        verify()
        record['qualified'] = True
    except BaseException as error:
        record['error'] = str(error).replace(str(ROOT), '<repo>')
        raise
    finally:
        with Path('docs/audits/library-source-public-controls-20261022.json.gz').open('xb') as stream:
            with gzip.GzipFile(fileobj=stream, mode='wb', mtime=0) as compressed:
                compressed.write((json.dumps(record, sort_keys=True, indent=2) + '\n').encode())
    print('public input/capture controls: PASS')


def final_checks():
    record = {'owner': 'ISF-REDUCTION-DELIVERY.2.3.2.1.2.3.2', 'schema_version': 1,
              'recipe': Path(RECIPE).read_text(), 'results': {},
              'scope': 'Current book/task/source-view checks after prose/frontier changes; unchanged product preservation tests remain the explicitly dated foundation evidence. No native/API/MCP source workload is replayed.'}
    try:
        for label, argv in (
            ('book_tasks', ['prove', '-Iperl', 't/1376-isf-book-example-lowering-audit.t', 't/1549-task-tree-integrity-doctrine.t']),
            ('source_views', ['python3', '-B', 'scripts/book_source_references.py', '--check', '--verify-build', 'docs/book/book']),
            ('source_index', ['python3', '-B', 'scripts/check_book_source_index.py']),
            ('saved_public', ['python3', '-B', RECIPE, 'verify']),
            ('saved_foundation', ['python3', '-B', 'docs/audits/library-source-foundation-20261022.py', 'verify']),
        ):
            print('checking', label, flush=True)
            record['results'][label] = capture(argv)
            if record['results'][label]['exit'] != 0:
                raise ValueError(label + ' failed')
        record['qualified'] = True
    except BaseException as error:
        record['error'] = str(error).replace(str(ROOT), '<repo>')
        raise
    finally:
        with Path('docs/audits/library-source-public-final-checks-20261022.json.gz').open('xb') as stream:
            with gzip.GzipFile(fileobj=stream, mode='wb', mtime=0) as compressed:
                compressed.write((json.dumps(record, sort_keys=True, indent=2) + '\n').encode())
    print('public source final checks: PASS')


def main():
    after_path = Path('docs/audits/library-source-retention-after-20261022.json.gz')
    _, after = runpy.run_path('docs/audits/library-source-retention-20261022.py')['qualification_pair']()
    expected = {name: {kind: normalized(json.loads(query['stdout']['text'])) for kind, query in row['queries'].items()}
                for name, row in after['cases'].items() if name in ('alias', 'nested', 'defaults')}
    foundation = json.loads(gzip.decompress(FOUNDATION.read_bytes()))
    focused = foundation['focus_capture']
    for path, value in focused['inputs'].items():
        if path != RECIPE and sha(Path(path).read_bytes()) != value['sha256']:
            raise ValueError('focused input changed: ' + path)
    record = {'owner': 'ISF-REDUCTION-DELIVERY.2.3.2.1.2.3', 'schema_version': 1,
              'baseline_revision': after['baseline_revision'], 'after_sha256': sha(after_path.read_bytes()),
              'foundation_sha256': sha(FOUNDATION.read_bytes()),
              'inputs': {path: {'text': Path(path).read_text(), 'sha256': sha(Path(path).read_bytes())}
                         for path in (RECIPE, PUBLIC, 'docs/audits/library-source-retention-20261022.py',
                                      'docs/audits/library-source-interruption-20261022.py',
                                      'docs/audits/library-source-timeout-control-20261022.py', *TESTS)}, 'results': dict(focused['results']),
              'focus_capture': focused, 'qualification_join': after['_qualification_join'], 'expected_native': expected,
              'initial_attempts': foundation['initial_attempts'],
              'initial_capture_sha256': sha(Path('docs/audits/library-source-retention-initial-20261022.json.gz').read_bytes()),
              'initial_private': foundation['initial_private'],
              'limits': 'Fixed current source checks only. Native products join the explicitly interrupted epoch with its separate successful traced final stage; historical cause remains open. The exact earlier focus instrument and results remain retained; only qualification orchestration changed afterward, with product/test inputs held identical. API/newline qualification selects alias/nested/default source cases; other cases have native and private evidence only. Programme PID and UTC/monotonic method events are current observations, not kernel birth attribution or a latency distribution. subprocess.run timeouts are not whole-host latency guarantees. No full transitive environment, complete producer-footprint, raw-root stream reconstruction, HDL execution or public dependency-inventory claim.'}
    try:
        record['capture_controls'] = capture_controls()
        record['materialized_inputs'] = prepare_public_inputs(after, foundation)
        for label, argv, stdin in (
            ('saved', ['python3', '-B', 'docs/audits/library-source-retention-20261022.py', 'verify'], None),
            ('public', ['perl', '-Iperl', '-It/lib', PUBLIC], json.dumps(expected).encode()),
        ):
            print('qualifying', label, flush=True)
            result = capture(argv, stdin)
            record['results'][label] = result
            if result['exit'] != 0:
                raise ValueError(label + ' qualification failed')
        public_rows = [json.loads(line) for line in record['results']['public']['stdout']['text'].splitlines()]
        if {(row['name'], row['kind']) for row in public_rows} != {(n, k) for n in expected for k in expected[n]}:
            raise ValueError('public membership differs')
        for row in public_rows:
            if row['source_sha256_before'] != row['source_sha256_after']:
                raise ValueError('source identity changed')
        record['qualified'] = True
    except BaseException as error:
        record['error'] = str(error).replace(str(ROOT), '<repo>')
        raise
    finally:
        with OUTPUT.open('xb') as stream:
            with gzip.GzipFile(fileobj=stream, mode='wb', mtime=0) as compressed:
                compressed.write((json.dumps(record, sort_keys=True, indent=2) + '\n').encode())
    print('library source qualification: PASS')


if __name__ == '__main__':
    if sys.argv[1:] == ['final-checks']:
        final_checks()
    elif sys.argv[1:] == ['controls']:
        qualify_controls()
    elif sys.argv[1:] == ['focus']:
        focus()
    elif sys.argv[1:] == ['verify']:
        verify()
    elif not sys.argv[1:]:
        main()
    else:
        raise SystemExit('usage: library-source-qualification-20261022.py [focus|controls|verify|final-checks]')
