"""Verify dated deletion and immutable Git reproduction without deleting again."""
import argparse
import copy
import hashlib
import json
import re
import stat
import subprocess
from datetime import datetime
from pathlib import Path

BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
parser.add_argument('--trust-decoy-as-original', action='store_true')
parser.add_argument('--omit-file', action='store_true')
parser.add_argument('--alter-protected', action='store_true')
args = parser.parse_args()
if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, record in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == record['bytes'] and hashlib.sha256(raw).hexdigest() == record['sha256'], name
report = json.loads((BASE / 'result.json').read_text())
revision = '93ff524834b748004510e10befad4df4cd8cc5fe'
prefix = '.artifacts/reservation-coverage-historical-context-20261003/' + revision
targets = [prefix + '/ordinary', prefix + '/decoy']
assert report['owner'] == 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.68'
assert (datetime.fromisoformat(report['utc']) - datetime.fromisoformat(report['prior_utc'])).total_seconds() > 86400
assert report['cleanup_revision'] == '1ff946bd1be974ad05e2c76fac4358c9c1b28ade'
assert [row['path'] for row in report['removed']] == targets
assert report['residue'] == {path: False for path in targets}
git_rows = {}
for entry in subprocess.check_output(['git', 'ls-tree', '-r', '-z', revision]).split(b'\0'):
    if not entry: continue
    header, name = entry.split(b'\t', 1); mode, kind, blob = header.decode().split()
    git_rows[name.decode()] = [mode, blob]
contexts = Path('docs/audits/reservation-coverage-historical-context-20261003')
for mode, row in zip(('ordinary', 'decoy'), report['removed']):
    context = json.loads((contexts / (mode + '-context.json')).read_text())
    assert context['revision'] == row['git_revision'] == revision
    assert row['index_rows'] == git_rows and row['index_entries'] == len(git_rows)
    expected = {row['path'] + '/index'} | {row['path'] + '/tree/' + name for name in context['members']}
    files = copy.deepcopy(row['files'])
    if args.omit_file and mode == 'ordinary': files.pop()
    assert {r['path'] for r in files} == expected, 'complete removed file membership'
    assert len(files) == len(expected) == 3473
    assert len({r['path'] for r in files}) == len(files)
    assert sum(r['bytes'] for r in files) == row['bytes_total']
    by_name = {r['path']: r for r in files}
    for name, original in context['members'].items():
        raw = subprocess.check_output(['git', 'show', revision + ':' + name])
        assert len(raw) == original['bytes'] and hashlib.sha256(raw).hexdigest() == original['sha256']
        if mode == 'decoy' and name == 't/1960-isf-formal-reservation-coverage.t' and not args.trust_decoy_as_original:
            raw += b'\n# owned projected hot-source decoy\n'
        captured = by_name[row['path'] + '/tree/' + name]
        assert captured['bytes'] == len(raw) and captured['sha256'] == hashlib.sha256(raw).hexdigest(), 'exact Git source/declared decoy bytes'
    # Index binary hash/inodes/times are dated native cache observations. The
    # complete published index entries are reproducible; hidden index bytes
    # and allocation identities are not claimed deterministic across rebuilds.
    index = by_name[row['path'] + '/index']
    assert index['bytes'] > 0 and re.fullmatch('[0-9a-f]{64}', index['sha256'])
    node_paths = {n['path'] for n in row['nodes']}
    assert expected <= node_paths and row['path'] in node_paths
    assert len(node_paths) == len(row['nodes'])
    for node in row['nodes']:
        assert node['path'] == row['path'] or node['path'].startswith(row['path'] + '/')
        assert stat.S_ISREG(node['mode']) or stat.S_ISDIR(node['mode'])
        assert node['device'] == row['nodes'][0]['device']
        if stat.S_ISREG(node['mode']): assert node['nlink'] == 1
        assert '.git' not in Path(node['path']).parts
    assert all(not p['path'].endswith(('.log', '.bin')) for p in files)
    assert row['independent_membership'] == 'rg agrees with os.walk'
protected = json.loads((BASE / 'protected.json').read_text())
if args.alter_protected:
    protected['after']['primary_git']['index'] = '0' * 64
assert protected['before'] == protected['after'], 'protected source/book/native/Git bytes conserve'
assert len(protected['before']['members']) > 0
assert all(re.fullmatch('[0-9a-f]{64}', r['sha256']) and type(r['bytes']) is int
           for r in protected['before']['members'].values())
assert [r['path'] for r in report['rust']] == [base + '/' + sub
    for base in ('target', 'rust/target') for sub in ('release', 'debug/incremental', 'debug/deps')]
assert all(r['status'] in ('absent', 'censused') and isinstance(r['retained'], list) for r in report['rust'])
assert (BASE / 'apply.status').read_text().strip() == '0'
assert 'complete selected residue absent' in (BASE / 'apply.txt').read_text()
print('PASS dated two-cache cleanup: all6946 regular members/source/index views authenticate; exact selected residue absent at capture and complete protected bytes conserve. Published Git source/index membership re-derives; binary index metadata/inodes/times are dated observations. Later legitimate replay may regenerate caches.')
