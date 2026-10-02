"""Collect this owned proof before sealing. Existing archives are read-only."""
import hashlib
import json
import os
import shutil
import subprocess
from html.parser import HTMLParser
from pathlib import Path

SCRATCH = Path('.artifacts/conditional-origin')
BASE = Path('docs/audits/conditional-origin-parser-20261002')
REV = '985e5e9707cd987a7b70a878f0c686ad36e191d6'
PREFIX = (str(Path('.').resolve()) + '/').encode()

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def write(name, data):
    (BASE / name).write_text(json.dumps(data, sort_keys=True, indent=2) + '\n')

def census(roots, name):
    raw = subprocess.check_output(['git','ls-tree','-r','-z',REV,'--'] + roots)
    records = {}
    for record in raw.split(b'\0'):
        if not record:
            continue
        meta, path = record.split(b'\t')
        mode, kind, blob = meta.decode().split()
        assert kind == 'blob', 'never cross submodule implementation boundary'
        path = path.decode()
        p = Path(path)
        actual = os.readlink(p).encode() if p.is_symlink() else p.read_bytes()
        original = subprocess.check_output(['git','cat-file','blob',blob])
        assert actual == original, path
        records[path] = {'mode': mode, 'blob': blob, 'bytes': len(actual), 'sha256': sha(actual)}
    write(name + '.json', {'baseline': REV, 'roots': roots, 'members': records})
    (BASE / (name + '.zlist')).write_bytes(raw)

class Render(HTMLParser):
    def __init__(self):
        super().__init__()
        self.text, self.links = [], []
    def handle_data(self, data):
        self.text.append(data)
    def handle_starttag(self, tag, attrs):
        if tag == 'a':
            self.links += [value for key, value in attrs if key == 'href']

assert not (BASE / 'manifest.json').exists(), 'sealed evidence is immutable'
normalization = {}
for path in sorted(p for p in SCRATCH.rglob('*') if p.is_file()):
    if path.name.startswith(('collect-', 'verify-', 'seal-')):
        continue
    assert not path.is_symlink()
    relative = path.relative_to(SCRATCH)
    destination = BASE / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    original = path.read_bytes()
    retained = original.replace(PREFIX, b'')
    destination.write_bytes(retained)
    normalization[str(relative)] = {'original_sha256': sha(original), 'retained_sha256': sha(retained),
        'normalization': 'exact runtime repository prefix only'}
write('normalization.json', normalization)
for path, name in [('t/2043-isf-conditional-origin-parser.t','test-final.t'),
                   ('t/lib/FSM/Test/ConditionalOriginParser.pm','probe-final.pm')]:
    shutil.copyfile(path, BASE / name)
assert not subprocess.check_output(['git','ls-files','--others','--exclude-standard','-z','--','bin','perl'])
census(['bin','perl'], 'production')
previous = json.loads(Path('docs/audits/procedure-cond-normalization-20261002/immutable-parents.json').read_text())
census(previous['roots'] + ['docs/audits/procedure-cond-normalization-20261002'], 'immutable-parents')
rendered = []
for name, marker in [('13d-control-flow.html','The detached parser-origin qualification'),
                     ('13k-isf-feature-support-matrix.html','Conditional source-intent qualification is private preparation'),
                     ('13i-downstream-integration.html','Detached parser-origin qualification now preserves original operations')]:
    path = Path('docs/book/book') / name
    raw = path.read_bytes()
    parsed = Render()
    parsed.feed(raw.decode())
    text = ' '.join(' '.join(parsed.text).split())
    assert marker in text, (name, marker)
    (BASE / name).write_bytes(raw)
    rendered.append({'chapter': name, 'sha256': sha(raw), 'marker': marker, 'links': parsed.links,
        'scope': 'actual rendered text/links; no browser visual QA'})
write('render.json', rendered)
print('PASS retained complete sources/products/failed drafts/recipes, exact production and immutable predecessors, actual rendered text/links')
