"""Independent byte census and cold checks; no parser, scheduler or HDL run."""
import copy
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

BASE = Path(__file__).parent


def baseline_sources(revision):
    # Batch immutable Git blobs, not later worktree bytes. This archive remains
    # cold-replayable after its separately owned consumer repair.
    names = subprocess.check_output([
        'git', 'ls-tree', '-r', '--name-only', revision,
        '--', 't', 'perl', 'scripts', 'bin']).decode().splitlines()
    blobs = subprocess.Popen(['git', 'cat-file', '--batch'],
                             stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    values = {}
    try:
        for name in names:
            blobs.stdin.write((revision + ':' + name + '\n').encode())
            blobs.stdin.flush()
            header = blobs.stdout.readline().split()
            assert len(header) == 3 and header[1] == b'blob'
            raw = blobs.stdout.read(int(header[2]))
            assert blobs.stdout.read(1) == b'\n'
            values[name] = raw
    finally:
        blobs.stdin.close()
        blobs.stdout.close()
        assert blobs.wait() == 0
    return values


def verify_discovery(data):
    files = []
    records = []
    for name, raw in sorted(SOURCES.items()):
        path = Path(name)
        first = raw.split(b'\n', 1)[0]
        if path.suffix not in {'.t', '.pm', '.pl', '.py'} and not (
                first.startswith(b'#!') and b'perl' in first):
            continue
        files.append(name)
        assert data['producers'][name] == {
            'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
        lines = raw.splitlines(keepends=True)
        for index, line in enumerate(lines):
            words = line.split()
            if len(words) < 2 or words[0] != b'sub' or not line.startswith(b'sub '):
                continue
            match = re.match(rb'([A-Za-z_]\w*)', words[1])
            if not match:
                continue
            # This deliberately re-derives only the declared lexical span,
            # rather than pretending to parse Perl or delegated predicates.
            if line.rstrip().endswith(b'}'):
                span = line.rstrip(b'\n')
            else:
                end = next((n for n in range(index + 1, len(lines))
                            if re.fullmatch(rb'}\s*(?:#.*)?', lines[n].rstrip(b'\n'))), None)
                if end is None:
                    continue
                tail = b''.join(lines[end:])
                close = re.match(rb'}\s*(?:#.*)?(?=\n|\Z)', tail)
                assert close is not None
                span = b''.join(lines[index:end]) + tail[:close.end()]
            if not (re.search(rb'\b(?:like|unlike)\s*\(', span)
                    or re.search(rb'\$@\s*=~', span)):
                continue
            if not (re.search(rb'\b(?:eval|diagnostic|error)\b', span) or b'$@' in span):
                continue
            records.append((name, match[1].decode(), index + 1, span))
    assert sorted(files) == data['files'] == sorted(data['producers'])
    actual = [(r['path'], r['function'], r['line'],
               r['span'].encode('utf-8', 'surrogateescape')) for r in data['records']]
    assert actual == records
    for record, (_, _, _, span) in zip(data['records'], records):
        assert record['span_sha256'] == hashlib.sha256(span).hexdigest()
        assert record['named_refusal_helper'] == bool(
            re.match(r'(?:refus|reject|fail|declin)', record['function']))


def verify_helpers(data):
    for bound in data['bindings']:
        raw = SOURCES[bound['path']]
        assert hashlib.sha256(raw).hexdigest() == bound['source_sha256']
        helper = bound['helper'].encode()
        assert helper in raw
        assert hashlib.sha256(helper).hexdigest() == bound['helper_sha256']
    rows = {(r['kind'], r['mode']): r for r in data['results']}
    assert set(rows) == {(kind, mode) for kind in ('file', 'value')
                         for mode in ('wrong_echo', 'correct')}
    for (kind, mode), row in rows.items():
        assert row['first_line'] == row['error'].splitlines()[0] == (
            'file origin independent document set required')
        assert ' at t/lib/FSM/Test/FileDocumentOriginAuthority.pm line 21' in row['error']
        expected = 'oracle_echo_expected_marker' if mode == 'wrong_echo' else row['first_line']
        first_matches = expected in row['first_line']
        full_matches = expected in row['error']
        assert row['first_line_matches'] == int(first_matches)
        assert row['full_trace_matches'] == int(full_matches) == 1
        assert first_matches == (mode == 'correct')
        if kind == 'file':
            assert row['controls'] == [{'name': kind + '-' + mode,
                                       'accepted': 0, 'diagnostic': row['first_line']}]
        else:
            assert row['controls'] == []
        if mode == 'wrong_echo':
            subject = row['error'] if '--wrong-subject' in sys.argv else row['first_line']
            assert expected not in subject, 'caller echo is not the actual reason'
    tap = (BASE / 'helper-probe.txt').read_text()
    assert 'ok 2 - precise actual file authority refusal' in tap
    assert 'not ok 6 - value-wrong_echo names the cause in its diagnostic line' in tap
    assert 'failed 1 test of 8' in tap and '1..8' in tap


discovery = json.loads((BASE / 'candidates.json').read_text())
helpers = json.loads((BASE / 'helper-controls.json').read_text())
SOURCES = baseline_sources(discovery['baseline'])
verify_discovery(discovery)
verify_helpers(helpers)
controls = []
for label in ('missing-file', 'changed-span', 'missing-record', 'wrong-source-hash'):
    changed = copy.deepcopy(discovery)
    if label == 'missing-file':
        changed['files'].pop()
    elif label == 'changed-span':
        changed['records'][0]['span'] += ' '
    elif label == 'missing-record':
        changed['records'].pop()
    else:
        changed['producers'][changed['files'][0]]['sha256'] = '0' * 64
    try:
        verify_discovery(changed)
    except AssertionError:
        controls.append(label)
    else:
        raise AssertionError('corruption accepted: ' + label)
print(json.dumps({'status': 'qualified bounded discovery',
                  'files': len(discovery['files']), 'spans': len(discovery['records']),
                  'named_refusal_spans': sum(r['named_refusal_helper'] for r in discovery['records']),
                  'shared_corruptions_rejected': controls,
                  'actual_file_helper': 'vulnerable; repair separately owned',
                  'actual_value_helper': 'first-line precedent rejects caller echo'}, sort_keys=True))
