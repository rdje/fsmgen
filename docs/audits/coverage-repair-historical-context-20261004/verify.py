"""Independent pinned source and full published-index contextual readback."""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
parser.add_argument('--trust-decoy', action='store_true')
parser.add_argument('--omit-member', action='store_true')
parser.add_argument('--corrupt-index-view', action='store_true')
args = parser.parse_args()
if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256'], name
binding = json.loads((BASE / 'binding.json').read_text())
assert binding['revision'] == '3951ccbc6eb95612adb6db00f3b4af559d05325b'
assert binding['reader'] == 'docs/audits/reservation-coverage-copy-repair-20261003/verify.py'
reader = subprocess.check_output(['git', 'show', binding['revision'] + ':' + binding['reader']])
assert len(reader) == binding['reader_bytes'] and hashlib.sha256(reader).hexdigest() == binding['reader_sha256']
assert b"after = path.read_bytes()" in reader and b"binding['public_sources']" in reader
assert b'live 39-copy/23-snapshot repair' in reader
expected = {}
for prefix in ('bin', 'perl', 't', 'scripts', 'isf', 'docs/audits', 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'):
    entries = subprocess.check_output(['git', 'ls-tree', '-r', '-z', binding['revision'], '--', prefix])
    for entry in entries.split(b'\0'):
        if not entry: continue
        header, name = entry.split(b'\t', 1)
        bits, kind, blob = header.decode().split(); name = name.decode()
        if prefix == 'docs/audits' and not name.startswith('docs/audits/reservation-coverage-'): continue
        assert bits in ('100644', '100755') and kind == 'blob' and name not in expected
        expected[name] = {'blob': blob, 'mode': bits}
with subprocess.Popen(['git', 'cat-file', '--batch'], stdin=subprocess.PIPE, stdout=subprocess.PIPE) as objects:
    for name, row in expected.items():
        objects.stdin.write((row['blob'] + '\n').encode()); objects.stdin.flush()
        header = objects.stdout.readline().decode().split()
        assert header[:2] == [row['blob'], 'blob'] and len(header) == 3
        raw = objects.stdout.read(int(header[2])); assert objects.stdout.read(1) == b'\n'
        row.update(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
    objects.stdin.close(); assert objects.wait() == 0
index_expected = []
for entry in subprocess.check_output(['git', 'ls-tree', '-r', '-z', binding['revision']]).split(b'\0'):
    if not entry: continue
    header, name = entry.split(b'\t', 1)
    bits, kind, blob = header.decode().split()
    assert kind in ('blob', 'commit')
    index_expected.append({'path': name.decode(), 'mode': bits, 'blob': blob, 'stage': 0})
records = {mode: json.loads((BASE / (mode + '-context.json')).read_text()) for mode in ('ordinary', 'decoy')}
for mode, record in records.items():
    assert record['revision'] == binding['revision'] and record['reader'] == binding['reader'] and record['mode'] == mode
    members = dict(record['members'])
    if args.omit_member and mode == 'ordinary': members.pop(next(iter(members)))
    assert members == expected, 'complete pinned source/audit/task membership'
    assert record['workspace'] == binding['workspace'] + '/' + binding['revision'] + '/' + mode
    assert not Path(record['workspace']).is_absolute() and '..' not in Path(record['workspace']).parts
    assert record['same_volume'] is True
    assert record['primary_git_before'] == record['primary_git_after']
    assert set(record['primary_git_before']) == {'index', 'config', 'HEAD'}
    assert record['primary_revision_before'] == record['primary_revision_after']
    assert len(record['primary_revision_before']) == 40
    assert all(len(v) == 64 for v in record['primary_git_before'].values())
    index_before = record['index_public_before']
    if args.corrupt_index_view and mode == 'ordinary':
        index_before = [dict(r) for r in index_before]
        next(r for r in index_before if r['path'] == 't/1983-isf-interface-port-metadata.t')['blob'] = '0' * 40
    assert index_before == record['index_public_after'] == index_expected, 'complete published separate-index identities'
    assert record['index_sha256_before'] == record['index_sha256_after'] and len(record['index_sha256_before']) == 64
    assert record['mismatches'] == ([] if mode == 'ordinary' else ['t/1983-isf-interface-port-metadata.t'])
    assert record['reader_status'] == int(mode == 'decoy')
    assert int((BASE / (mode + '.status')).read_text()) == record['reader_status']
    output = (BASE / (mode + '.txt')).read_text()
    if mode == 'ordinary':
        assert 'PASS live 39-copy/23-snapshot repair, 12 preparations/10 complete lowerings/carriers, 39 native cause cases' in output
        assert 'PASS exact pinned canonical cause/copy qualification and owning task context' in output
        assert 'Traceback (most recent call last):' not in output
    else:
        assert [line for line in output.splitlines() if line.startswith('AssertionError:')] == ['AssertionError: t/1983-isf-interface-port-metadata.t']
        if args.trust_decoy:
            assert record['mismatches'] == [], 'actual unrelated source decoy cannot authenticate original repaired coverage'
assert records['ordinary']['members'] == records['decoy']['members']
canonical = json.loads((BASE / 'canonical-binding.json').read_text())
before = subprocess.check_output(['git', 'show', canonical['revision_before'] + ':' + canonical['path']])
assert before == (BASE / 'canonical-before.py').read_bytes()
assert hashlib.sha256(before).hexdigest() == canonical['before_sha256']
after = (BASE / 'canonical-after.py').read_bytes()
assert hashlib.sha256(after).hexdigest() == canonical['after_sha256']
assert b'coverage-repair-historical-context-20261004/run_context.py' in after
assert b'reservation-coverage-historical-context-20261003/run_context.py' in after
assert b'reservation-coverage-copy-repair-20261003/verify.py' not in after
assert b'later hot-source changes require their own validation' in after
print('PASS complete pinned repaired-coverage source/audit/task membership and whole published separate-index identities; unchanged primary/index state and actual unrelated T1983 source decoy independently close historical context without changing sealed evidence or claiming hot-source currency.')
print('MEASURED:', len(expected), 'selected members;', sum(r['bytes'] for r in expected.values()), 'logical source bytes;', len(index_expected), 'published index entries.')
