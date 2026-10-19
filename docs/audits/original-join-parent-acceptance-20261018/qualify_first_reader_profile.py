"""Validate the complete retained profile without repeating the saved reader."""
import argparse
import ast
import base64
import copy
from fractions import Fraction
import gzip
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[3]
AUDIT = 'docs/audits/original-join-parent-acceptance-20261018/'
REVISION = '222feff4463923aa0af8b077e77f1bf49de984f3'
SOURCE = AUDIT + 'profile_first_reader.py'
INPUT = AUDIT + 'first-reader-recoverable-profile.json.gz'
OUTPUT = AUDIT + 'first-reader-profile-qualified.json.gz'


def equal(actual, expected):
    assert type(actual) is type(expected), 'exact primitive kind'
    if isinstance(expected, dict):
        assert actual.keys() == expected.keys(), 'complete object population'
        for key in expected:
            equal(actual[key], expected[key])
    elif isinstance(expected, list):
        assert len(actual) == len(expected), 'complete array population'
        for left, right in zip(actual, expected):
            equal(left, right)
    else:
        assert actual == expected, 'exact value'


def blob(body):
    return dict(bytes=len(body), sha256=hashlib.sha256(body).hexdigest(),
                body_base64=base64.b64encode(body).decode())


def unblob(value):
    body = base64.b64decode(value['body_base64'], validate=True)
    equal(value, blob(body))
    return body


def native():
    argv = ['git', '--no-replace-objects', 'show', REVISION + ':' + SOURCE]
    result = subprocess.run(argv, cwd=ROOT, stdin=subprocess.DEVNULL, capture_output=True, timeout=30)
    assert result.returncode == 0 and result.stderr == b'', 'fixed native collector source'
    return result.stdout


def capacity(total, vm):
    assert re.fullmatch(rb'[1-9][0-9]*\n', total), 'positive native physical bytes'
    page = re.findall(rb'page size of ([0-9]+) bytes', vm)
    assert len(page) == 1 and int(page[0]) > 0, 'one native page-size observation'
    names = ('Pages active', 'Pages inactive', 'Pages speculative', 'Pages wired down',
             'Pages purgeable', 'File-backed pages', 'Pages occupied by compressor')
    counters = {}
    for name in names:
        found = re.findall(rb'^' + re.escape(name.encode()) + rb':\s+([0-9]+)\.$', vm, re.M)
        assert len(found) == 1, 'one native counter: ' + name
        counters[name] = int(found[0])
    # An independent Python integer/rational derivation of the documented
    # occupied-capacity formula; no guard AWK code or rounded log value is used.
    occupied = sum(counters[name] for name in names[:4]) + counters[names[6]] - counters[names[4]] - counters[names[5]]
    assert occupied >= 0
    used = min(occupied * int(page[0]), int(total))
    return dict(used_bytes=used, physical_bytes=int(total),
                percent_rational=[Fraction(used * 100, int(total)).numerator,
                                  Fraction(used * 100, int(total)).denominator])


def process_members(body, root_pid):
    rows = {}
    for line in body.splitlines():
        parts = line.split()
        assert len(parts) == 3 and all(part.isdigit() for part in parts), 'PID/parent/RSS-only process wire'
        pid, parent, rss = map(int, parts)
        assert pid not in rows and pid > 0 and parent >= 0 and rss >= 0
        rows[pid] = (parent, rss)
    if root_pid not in rows:
        return []
    closure = {root_pid}
    while True:
        expanded = closure | {pid for pid, (parent, _) in rows.items() if parent in closure}
        if expanded == closure:
            break
        closure = expanded
    # Ancestor walking is a distinct membership algorithm on the same wire;
    # it does not independently establish the OS's RSS accounting accuracy.
    walked = set()
    for pid in rows:
        current, seen = pid, set()
        while current in rows and current not in seen:
            if current == root_pid:
                walked.add(pid)
                break
            seen.add(current)
            current = rows[current][0]
    assert walked == closure, 'independent descendant allocation'
    return [dict(pid=pid, parent=rows[pid][0], rss_kib=rows[pid][1]) for pid in sorted(closure)]


