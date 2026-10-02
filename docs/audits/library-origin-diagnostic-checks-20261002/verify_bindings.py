import hashlib,json,subprocess
from pathlib import Path
from html.parser import HTMLParser
base=Path('docs/audits/library-origin-diagnostic-correction-20261002')
members=json.loads((base/'manifest.json').read_text())['files']
assert set(members)=={str(p.relative_to(base)) for p in base.rglob('*') if p.is_file() and p.name!='manifest.json'}
for name,expected in members.items():
    raw=(base/name).read_bytes()
    assert len(raw)==expected['bytes'] and hashlib.sha256(raw).hexdigest()==expected['sha256']
assert (base/'candidate-test.t').read_bytes()==Path('t/2046-isf-library-document-origin-authority.t').read_bytes()
for band in ('current-bound','full-stack-red','bypass-red'):
    recipe=json.loads((base/(band+'-recipe.json')).read_text())
    assert recipe['before']==recipe['after']
    for name,sha in recipe['before'].items():
        assert hashlib.sha256(Path(name).read_bytes()).hexdigest()==sha
        if name.startswith(('bin/','perl/','t/lib/')):
            assert hashlib.sha256(subprocess.check_output(['git','show',recipe['baseline']+':'+name])).hexdigest()==sha
class Text(HTMLParser):
    def __init__(self): super().__init__(); self.values=[]
    def handle_data(self,data): self.values.append(data)
p=Text(); p.feed(Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text())
text=' '.join(' '.join(p.values).split())
assert (base/'rendered.txt').read_text()==text+'\n'
assert 'library-document helper also uses the first diagnostic line' in text
print('PASS exact exclusive archive seal, current test, unchanged baseline production/provider/instruments and completed book rendered text')
