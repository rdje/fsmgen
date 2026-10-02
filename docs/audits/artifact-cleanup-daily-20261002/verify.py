import copy
import hashlib
import json
import os
import stat
import subprocess
from pathlib import Path

BASE = Path('docs/audits/artifact-cleanup-daily-20261002')
TARGET = '.artifacts/formal-preallocation-admission/book'
BASELINE = '6bf1e9b0a2802cf644d35667f35a2f7988e95989'

def same(a, b):
    assert json.dumps(a, sort_keys=True, separators=(',', ':')) == json.dumps(b, sort_keys=True, separators=(',', ':'))

report = json.loads((BASE / 'result.json').read_text())
protected = json.loads((BASE / 'protected.json').read_text())

def validate(r, p):
    assert r['owner'] == 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.67' and r['cleanup_revision'] == BASELINE
    same(r['residue'], {TARGET: False})
    assert not os.path.lexists(TARGET)
    assert len(r['removed']) == 1
    row = r['removed'][0]; assert row['path'] == TARGET
    assert len(row['files']) == 99
    same(row['bytes_total'], 25839310)
    names = [f['path'] for f in row['files']]
    assert names == sorted(set(names))
    assert all(name.startswith(TARGET + '/') and '..' not in Path(name).parts for name in names)
    assert sum(f['bytes'] for f in row['files']) == row['bytes_total']
    assert all(type(f['bytes']) is int and f['bytes'] >= 0 and len(f['sha256']) == 64 for f in row['files'])
    nodes = row['nodes']; assert len({n['path'] for n in nodes}) == len(nodes)
    assert len({n['device'] for n in nodes}) == 1
    assert all(n['path'] == TARGET or n['path'].startswith(TARGET + '/') for n in nodes)
    files = {n['path']: n for n in nodes if stat.S_ISREG(n['mode'])}
    assert set(files) == set(names)
    for n in nodes:
        assert stat.S_ISREG(n['mode']) or stat.S_ISDIR(n['mode'])
        if stat.S_ISREG(n['mode']): same(n['nlink'], 1)
    for f in row['files']: same(files[f['path']]['size'], f['bytes'])
    same(p['before'], p['after'])
    assert len(p['before']['members']) == 8181 and len(p['before']['log_bin_names']) == 4864
    assert set(p['before']['log_bin_names']) <= set(p['before']['members'])
    assert all(not name.startswith(TARGET + '/') for name in p['before']['members'])
    same([(n['path'], n['status'], n['retained']) for n in r['rust']], [
        ('target/release', 'absent', []), ('target/debug/incremental', 'absent', []),
        ('target/debug/deps', 'absent', []), ('rust/target/release', 'absent', []),
        ('rust/target/debug/incremental', 'censused', []), ('rust/target/debug/deps', 'censused', [])])
    assert r['retained'] == ['all logs', 'native/receipt evidence', 'spent compiler workspaces', 'docs/book/book']
    assert Path('docs/book/book/index.html').is_file()

validate(report, protected)
# Mutable logs/workspaces/render hashes are dated before/after captures. Only
# immutable committed parents are rechecked against current bytes/Git objects.
paths = [p for p in protected['before']['members'] if p.startswith(('bin/', 'perl/', 't/'))]
raw = subprocess.check_output(['git', 'cat-file', '--batch'], input=''.join(BASELINE + ':' + p + '\n' for p in paths).encode())
offset = 0
for path in paths:
    end = raw.index(b'\n', offset); header = raw[offset:end].split(); assert header[1] == b'blob'
    size = int(header[2]); offset = end + 1; body = raw[offset:offset + size]; offset += size + 1
    same({'bytes': len(body), 'sha256': hashlib.sha256(body).hexdigest()}, protected['before']['members'][path])
assert offset == len(raw)
for path, row in protected['before']['members'].items():
    if path.startswith('docs/audits/'):
        body = Path(path).read_bytes()
        same({'bytes': len(body), 'sha256': hashlib.sha256(body).hexdigest()}, row)
for name in ('target', 'allocation', 'membership', 'hard_link', 'retention'):
    bad = copy.deepcopy(report)
    if name == 'target': bad['removed'][0]['path'] = '.artifacts'
    elif name == 'allocation': bad['removed'][0]['bytes_total'] += 1
    elif name == 'membership': bad['removed'][0]['files'].pop()
    elif name == 'hard_link': next(n for n in bad['removed'][0]['nodes'] if stat.S_ISREG(n['mode']))['nlink'] = 2
    else: bad['retained'] = []
    try: validate(bad, protected)
    except AssertionError: print('hostile cleanup corruption rejects:', name)
    else: raise AssertionError('accepted cleanup corruption ' + name)
bad = copy.deepcopy(protected); first = next(iter(bad['after']['members'])); bad['after']['members'][first]['sha256'] = '0' * 64
try: validate(report, bad)
except AssertionError: print('changed protected identity rejects')
else: raise AssertionError('accepted protected change')
if (BASE / 'manifest.json').exists():
    seal = json.loads((BASE / 'manifest.json').read_text())['files']
    assert set(seal) == {str(p.relative_to(BASE)) for p in BASE.rglob('*') if p.is_file() and p.name != 'manifest.json'}
    for name, row in seal.items():
        body = (BASE / name).read_bytes()
        same({'bytes': len(body), 'sha256': hashlib.sha256(body).hexdigest()}, row)
print('daily cleanup: exact member/allocation/node/link/residue and protected identities authenticate; immutable parents/Git bytes reverify; mutable captures are historical; obsolete render bytes/producing revision are not reproduced')
