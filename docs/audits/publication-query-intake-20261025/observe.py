#!/usr/bin/env python3
"""Capture a declared normal intake once; default to saved-product checks."""
import argparse
import base64
import copy
import datetime
import gzip
import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import time

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
QUESTION = 'how are authored binding names retained before formal physical projection?'
ROUTE = QUESTION + '\tisf-formal-source-binding-reports\tdocs/knowledge/isf-formal-source-binding-reports.md\n'
FIXTURE = BASE.relative_to(ROOT).as_posix() + '/conditional-do.isf'
WORK = ROOT / '.artifacts/publication-query-intake-20261025'
BOUND = 60


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)


def packed(raw):
    normalized = raw.replace(str(ROOT).encode(), b'<repository>')
    return {'base64': base64.b64encode(normalized).decode(),
            'bytes': len(normalized), 'sha256': sha(normalized),
            'original_bytes': len(raw), 'original_sha256': sha(raw)}


def unpack(value):
    raw = base64.b64decode(value['base64'], validate=True)
    assert type(value['bytes']) is int and len(raw) == value['bytes']
    assert sha(raw) == value['sha256'], 'retained product identity'
    return raw


def group_absent(pid):
    try:
        os.killpg(pid, 0)
    except ProcessLookupError:
        return True
    return False


def check_case(kind, case):
    allowed = {'argv', 'inputs', 'expected_stdout', 'json_predicates', 'trace_file', 'fixture_origin'}
    assert set(case) <= allowed and type(case['inputs']) is list
    for path in case['inputs']:
        relative = Path(path)
        actual = ROOT / relative
        assert not relative.is_absolute() and '..' not in relative.parts
        assert actual.resolve().is_relative_to(ROOT) and actual.is_file()
        assert actual.stat().st_dev == ROOT.stat().st_dev
    if kind == 'knowledge':
        assert case['argv'] == ['bash', '-x', 'knowledge-map/scripts/query_knowledge_map.sh', '--no-cache', QUESTION]
        assert case['expected_stdout'] == ROUTE and case['trace_file'] is None
        assert case['json_predicates'] == []
    else:
        trace = '.artifacts/publication-query-intake-20261025/binding/events.trace'
        assert case['argv'] == ['perl', 'bin/fsmgen', '--quiet', '--strict', '--trace-verbosity=debug',
                                '--trace-log=' + trace, '--emit-schedule-json', FIXTURE]
        assert case['trace_file'] == trace and case['json_predicates']


def validate(kind, case, row):
    check_case(kind, case)
    assert json.dumps(row['case'], sort_keys=True) == json.dumps(case, sort_keys=True), 'declared case changed'
    assert row['owner'] == 'PUBLICATION-REGRESSION-REPAIRS.7'
    assert row['recipe'] == Path(__file__).read_text(), 'capture programme identity'
    assert row['recipe_sha256'] == sha(row['recipe'].encode())
    assert type(row['bound_seconds']) is int and row['bound_seconds'] == BOUND
    assert type(row['returncode']) is int and row['returncode'] == 0, 'actual integer success'
    assert row['timed_out'] is False and row['group_absent'] is True, 'normal settlement'
    assert row['lingering_group'] is False, 'no post-success group cleanup'
    assert row['guard'] == {'host': '88', 'descendant_mib': '4096', 'active': '1'}
    for field in ('pid', 'pgid', 'sid', 'started_ns', 'launched_ns', 'ended_ns'):
        assert type(row[field]) is int and row[field] > 0, 'discrete process/clock kind'
    assert row['pid'] == row['pgid'] == row['sid'], 'owned session identity'
    assert row['started_ns'] <= row['launched_ns'] <= row['ended_ns'], 'clock order'
    for field in ('started_utc', 'ended_utc'):
        assert datetime.datetime.fromisoformat(row[field]).utcoffset() == datetime.timedelta(0)
    assert len(row['baseline']) == 40 and all(c in '0123456789abcdef' for c in row['baseline'])
    for path, identity in row['inputs'].items():
        raw = (ROOT / path).read_bytes() if path == FIXTURE else git('show', row['baseline'] + ':' + path)
        assert sha(raw) == identity, 'input identity: ' + path
    stdout = unpack(row['stdout']).decode()
    stderr = unpack(row['stderr']).decode()
    if kind == 'knowledge':
        assert case['argv'] == ['bash', '-x', 'knowledge-map/scripts/query_knowledge_map.sh', '--no-cache', QUESTION]
        assert case['expected_stdout'] == ROUTE and stdout == ROUTE, 'literal complete route'
        assert 'exec perl' in stderr and '--no-cache' in stderr, 'actual wrapper trace'
    else:
        trace = '.artifacts/publication-query-intake-20261025/binding/events.trace'
        assert case['argv'] == ['perl', 'bin/fsmgen', '--quiet', '--strict', '--trace-verbosity=debug',
                                '--trace-log=' + trace, '--emit-schedule-json', FIXTURE]
        assert case['trace_file'] == trace and unpack(row['trace']), 'actual producer trace'
        assert stderr == '', 'clean source-query stderr'
        product = json.loads(stdout)
        assert type(product) is dict and case['json_predicates'], 'declared object predicates'
        for predicate in case['json_predicates']:
            actual = product
            for key in predicate['path']:
                actual = actual[key]
            assert actual == predicate['value'], 'literal authored-binding predicate'