def review(value, collector):
    assert set(value) == {'schema', 'command', 'status', 'programme', 'missing', 'retained',
                          'outer_stdout', 'outer_stderr', 'partial_directory', 'scope'}, 'complete capture metadata'
    equal(value['schema'], 'fsmgen.isolated_reader_profile_capture.v1')
    equal(value['scope'], 'Exact actual isolated current-reader observation. Raw interval snapshots and phase/guard streams retain even if completion is missing; original complete-peak, exclusive-host cause, native/private and semantic-cohort permissions remain unproved and unchanged.')
    directory = value['partial_directory']
    assert type(directory) is str and re.fullmatch(r'\.artifacts/tmp/tests/first-reader-profile-[a-z0-9_]+', directory)
    equal(unblob(value['outer_stdout']), (directory + '\nRetained complete diagnostic at ' + directory + '\n').encode())
    outer_guard = re.fullmatch(rb'ram-guard: PID ([0-9]+); host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', unblob(value['outer_stderr']))
    assert outer_guard, 'unchanged complete outer guard'
    collector_pid = int(outer_guard[1])
    equal(value['command'], ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', SOURCE, '--run'])
    equal(value['status'], 0)
    equal(value['programme'], blob(collector))
    equal(value['missing'], [])
    files = value['retained']
    assert set(files) == {'started.json', 'samples.jsonl', 'stdout.bin', 'stderr.bin', 'finished.json'}, 'complete actual file population'
    started = json.loads(unblob(files['started.json']))
    assert set(started) == {'programme', 'command', 'fixture'}
    equal(started['programme'], blob(collector))
    equal(started['fixture'], False)
    tree = ast.parse(collector)
    tracer = [ast.literal_eval(node.value) for node in ast.walk(tree) if isinstance(node, ast.Assign)
              and any(isinstance(target, ast.Name) and target.id == 'tracer' for target in node.targets)]
    assert len(tracer) == 1
    equal(started['command'], ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', '-c', tracer[0]])
    equal(json.loads(unblob(files['finished.json'])), dict(status=0))
    equal(unblob(files['stdout.bin']), b'Failed prerequisite custody and exact-source epoch diagnosis pass; the cohort remains failed and later execution is gated.\n')
    stderr = unblob(files['stderr.bin'])
    guard = re.findall(rb'^ram-guard: PID ([0-9]+); host ([0-9.]+)%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s$', stderr, re.M)
    assert len(guard) == 1 and b'terminating PID tree' not in stderr, 'complete unchanged successful inner guard'
    root_pid = int(guard[0][0])
    events = [json.loads(line) for line in stderr.splitlines() if line.startswith(b'{')]
    assert events
    assert all(line.startswith(b'{') or re.fullmatch(rb'ram-guard: PID [0-9]+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s', line)
               for line in stderr.splitlines()), 'complete declared stderr protocol'
    vocabulary = {'prepare.py': {'premises'}, 'verify_execution.py': {'load', 'sources', 'validate_sources'},
                  'verify_failed.py': {'failed', 'controls', 'diagnosis'}}
    stack = []
    for event in events:
        assert set(event) == {'event', 'function', 'source', 'maxrss_raw'}
        assert event['event'] in ('call', 'return') and type(event['maxrss_raw']) is int and event['maxrss_raw'] >= 0
        assert event['function'] in vocabulary.get(event['source'], set()), 'native tracer phase vocabulary'
        frame = (event['source'], event['function'])
        if event['event'] == 'call':
            stack.append(frame)
        else:
            assert stack and stack.pop() == frame, 'complete phase call/return nesting'
    assert not stack, 'complete phase return population'
    for phase in ('failed', 'controls', 'diagnosis'):
        assert any(row['function'] == phase and row['source'] == 'verify_failed.py' and row['event'] == 'return' for row in events), 'completed current phase: ' + phase
    samples = [json.loads(line) for line in unblob(files['samples.jsonl']).splitlines()]
    assert samples, 'actual retained sample population'
    result = []
    observed_lineage = False
    for row in samples:
        assert set(row) == {'host', 'processes'}
        assert len(row['host']) == 2
        expected = [['sysctl', '-n', 'hw.memsize'], ['vm_stat'], ['ps', '-axo', 'pid=,ppid=,rss=']]
        receipts = [*row['host'], row['processes']]
        for receipt, command in zip(receipts, expected):
            assert set(receipt) == {'command', 'status', 'stdout', 'stderr'}
            equal(receipt['command'], command)
            equal(receipt['status'], 0)
            equal(unblob(receipt['stderr']), b'')
        processes = unblob(receipts[2]['stdout'])
        observed_lineage |= any(member['pid'] == root_pid for member in process_members(processes, collector_pid))
        result.append(dict(capacity=capacity(unblob(receipts[0]['stdout']), unblob(receipts[1]['stdout'])),
            descendants=process_members(processes, root_pid)))
    assert any(row['descendants'] for row in result), 'observed actual guarded root membership'
    assert observed_lineage, 'observed guarded root belongs to its collector'
    return dict(samples=result, phases=events, root_pid=root_pid,
        scope='One instrumented current-reader success under unchanged guards. Same-snapshot integer/rational capacity and two descendant membership algorithms derive from retained raw wires. OS RSS accuracy, between-sample peaks, original-event simultaneous counters/exclusive cause and future capacity guarantees remain unproved. This does not qualify the complete wrapper or original semantic/custody/native/private gates.')


def main():
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    collector = native()
    raw = (ROOT / INPUT).read_bytes()
    value = json.loads(gzip.decompress(raw))
    result = review(value, collector)
    controls = []
    for label, mutation in (
        ('boolean-outer-status', lambda x: x.__setitem__('status', False)),
        ('missing-member', lambda x: x['retained'].pop('samples.jsonl')),
        ('wrong-producer', lambda x: x.__setitem__('programme', blob(b'changed programme'))),
        ('borrowed-scope', lambda x: x.__setitem__('scope', 'borrowed original success and exclusive old host causation')),
        ('wrong-partial-route', lambda x: x.__setitem__('partial_directory', '.artifacts/tmp/tests/first-reader-profile-other')),
        ('false-inner-success', lambda x: x['retained'].__setitem__('finished.json', blob(b'{"status":false}\n'))),
        ('lost-phases', lambda x: x['retained'].__setitem__('stderr.bin', blob(b''))),
        ('unexpected-stderr', lambda x: x['retained'].__setitem__('stderr.bin', blob(unblob(x['retained']['stderr.bin']) + b'borrowed original success\n'))),
        ('lost-samples', lambda x: x['retained'].__setitem__('samples.jsonl', blob(b''))),
    ):
        candidate = copy.deepcopy(value)
        mutation(candidate)
        try:
            review(candidate, collector)
        except AssertionError as error:
            controls.append(dict(label=label, candidate=candidate, refusal=str(error)))
        else:
            raise AssertionError('changed profile admitted: ' + label)
    product = dict(input=blob(raw), collector=blob(collector), result=result, controls=controls,
                   programme=blob(Path(__file__).read_bytes()))
    output = ROOT / OUTPUT
    if args.write:
        with output.open('xb') as stream:
            stream.write(gzip.compress((json.dumps(product, sort_keys=True) + '\n').encode(), mtime=0))
    else:
        equal(json.loads(gzip.decompress(output.read_bytes())), product)
    print('Complete isolated current-reader success, native collector and raw observation boundaries qualify; original causality remains unproved.')


if __name__ == '__main__':
    main()
