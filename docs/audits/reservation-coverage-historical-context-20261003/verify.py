"""Cold independent source/context identity and genuine decoy qualification."""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/reservation-coverage-historical-context-20261003')
parser = argparse.ArgumentParser()
parser.add_argument('--trust-decoy', action='store_true')
options = parser.parse_args()


def digest(raw): return hashlib.sha256(raw).hexdigest()


if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == row['bytes'] and digest(raw) == row['sha256'], name
binding = json.loads((BASE / 'bindings.json').read_text())
assert binding['revision'] == '93ff524834b748004510e10befad4df4cd8cc5fe'
assert binding['reader'] == 'docs/audits/reservation-coverage-source-copy-checks-20261003/reverify.py'
raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + binding['reader']])
assert len(raw) == binding['reader_bytes'] and digest(raw) == binding['reader_sha256']
assert 'reservation-coverage-qualification-join-20261003/verify.py' in raw.decode()
assert 'reservation-coverage-cause-repair-checks-20261003/verify.py' in raw.decode()
records = {mode: json.loads((BASE / (mode + '-context.json')).read_text()) for mode in ('ordinary', 'decoy')}
expected = {}
# Independently enumerate separate literal source roots and their immutable
# Git object identities; no producer classifier or projection code is imported.
for prefix in ('bin', 'perl', 't', 'scripts', 'isf', 'docs/audits', 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'):
    raw = subprocess.check_output(['git', 'ls-tree', '-r', '-z', binding['revision'], '--', prefix])
    for entry in raw.split(b'\0'):
        if not entry: continue
        header, raw_name = entry.split(b'\t', 1)
        bits, kind, blob = header.decode().split(); name = raw_name.decode()
        if prefix == 'docs/audits' and not name.startswith('docs/audits/reservation-coverage-'): continue
        assert bits in ('100644', '100755') and kind == 'blob'
        assert name not in expected
        expected[name] = {'blob': blob, 'mode': bits}
with subprocess.Popen(['git', 'cat-file', '--batch'], stdin=subprocess.PIPE, stdout=subprocess.PIPE) as objects:
    for name, row in expected.items():
        objects.stdin.write((row['blob'] + '\n').encode()); objects.stdin.flush()
        header = objects.stdout.readline().decode().split()
        assert header[:2] == [row['blob'], 'blob'] and len(header) == 3
        body = objects.stdout.read(int(header[2])); assert objects.stdout.read(1) == b'\n'
        row.update(bytes=len(body), sha256=digest(body))
    objects.stdin.close(); assert objects.wait() == 0
assert len(expected) == 3472 and sum(r['bytes'] for r in expected.values()) == 162992888
for mode, record in records.items():
    assert set(record) == {'revision', 'reader', 'mode', 'members', 'mismatches', 'reader_status',
        'primary_git_before', 'primary_git_after', 'primary_revision_before', 'primary_revision_after', 'workspace', 'same_volume'}
    assert record['revision'] == binding['revision'] and record['reader'] == binding['reader'] and record['mode'] == mode
    assert record['members'] == expected
    assert record['workspace'] == binding['workspace'] + '/' + binding['revision'] + '/' + mode
    assert not Path(record['workspace']).is_absolute() and '..' not in Path(record['workspace']).parts
    assert record['same_volume'] is True
    assert record['primary_revision_before'] == record['primary_revision_after'] == binding['revision']
    assert set(record['primary_git_before']) == {'index', 'config', 'HEAD'}
    assert record['primary_git_before'] == record['primary_git_after']
    assert all(len(v) == 64 and set(v) <= set('0123456789abcdef') for v in record['primary_git_before'].values())
    assert record['mismatches'] == ([] if mode == 'ordinary' else ['t/1960-isf-formal-reservation-coverage.t'])
    assert type(record['reader_status']) is int and record['reader_status'] == int(mode == 'decoy')
    assert (BASE / (mode + '.status')).read_text().strip() == str(record['reader_status'])
    receipt = (BASE / (mode + '.txt')).read_text()
    if mode == 'ordinary':
        assert 'PASS complete initial/current Git/source and done semantic/control owners' in receipt
        assert 'PASS complete-cause correction/source/graph closure, conserved whole ordinary products' in receipt
        assert 'Traceback (most recent call last):' not in receipt
    else:
        causes = [l for l in receipt.splitlines() if l.startswith('AssertionError:')]
        assert causes == ['AssertionError: t/1960-isf-formal-reservation-coverage.t']
        assert 'reservation-coverage-cause-repair-checks-20261003/verify.py' in receipt
        if options.trust_decoy:
            assert record['mismatches'] == [], 'actual projected source decoy cannot authenticate pinned original qualification'
assert records['ordinary']['members'] == records['decoy']['members']
print('PASS exact pinned canonical cause/copy qualification and owning task context: all3472 selected Git source/audit files /162992888 bytes independently authenticate; primary index/config/HEAD and revision remain unchanged within both captured invocations.')
print('PASS actual projected T1960 source-only decoy fails original complete source identity; ordinary pinned replay closes full qualified semantics/controls without rewriting archives or claiming hot-source currency.')
print('SCOPE: replay projects into repository-owned same-volume data with an explicitly separate Git index and the primary object store; no new repository, worktree registration or primary config/index change. Live helper repair remains .13.2-owned.')
if not options.trust_decoy:
    assert (BASE / 'trust-decoy.status').read_text().strip() == '1'
    assert (BASE / 'trust-decoy.txt').read_text().splitlines()[-1] == 'AssertionError: actual projected source decoy cannot authenticate pinned original qualification'