def capture(kind, case):
    check_case(kind, case)
    assert os.environ.get('FSMGEN_RAM_GUARD_ACTIVE') == '1', 'normal RAM guard required'
    guard = {'host': os.environ.get('FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT'),
             'descendant_mib': os.environ.get('FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB'),
             'active': os.environ.get('FSMGEN_RAM_GUARD_ACTIVE')}
    assert guard == {'host': '88', 'descendant_mib': '4096', 'active': '1'}
    for prefix in ('bin/fsmgen', 'perl', 'knowledge-map', 'KNOWLEDGE_MAP.md', 'docs/knowledge'):
        subprocess.run(['git', 'diff', '--exit-code', 'HEAD', '--', prefix], cwd=ROOT, check=True)
    output = BASE / (kind + '.json.gz')
    assert not output.exists(), 'retained intake cannot be replayed'
    WORK.mkdir(parents=True, exist_ok=True)
    assert WORK.resolve().is_relative_to(ROOT) and WORK.stat().st_dev == ROOT.stat().st_dev
    slot = WORK / kind
    slot.mkdir(exist_ok=False)
    row = {'owner': 'PUBLICATION-REGRESSION-REPAIRS.7', 'case': case, 'guard': guard,
           'baseline': git('rev-parse', 'HEAD').decode().strip(), 'recipe': Path(__file__).read_text(),
           'bound_seconds': BOUND, 'inputs': {p: sha((ROOT / p).read_bytes()) for p in case['inputs']}}
    row['recipe_sha256'] = sha(row['recipe'].encode())
    row['started_utc'] = datetime.datetime.now(datetime.timezone.utc).isoformat()
    row['started_ns'] = time.monotonic_ns()
    process = None
    with output.open('xb') as retained:
        try:
            process = subprocess.Popen(case['argv'], cwd=ROOT, stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE, start_new_session=True)
            row.update(pid=process.pid, pgid=os.getpgid(process.pid), sid=os.getsid(process.pid),
                       launched_ns=time.monotonic_ns())
            deadline = row['launched_ns'] + BOUND * 1_000_000_000
            (slot / 'state.json').write_text(json.dumps({'state': 'running', **row}, indent=2) + '\n')
            row['timed_out'] = False
            try:
                stdout, stderr = process.communicate(timeout=max(0, (deadline - time.monotonic_ns()) / 1e9))
            except subprocess.TimeoutExpired as error:
                row['timed_out'] = True
                row.update(stdout=packed(error.stdout or b''), stderr=packed(error.stderr or b''))
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                stdout, stderr = process.communicate(timeout=5)
            row.update(returncode=process.returncode, stdout=packed(stdout), stderr=packed(stderr))
            row['lingering_group'] = not group_absent(process.pid)
            if row['lingering_group']:
                os.killpg(process.pid, signal.SIGKILL)
                for _ in range(20):
                    if group_absent(process.pid):
                        break
                    time.sleep(0.05)
            row['group_absent'] = group_absent(process.pid)
            if case['trace_file'] is not None:
                row['trace'] = packed((ROOT / case['trace_file']).read_bytes())
        except BaseException as error:
            row['error'] = str(error).replace(str(ROOT), '<repository>')
            if process is not None and process.poll() is None:
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                    stdout, stderr = process.communicate(timeout=5)
                    row.update(returncode=process.returncode, stdout=packed(stdout), stderr=packed(stderr))
                except (ProcessLookupError, subprocess.TimeoutExpired) as cleanup:
                    row['cleanup_error'] = str(cleanup).replace(str(ROOT), '<repository>')
            if process is not None:
                row['group_absent'] = group_absent(process.pid)
            raise
        finally:
            if case['trace_file'] is not None and (ROOT / case['trace_file']).is_file():
                row['trace'] = packed((ROOT / case['trace_file']).read_bytes())
            row.update(ended_ns=time.monotonic_ns(),
                       ended_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
            with gzip.GzipFile(fileobj=retained, mode='wb', mtime=0) as stream:
                stream.write((json.dumps(row, indent=2) + '\n').encode())
            state = 'finished' if row.get('group_absent', process is None) else 'needs_settlement'
            (slot / 'state.json').write_text(json.dumps({'state': state, 'record': output.relative_to(ROOT).as_posix(),
                                                       'pid': row.get('pid'), 'error': row.get('error')}, indent=2) + '\n')
    validate(kind, case, row)
    print(kind + ': current normal intake captured; historical causality unchanged')


def verify(cases):
    controls = []
    for kind, case in cases.items():
        row = json.loads(gzip.decompress((BASE / (kind + '.json.gz')).read_bytes()))
        validate(kind, case, row)
        for field, value in [('returncode', False), ('group_absent', False),
                             ('started_ns', True), ('recipe_sha256', 'changed')]:
            bad = copy.deepcopy(row)
            bad[field] = value
            try:
                validate(kind, case, bad)
            except AssertionError:
                controls.append(kind + ':' + field)
            else:
                raise AssertionError('altered saved intake accepted: ' + field)
        bad = copy.deepcopy(row)
        bad['stdout'] = packed(b'{}\n' if kind == 'knowledge' else b'{"borrowed":true}\n')
        try:
            validate(kind, case, bad)
        except (AssertionError, KeyError, IndexError):
            controls.append(kind + ':covaried-product')
        else:
            raise AssertionError('covaried wrong product accepted')
    print('Saved normal intake identities, routes/products and settlement verify; controls refuse: ' + ', '.join(controls))


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Saved acceptance assertions must be enabled')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--capture', choices=['knowledge', 'binding'])
    args = parser.parse_args()
    cases = json.loads((BASE / 'contract.json').read_text())['cases']
    if args.capture:
        capture(args.capture, cases[args.capture])
    else:
        verify(cases)
