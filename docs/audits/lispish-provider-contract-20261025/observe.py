#!/usr/bin/env python3
"""Capture this declared provider intake once; otherwise review saved records."""
import argparse
import base64
import copy
import datetime
import gzip
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import time

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
WORK = ROOT / '.artifacts/lispish-provider-contract-20261025'


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def packed(raw):
    normalized = raw.replace(str(ROOT).encode(), b'<repository>')
    return dict(base64=base64.b64encode(normalized).decode(), bytes=len(normalized),
                sha256=digest(normalized), original_bytes=len(raw), original_sha256=digest(raw))


def unpack(value):
    raw = base64.b64decode(value['base64'], validate=True)
    assert type(value['bytes']) is int and len(raw) == value['bytes']
    assert digest(raw) == value['sha256'], 'stream identity'
    return raw


def group_absent(pid):
    try:
        os.killpg(pid, 0)
    except ProcessLookupError:
        return True
    return False


def inputs(contract):
    return {name: digest((ROOT / name).read_bytes()) for name in contract['inputs']}


def capture(contract, text, case):
    assert case['id'] in ('imports', 'discovery', 'canonical', 'syntax', 'stability')
    assert case['argv'][:3] == ['perl', '-Iperl', '-e'] and len(case['argv']) == 4
    assert inputs(contract) == contract['inputs'], 'declared input changed'
    assert WORK.parent.resolve().is_relative_to(ROOT)
    WORK.mkdir(exist_ok=True)
    assert WORK.stat().st_dev == ROOT.stat().st_dev
    slot = WORK / case['id']
    slot.mkdir(exist_ok=False)
    output = BASE / (case['id'] + '.json.gz')
    assert not output.exists(), 'refusing to replace a retained intake'
    row = dict(owner=contract['owner'], baseline=contract['baseline'], case=case,
               contract_sha256=digest(text), recipe=Path(__file__).read_text(),
               inputs_before=inputs(contract), bound_seconds=60,
               started_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
               started_ns=time.monotonic_ns(), timed_out=False, forced_cleanup=False)
    row['recipe_sha256'] = digest(row['recipe'].encode())
    process = None
    failure = None
    state = slot / 'state.json'
    state.write_text(json.dumps({'state': 'starting', **row}, indent=2) + '\n')
    with (slot / 'stdout').open('xb') as out, (slot / 'stderr').open('xb') as err:
        try:
            # The lightweight recorder remains outside the guarded command tree.
            process = subprocess.Popen(['scripts/run_with_ram_guard.sh', '--'] + case['argv'],
                cwd=ROOT, stdin=subprocess.DEVNULL, stdout=out, stderr=err,
                start_new_session=True)
            row.update(guard_pid=process.pid, new_session_requested=True,
                       launched_ns=time.monotonic_ns())
            state.write_text(json.dumps({'state': 'running', **row}, indent=2) + '\n')
            remaining = max(0, (row['started_ns'] + 60_000_000_000 - time.monotonic_ns()) / 1e9)
            try:
                process.wait(timeout=remaining)
            except subprocess.TimeoutExpired:
                row['timed_out'] = True
                os.killpg(process.pid, signal.SIGKILL)
                process.wait(timeout=5)
        except BaseException as error:
            failure = error
            row['error'] = str(error).replace(str(ROOT), '<repository>')
        finally:
            row['ended_ns'] = time.monotonic_ns()
            if process is not None and process.poll() is None:
                os.killpg(process.pid, signal.SIGKILL)
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    row['unreaped'] = True
            row['returncode'] = process.returncode if process is not None else None
            if process is not None:
                for _ in range(20):
                    if group_absent(process.pid):
                        break
                    time.sleep(.05)
                if not group_absent(process.pid):
                    row['forced_cleanup'] = True
                    os.killpg(process.pid, signal.SIGKILL)
                    for _ in range(20):
                        if group_absent(process.pid):
                            break
                        time.sleep(.05)
                row['group_absent'] = group_absent(process.pid)
            row.update(settled_ns=time.monotonic_ns(),
                       ended_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
    for channel in ('stdout', 'stderr'):
        raw_path = slot / channel
        if raw_path.stat().st_size <= 1_048_576:
            row[channel] = packed(raw_path.read_bytes())
        else:
            row[channel + '_oversized_raw'] = raw_path.relative_to(ROOT).as_posix()
    row['inputs_after'] = inputs(contract)
    with output.open('xb') as stream:
        stream.write(gzip.compress((json.dumps(row, indent=2) + '\n').encode(), mtime=0))
    state.write_text(json.dumps({'state': 'finished' if row.get('group_absent') and
        not row.get('unreaped') else 'needs_settlement',
        'record': output.relative_to(ROOT).as_posix(), 'guard_pid': row.get('guard_pid')}, indent=2) + '\n')
    print(f"{case['id']}: guard_status={row['returncode']}, timeout={row['timed_out']}, "
          f"group_absent={row.get('group_absent')}", flush=True)
    if failure is not None:
        raise failure


def check(contract, text, case, row):
    assert row['owner'] == contract['owner'] and row['baseline'] == contract['baseline']
    assert row['case'] == case and row['contract_sha256'] == digest(text), 'declared case identity'
    assert row['recipe'] == Path(__file__).read_text()
    assert row['recipe_sha256'] == digest(row['recipe'].encode())
    assert row['inputs_before'] == row['inputs_after'] == contract['inputs']
    assert type(row['returncode']) is int and row['returncode'] == case['expected_returncode'], 'actual guard status'
    assert row['timed_out'] is False and row['forced_cleanup'] is False
    assert row['group_absent'] is True and not row.get('unreaped'), 'settled group'
    assert row['bound_seconds'] == 60 and row['new_session_requested'] is True
    assert all(type(row[key]) is int and row[key] > 0 for key in
               ('guard_pid', 'started_ns', 'launched_ns', 'ended_ns', 'settled_ns'))
    assert row['started_ns'] <= row['launched_ns'] <= row['ended_ns'] <= row['settled_ns']
    assert row['ended_ns'] - row['started_ns'] < 60_000_000_000
    stdout, stderr = unpack(row['stdout']).decode(), unpack(row['stderr']).decode()
    header = re.fullmatch(r'ram-guard: PID ([0-9]+); host [0-9.]+%; host cutoff 88%; '
                          r'descendant RSS cutoff 4096 MiB; poll 2s\n', stderr)
    assert header, 'complete stderr is the declared guard header only'
    if case['kind'] == 'syntax':
        assert stdout == contract['expected_syntax_stdout'], 'literal syntax diagnostic'
        return
    data = json.loads(stdout)
    assert type(data['pid']) is int and data['pid'] == int(header[1]), 'actual worker PID join'
    if case['kind'] == 'imports':
        assert set(data) == {'pid', 'modules'} and type(data['modules']) is dict
        assert all(name in data['modules'] for name in
                   ('Lispish.pm', 'PPlugin.pm', 'LinkedSpec.pm', 'PathSearch.pm', 'Global.pm', 'HUtils.pm'))
    elif case['kind'] == 'discovery':
        assert set(data) == {'pid', 'phase', 'roots', 'error'}
        assert data['phase'] == 'parse' and data['roots'] == ['.']
        assert 'PARSER_DISCOVERY_BOUNDARY' in data['error']
    elif case['kind'] == 'forms':
        assert set(data) == {'pid', 'cases'}
        assert len(data['cases']) == len(contract['literal_fixtures']), 'finite fixture closure'
        for actual, expected in zip(data['cases'], contract['literal_fixtures']):
            assert set(actual) == {'id', 'forms', 'source_after', 'pos'}
            assert actual['id'] == expected['id'] and actual['forms'] == expected['expected'], 'literal canonical AST'
            assert actual['source_after'] == expected['source']
            assert actual['pos'] is None or type(actual['pos']) is int
    else:
        assert case['kind'] == 'stability' and set(data) == {'pid', 'before', 'after', 'error'}
        assert data['before'] == contract['desired_stability_ast']
        assert data['after'] is None and re.search(r'undefined.*subroutine', data['error'], re.I), 'declared shared-root RED'


def verify(contract, text):
    for name, expected in contract['inputs'].items():
        raw = ((ROOT / name).read_bytes() if name.endswith('/inputs.json') else
               subprocess.check_output(['git', 'show', contract['baseline'] + ':' + name], cwd=ROOT))
        assert digest(raw) == expected, 'native original input identity'
    rows = {}
    for case in contract['cases']:
        row = json.loads(gzip.decompress((BASE / (case['id'] + '.json.gz')).read_bytes()))
        check(contract, text, case, row)
        rows[case['id']] = row
    for key, value, message in [('returncode', False, 'actual guard status'),
                                 ('group_absent', False, 'settled group')]:
        bad = copy.deepcopy(rows['canonical']); bad[key] = value
        try:
            check(contract, text, contract['cases'][2], bad)
        except AssertionError as error:
            assert str(error) == message
        else:
            raise AssertionError('altered mechanism admitted')
    bad = copy.deepcopy(rows['canonical']); data = json.loads(unpack(bad['stdout']))
    data['cases'][0]['forms'] = [['wrong']]
    bad['stdout'] = packed((json.dumps(data) + '\n').encode())
    try:
        check(contract, text, contract['cases'][2], bad)
    except AssertionError as error:
        assert str(error) == 'literal canonical AST'
    else:
        raise AssertionError('covaried wrong AST admitted')
    print('Saved provider witnesses verify; discovery93 and stability71 are RED causes, '
          'not successful parses. Wrong status/type/settlement/covaried AST controls refuse.')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Evidence assertions must be enabled')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--capture', action='store_true')
    args = parser.parse_args()
    text = (BASE / 'contract.json').read_bytes()
    contract = json.loads(text)
    assert contract['bound_seconds'] == 60 and contract['guard'] == {'host_pct': 88, 'descendant_mib': 4096}
    if args.capture:
        for case in contract['cases']:
            capture(contract, text, case)
    verify(contract, text)
