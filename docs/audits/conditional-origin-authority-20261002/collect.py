import hashlib
import json
import shutil
import subprocess
from html.parser import HTMLParser
from pathlib import Path

scratch = Path('.artifacts/conditional-origin-authority')
root = Path('docs/audits/conditional-origin-authority-20261002')
assert not root.exists()
root.mkdir()
for name in ('current-first', 'current', 'current-bound', 'red', 'red-bound'):
    shutil.copytree(scratch / name, root / name)
for name in ('test-first.t', 'red_unbound.t', 'run_bound.py', 'verify.py', 'collect.py',
        'current-first.txt', 'current.txt', 'red.txt', 'bound.txt', 'current-bound.tap',
        'current-bound-stderr.txt', 'current-bound-recipe.json', 'red-bound.tap',
        'red-bound-stderr.txt', 'red-bound-recipe.json', 'docs.txt', 'book.txt'):
    shutil.copyfile(scratch / name, root / name)
shutil.copyfile('t/2044-isf-conditional-origin-source-authority.t', root / 'test-final.t')
shutil.copyfile('t/lib/FSM/Test/ConditionalOriginAuthority.pm', root / 'authority-final.pm')
normalization = {str(scratch / name): str(root / name) for name in ('red_unbound.t', 'run_bound.py')}
(root / 'normalization.json').write_text(json.dumps(normalization, indent=2, sort_keys=True) + '\n')
baseline = 'cb2a156df5a3c8169ad9ca1cfaa9c05046e33bf8'
originals = subprocess.check_output(['git', 'ls-tree', '-rz', baseline, '--', 'bin', 'perl',
    'docs/audits/conditional-origin-parser-20261002', 'docs/audits/conditional-origin-parser-gate-20261002',
    't/2043-isf-conditional-origin-parser.t', 't/lib/FSM/Test/ConditionalOriginParser.pm'])
inventory = {}
for entry in originals.split(b'\0'):
    if not entry: continue
    header, raw_path = entry.split(b'\t', 1)
    mode, kind, oid = header.decode().split()
    assert kind == 'blob' and mode in ('100644', '100755')
    path = raw_path.decode()
    raw = Path(path).read_bytes()
    assert hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest() == oid, path
    inventory[path] = {'git_blob': oid, 'sha256': hashlib.sha256(raw).hexdigest()}
(root / 'originals.json').write_text(json.dumps(inventory, indent=2, sort_keys=True) + '\n')

class Text(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []
    def handle_data(self, data): self.parts.append(data)

markers = {
    '13d-control-flow.html': ['private local-source verifier', 'An embedded digest supplies no authority'],
    '13i-downstream-integration.html': ['private local-source reload verifier', 'Matching embedded digests'],
    '13k-isf-feature-support-matrix.html': ['Local-source reload verification', 'imports remain closed'],
}
render = {}
for name, wanted in markers.items():
    raw = (Path('docs/book/book') / name).read_bytes()
    reader = Text()
    reader.feed(raw.decode())
    text = ' '.join(' '.join(reader.parts).split())
    assert all(marker in text for marker in wanted), name
    (root / name).write_bytes(raw)
    render[name] = {'sha256': hashlib.sha256(raw).hexdigest(), 'literal_markers': wanted,
        'scope': 'Actual rendered text and canonical downstream inclusion; no browser visual QA.'}
(root / 'render.json').write_text(json.dumps(render, indent=2, sort_keys=True) + '\n')
(root / 'scope.txt').write_text('''Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.1
Baseline: cb2a156df5a3c8169ad9ca1cfaa9c05046e33bf8
Private local-source reload authority; independently supplied source produces
complete actor and ledger through the real parser observer. Imported documents
refuse before resolution. Production parser/scheduler/public schemas unchanged.
Final bound positive: Files=1/Tests=58 PASS, complete original 54-source cohort.
Actual fresh structural verifier: Files=1/Tests=54/Failed54 genuine RED.
First green draft uses nonexistent name/inputs actor keys in identity/kind
controls. Independent review catches that false oracle; preserve complete draft
products/test and correct to actor_name/interface.inputs with kind/key assertions.
That first draft does not qualify original-kind or existing-identity mutation.
Independent verifier compares whole products and independently constructs every
exact mutation against immutable predecessor authority; shared corruptions fail.
Docs/book terminal receipts and complete bound parser proof retained. The
separate broader focused job must be consumed before its receipt is accepted.
No HDL/compiler/analyzer/simulation, spent replay, macro/output runtime, public
widening, preparation/adoption, browser visual QA, full CI or push is claimed.
''')
print('PASS complete actual recipes/products/drafts, immutable original census and rendered canonical inclusion retained')
