"""Bind dated native observations to complete immutable original sources."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
revision = 'dd85fe5b10d555a281281510ebc40dea977a8cca'
assert subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip() == revision
contract = json.loads(Path('docs/audits/interface-metadata-helper-contract-20261003/contracts.json').read_text())
paths = list(contract['sources']) + ['perl/FSM/Support/ISFRecordPortValues.pm']
sources = {}
for name in paths:
    raw = subprocess.check_output(['git', 'show', revision + ':' + name])
    assert raw == Path(name).read_bytes()
    if name in contract['sources']:
        assert raw.decode() == contract['sources'][name]['body']
    sources[name] = {'body': raw.decode(), 'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
data = json.loads((BASE / 'ordinary.json').read_text())
membership = {
    'helper_labels': [r['label'] for r in data['helpers']],
    'api_callers': [r['caller'] for r in data['api']],
    'copy_callers': [r['caller'] for r in data['copies']],
    'consumer_labels': [r['label'] for r in data['consumers']],
}
(BASE / 'binding.json').write_text(json.dumps({'revision': revision, 'sources': sources,
    'membership': membership, 'meaning_boundary': 'Complete observations and contextual false positives; field/copy/source semantics remain owned .3 before repair .5 and outcome join .4.'},
    sort_keys=True, indent=2) + '\n')
print('PASS complete original Git bodies, native membership and explicit later semantic/repair boundary retained.')
