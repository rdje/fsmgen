import hashlib
import json
import shutil
from pathlib import Path
from html.parser import HTMLParser

ROOT = Path('docs/audits/conditional-origin-files-20261002')

class Text(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []
    def handle_data(self, value):
        self.parts.append(value)

products = []
for name, markers in [
    ('13d-control-flow.html', ['Separate private file-backed qualification now reads',
     'prior canonical parse', 'no public parser or scheduling behavior']),
    ('13i-downstream-integration.html', ['runtime-to-relative document identities',
     'canonical width-token coercion', 'conditional-origin-files-20261002/scope.txt'])
]:
    raw = (Path('docs/book/book') / name).read_bytes()
    parser = Text()
    parser.feed(raw.decode())
    content = ' '.join(' '.join(parser.parts).split())
    for marker in markers:
        assert marker in content or marker in raw.decode(), (name, marker)
    shutil.copyfile(Path('docs/book/book') / name, ROOT / name)
    products.append({'page': name, 'sha256': hashlib.sha256(raw).hexdigest(), 'markers': markers})
(ROOT / 'render.json').write_text(json.dumps({'pages': products,
    'scope': 'actual rendered text and canonical downstream inclusion; no browser visual QA'}, indent=2) + '\n')
print('PASS actual rendered file-backed paragraph and canonical downstream inclusion')
