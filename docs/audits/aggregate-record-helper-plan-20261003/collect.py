"""Declare per-source review ownership; no consumer/native classification."""
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
REVISION = '3951ccbc6eb95612adb6db00f3b4af559d05325b'
PARENT = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3'
PRIOR = Path('docs/audits/residual-named-helper-cohorts-20261003')
assert subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip() == REVISION
prior = json.loads((PRIOR / 'membership.json').read_text())
paths = json.loads((PRIOR / 'owners.json').read_text())['cohorts']['3']
rows = []
for number, path in enumerate(paths, 2):
    raw = subprocess.check_output(['git', 'show', REVISION + ':' + path])
    assert raw == Path(path).read_bytes() == prior['sources'][path].encode(), ('source drift', path)
    original = [row for row in prior['definitions'] if row['path'] == path]
    definitions = []
    for match in re.finditer(rb'(?m)^[ \t]*sub[ \t]+((?:refus|reject|fail|declin)\w*)\b', raw):
        definitions.append({'function': match[1].decode(), 'line': raw[:match.start()].count(b'\n') + 1,
            'offset': match.start(), 'token': match[0].decode()})
    assert len(definitions) == len(original) == 1
    for current, previous in zip(definitions, original):
        assert all(current[key] == previous[key] for key in current)
        assert previous['review_owner'] == PARENT
    rows.append({'path': path, 'review_owner': PARENT + '.' + str(number),
        'prior_review_owner': PARENT, 'source': raw.decode(), 'bytes': len(raw),
        'sha256': hashlib.sha256(raw).hexdigest(), 'definitions': definitions,
        'scope': 'pending actual helper/caller/cause/product/copy/native applicability qualification'})
(BASE / 'plan.json').write_text(json.dumps({'revision': REVISION, 'parent': PARENT,
    'split_owner': PARENT + '.1', 'join_owner': PARENT + '.16', 'rows': rows}, indent=2, sort_keys=True) + '\n')
print('PASS complete aggregate-record declaration membership binds 14 sources/14 declarations to distinct review leaves; split/join have separate owners; native and behavior review remain pending.')
