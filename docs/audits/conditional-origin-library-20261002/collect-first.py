import hashlib
import json
import shutil
import subprocess
from html.parser import HTMLParser
from pathlib import Path

scratch = Path('.artifacts/conditional-origin-library')
root = Path('docs/audits/conditional-origin-library-20261002')
assert not root.exists()
root.mkdir()
for name in ('current-first','current','current-bound','red','red-bound',
        'current-bound-before-finalization','red-bound-before-finalization'):
    shutil.copytree(scratch / name, root / name)
for path in sorted(scratch.iterdir()):
    if path.is_file() and path.suffix in ('.py','.t','.pm','.txt','.tap','.json'):
        shutil.copyfile(path, root / path.name)
shutil.copyfile('t/2045-isf-same-source-library-origins.t', root / 'test-final.t')
shutil.copyfile('t/lib/FSM/Test/SameSourceLibraryOriginParser.pm', root / 'probe-final.pm')
normalization = {str(scratch / name): str(root / name) for name in ('red_missing_export.t','run_bound.py')}
for path in (scratch / 'current').glob('*.json'):
    normalization[str(path)] = str(root / 'current' / path.name)
(root / 'normalization.json').write_text(json.dumps(normalization, indent=2, sort_keys=True) + '\n')
baseline = 'e95955e704c452e41277e3c402ce832912d700f5'
old = subprocess.check_output(['git','ls-tree','-rz',baseline,'--','bin','perl',
    'docs/audits/conditional-origin-parser-20261002','docs/audits/conditional-origin-parser-gate-20261002',
    'docs/audits/conditional-origin-authority-20261002','docs/audits/conditional-origin-authority-checks-20261002',
    't/2043-isf-conditional-origin-parser.t','t/2044-isf-conditional-origin-source-authority.t',
    't/lib/FSM/Test/ConditionalOriginParser.pm','t/lib/FSM/Test/ConditionalOriginAuthority.pm'])
originals = {}
for entry in old.split(b'\0'):
    if not entry: continue
    header, name = entry.split(b'\t',1)
    mode, kind, oid = header.decode().split()
    assert kind == 'blob' and mode in ('100644','100755')
    name = name.decode()
    raw = Path(name).read_bytes()
    assert hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest() == oid
    originals[name] = {'git_blob':oid,'sha256':hashlib.sha256(raw).hexdigest()}
(root / 'originals.json').write_text(json.dumps(originals, indent=2, sort_keys=True) + '\n')
class Text(HTMLParser):
    def __init__(self): super().__init__(); self.parts = []
    def handle_data(self,data): self.parts.append(data)
markers = {
    '13d-control-flow.html': ['Separate same-source library producer qualification','Imported consumer authenticity'],
    '13i-downstream-integration.html': ['Separate same-source library producer qualification','distinct use-instance identities'],
    '13f-composition.html': ['In this shipped surface'],
}
render = {}
for name,wanted in markers.items():
    raw = (Path('docs/book/book') / name).read_bytes()
    reader = Text(); reader.feed(raw.decode())
    text = ' '.join(' '.join(reader.parts).split())
    assert all(marker in text for marker in wanted), name
    if name == '13f-composition.html': assert 'In that future surface' not in text
    (root / name).write_bytes(raw)
    render[name] = {'sha256':hashlib.sha256(raw).hexdigest(),'literal_markers':wanted,
        'scope':'Actual rendered text and canonical inclusion; no browser visual QA.'}
(root / 'render.json').write_text(json.dumps(render, indent=2, sort_keys=True) + '\n')
(root / 'scope.txt').write_text('''Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.2.1
Baseline: e95955e704c452e41277e3c402ce832912d700f5
Detached same-source library conditional producer and actual export-clone linkage.
Complete parent/actor/library/use source identity follows canonical construction.
Final bound positive: Files=1/Tests=27 PASS for the complete 24-source cohort.
Canonical missing-export association producer: Files=1/Tests=24/Failed24 RED.
First test draft FAIL5/26: wrong min/max inverse-guard literals and missing bind
in the external closure fixture. Preserve full sources/products/test and repair
the fixture expectations, without attributing a production defect.
Root finalization mutation exposes a real private prototype gap, RED1/1.
Revalidate full root coverage/targets after canonical finalization; actual fixed
counterfactual and permanent T2045 reject stale target association. Earlier bound
products are pre-finalization-check drafts, not final input/instrument evidence.
Independent complete source reader/catalog/normalized-body/type/scope/clone-edge
verification and shared corruptions qualify the producer boundary, not consumer
authentication. Local source authority still refuses all imports; external docs,
package and ATL authority close explicitly. Preparation/adoption remain owned.
P3 canonical composition wording now says shipped rather than future, matching
the qualified actor-type contract and actual canonical book inclusion.
All production and selected complete predecessor archives remain unchanged.
No HDL/compiler/analyzer/simulation, spent replay, source/public/schema widening,
macro/output runtime, imported consumer authentication, full CI/push or browser
visual QA is claimed. Complete terminal focused/docs/book recipes retained.
''')
print('PASS complete sources/products/drafts/recipes, exact original census and rendered canonical inclusion retained')
