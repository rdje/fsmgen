"""Derive complete original copy-field roster; no semantic authority from copies."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
profile = json.loads((BASE / 'ordinary.json').read_text())
old = json.loads(Path('docs/audits/interface-metadata-runtime-20261004/ordinary.json').read_text())
assert len(profile['api']) == len(old['api']) and len(profile['copies']) == len(old['copies'])
for actual, prior in zip(profile['api'], old['api']):
    for name in ('kind', 'caller', 'helper', 'before', 'after', 'accepted', 'warnings', 'result'):
        assert actual[name] == prior[name], ('native metadata stream drift', name)
    assert actual['error'].splitlines()[:1] == prior['error'].splitlines()[:1]
for actual, prior in zip(profile['copies'], old['copies']):
    assert actual == prior, 'whole original copy stream'

def fields(graph, path=''):
    if not isinstance(graph, list): return {path: {'kind': type(graph).__name__, 'value': graph}}
    kind, body = graph
    if kind == 'reference': return {path: {'kind': kind, 'value': body}}
    pairs = body.items() if kind == 'hash' else enumerate(body)
    result = {}
    for key, node in pairs:
        escaped = str(key).replace('~', '~0').replace('/', '~1')
        result.update(fields(node, path + '/' + escaped))
    return result

rows = []; unchanged = []
for ordinal, copied in enumerate(profile['copies']):
    original = fields(copied['before']); actual = fields(copied['copy'])
    assert original.keys() == actual.keys()
    changed = [name for name in original if original[name] != actual[name]]
    if not changed: unchanged.append(ordinal)
    for name in changed:
        rows.append({'copy': ordinal, 'kind': copied['kind'], 'line': copied['caller'][2],
            'api': copied['api'], 'path': name, 'original': original[name], 'copied': actual[name],
            'role': 'test source/baseline fixture' if copied['kind'] == 'test' else 'private numeric validation input'})
assert len(rows) == 94 and len({r['copy'] for r in rows}) == 32 and len(unchanged) == 113
assert all(r['path'].endswith('/width') and r['original']['kind'] == 'int'
    and r['copied']['kind'] == 'str' and str(r['original']['value']) == r['copied']['value'] for r in rows)
source_contract = json.loads(Path('docs/audits/interface-metadata-runtime-20261004/binding.json').read_text())
revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
for path, row in source_contract['sources'].items():
    raw = subprocess.check_output(['git', 'show', revision + ':' + path])
    assert raw.decode() == row['body'] and raw == Path(path).read_bytes()
    assert hashlib.sha256(raw).hexdigest() == row['sha256']
(BASE / 'fields.json').write_text(json.dumps({'revision': revision, 'rows': rows,
    'unchanged_copy_ordinals': unchanged, 'sources': source_contract['sources']}, sort_keys=True, indent=2) + '\n')
print('PASS complete94 changed width field pairs across32 copies and113 unchanged original-copy controls bind the exact native source/API/copy streams; semantics and assurance require independent source models and actual successor controls.')
