"""Verify the complete finite-reference source, native paragraphs and table."""
import copy
import hashlib
import json
import subprocess
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/coordinate-public-reference-checks-20261008')
SOURCE = Path('docs/book/src/13k-isf-feature-support-matrix.md')
OUTPUT = '.artifacts/coordinate-public-reference-book'


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def normal(text):
    return ' '.join(text.split())


class Visible(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.parts = []
        self.cells = []
        self.cell = None

    def handle_starttag(self, tag, attrs):
        if tag in ('th', 'td'):
            self.cell = []

    def handle_data(self, value):
        self.parts.append(value)
        if self.cell is not None:
            self.cell.append(value)

    def handle_endtag(self, tag):
        if tag in ('th', 'td') and self.cell is not None:
            self.cells.append(normal(''.join(self.cell)))
            self.cell = None


def check(source, native, actual):
    revision = json.loads((BASE / 'epoch.json').read_bytes())['revision']
    before = subprocess.check_output(['git', 'show', revision + ':' + str(SOURCE)]).decode()
    need((BASE / 'book-before.md.txt').read_text() == before, 'whole committed pre-reference source')
    addition = (BASE / 'book-addition.txt').read_text()
    expected = before.replace('final public recipe/fact publication and original-coordinate intake remain later steps:',
                              'the canonical reader route and final public parent closure remain later steps; original-coordinate intake follows those:', 1)
    expected = expected.replace('\nThe own subtest source model now assigns', addition + '\nThe own subtest source model now assigns', 1)
    need(source == expected, 'whole exact finite-reference source and predecessor conservation')
    need(actual['command'] == ['scripts/run_with_ram_guard.sh', '--', 'mdbook', 'build', 'docs/book', '--dest-dir', OUTPUT]
         and type(actual['status']) is int and actual['status'] == 0, 'exact finite-reference native build success')
    visible = Visible(); visible.feed(native)
    rendered = normal(' '.join(visible.parts))
    paragraphs = []
    for block in addition.replace('```bash\n', '').replace('```\n', '').strip().split('\n\n'):
        if not block.startswith('|'):
            paragraphs.append(normal(block))
    need(all(block in rendered for block in paragraphs), 'whole finite-reference rendered paragraphs and scoped route')
    cells = [normal(cell) for line in addition.splitlines() if line.startswith('|') and not line.startswith('| ---')
             for cell in line.strip('|').split('|')]
    need(len(cells) == 12 and any(visible.cells[i:i + len(cells)] == cells for i in range(len(visible.cells))),
         'whole finite-reference rendered table cells')


def main():
    source = (BASE / 'book-source.md.txt').read_text(); native = (BASE / 'book-input.html').read_text()
    actual = json.loads((BASE / 'book.json').read_bytes()); check(source, native, actual)
    controls = []
    for phrase in ('record-value-coordinate-public-reference-20261008/verify.py',
                   'no original-coordinate intake is admitted by this reference.',
                   'Preserve both labels when the alternatives coincide.'):
        need(native.count(phrase) == 1, 'unique finite-reference native control target')
        changed = native.replace(phrase, 'borrowed', 1)
        try:
            check(source, changed, actual)
        except ValueError as error:
            need(str(error) in ('whole finite-reference rendered paragraphs and scoped route', 'whole finite-reference rendered table cells'),
                 'intended finite-reference native refusal')
            controls.append(dict(control=phrase, status=1, cause=str(error)))
        else:
            raise ValueError('false-green finite-reference native control')
    changed = copy.deepcopy(actual); changed['status'] = False
    try:
        check(source, native, changed)
    except ValueError as error:
        need(str(error) == 'exact finite-reference native build success', 'intended native Boolean status refusal')
        controls.append(dict(control='Boolean-native-status', status=1, cause=str(error)))
    else:
        raise ValueError('false-green native Boolean status')
    proof = dict(source=pin(source.encode()), native=pin(native.encode()), controls=controls,
                 scope='Complete dated finite reference source/native text/table only. Canonical route, final public parent and visual QA remain pending.')
    path = BASE / 'book-proof.json'; raw = json.dumps(proof, sort_keys=True, indent=2) + '\n'
    if path.exists():
        need(path.read_text() == raw, 'whole retained finite-reference native proof')
    else:
        path.write_text(raw)
    print('PASS complete finite-reference source/native paragraphs/table and genuine controls; visual QA and current route remain pending.')


if __name__ == '__main__':
    main()
