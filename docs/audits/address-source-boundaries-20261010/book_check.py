"""Whole original chapter conservation, final source copies and native new guide."""
import hashlib
import json
import re
import runpy
import subprocess
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/address-source-boundaries-20261010')
CHAPTER = 'docs/book/src/13k-isf-feature-support-matrix.md'


class Text(HTMLParser):
    def __init__(self):
        super().__init__(); self.parts = []
    def handle_data(self, data):
        self.parts.append(data)


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def native_guide(raw, addition):
    text = Text(); text.feed(raw)
    flat = re.sub(r'\s+', ' ', ' '.join(text.parts))
    for paragraph in addition.split('\n\n'):
        if paragraph.startswith('```') or not paragraph.strip():
            continue
        if re.sub(r'\s+', ' ', paragraph.strip()) not in flat:
            raise ValueError('complete new source-only native guide')


def main():
    revision = json.loads((BASE / 'binding.json').read_bytes())['revision']
    original = subprocess.check_output(['git', 'show', revision + ':' + CHAPTER]).decode()
    addition = (BASE / 'book-addition.md.txt').read_text()
    marker = 'Raw-coordinate qualification first admits the complete predecessor source and\n'
    current = Path(CHAPTER).read_text()
    if original.count(marker) != 1 or current != original.replace(marker, addition + marker):
        raise ValueError('whole original chapter plus exact source-only addition')
    plane = runpy.run_path('scripts/book_source_references.py')
    plane['check'](plane['expected_rows'](), 'docs/book/book')
    html_path = Path('docs/book/book/13k-isf-feature-support-matrix.html')
    html = html_path.read_text()
    native_guide(html, addition)
    missing = addition.split('\n\n')[0].splitlines()[0]
    if missing not in html:
        raise ValueError('genuine rendered omission control setup')
    try:
        native_guide(html.replace(missing, 'removed source scope'), addition)
    except ValueError as error:
        if str(error) != 'complete new source-only native guide':
            raise
    else:
        raise ValueError('native omitted source scope admitted')
    result = {'revision': revision, 'original': identity(original.encode()),
              'addition': identity(addition.encode()), 'current': identity(current.encode()),
              'native': identity(html.encode()), 'programme': identity(Path(__file__).read_bytes()),
              'scope': 'Complete original chapter conservation, all final source copies and full new source-only native guide; visual QA remains open.',
              'control': 'Genuine native source-scope omission rejects at complete new source-only native guide.'}
    target = BASE / 'book-proof.json'
    if target.exists() and json.loads(target.read_bytes()) != result:
        raise ValueError('whole retained native guide proof; never overwrite')
    if not target.exists():
        target.write_text(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print('PASS whole original chapter conservation, all final canonical source copies and complete new source-only native guide; omission rejects.')


if __name__ == '__main__':
    main()
