"""Verify the entire route source delta and scoped native publication."""
import copy
import hashlib
import json
import subprocess
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/coordinate-public-route-checks-20261008')
SOURCE = Path('docs/book/src/13k-isf-feature-support-matrix.md')
OUTPUT = '.artifacts/coordinate-public-route-book'


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


class Visible(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True); self.parts = []

    def handle_data(self, value):
        self.parts.append(value)


def normal(text):
    return ' '.join(text.split())


def check(source, native, actual):
    revision = json.loads((BASE / 'epoch.json').read_bytes())['revision']
    before = subprocess.check_output(['git', 'show', revision + ':' + str(SOURCE)]).decode()
    need((BASE / 'book-before.md.txt').read_text() == before, 'whole committed pre-route book source')
    edits = json.loads((BASE / 'book-edits.json').read_bytes()); expected = before
    for old, new in edits['replacements']:
        need(expected.count(old) == 1, 'unique whole route source seam'); expected = expected.replace(old, new, 1)
    expected = expected.replace('\nThe own subtest source model now assigns', edits['addition'] + '\nThe own subtest source model now assigns', 1)
    need(source == expected, 'whole exact route source and predecessor conservation')
    need(actual['command'] == ['scripts/run_with_ram_guard.sh', '--', 'mdbook', 'build', 'docs/book', '--dest-dir', OUTPUT]
         and type(actual['status']) is int and actual['status'] == 0, 'exact route native build success')
    parser = Visible(); parser.feed(native); rendered = normal(' '.join(parser.parts))
    blocks = [new for old, new in edits['replacements']] + edits['addition'].replace('```bash\n', '').replace('```\n', '').strip().split('\n\n')
    need(all(normal(block) in rendered for block in blocks), 'whole native route guidance and identity gaps')


def main():
    source = (BASE / 'book-source.md.txt').read_text(); native = (BASE / 'book-input.html').read_text()
    actual = json.loads((BASE / 'book.json').read_bytes()); check(source, native, actual)
    controls = []
    for phrase in ('where are public coordinate recipes verified?', 'record-value-coordinate-public-route-20261008/verify.py',
                   'Original coordinates/identities remain unmeasured; visual QA remains pending.'):
        need(native.count(phrase) == 1, 'unique real native route control'); changed = native.replace(phrase, 'borrowed', 1)
        try:
            check(source, changed, actual)
        except ValueError as error:
            need(str(error) == 'whole native route guidance and identity gaps', 'intended native route refusal')
            controls.append(dict(control=phrase, status=1, cause=str(error)))
        else:
            raise ValueError('false-green native route control')
    changed = copy.deepcopy(actual); changed['status'] = False
    try:
        check(source, native, changed)
    except ValueError as error:
        need(str(error) == 'exact route native build success', 'intended native Boolean status refusal')
        controls.append(dict(control='Boolean-status', status=1, cause=str(error)))
    else:
        raise ValueError('false-green native Boolean status')
    proof = dict(source=pin(source.encode()), native=pin(native.encode()), controls=controls,
                 scope='Complete route source delta and native text. Every copied canonical source has a separate full factory check; visual QA remains pending.')
    path = BASE / 'book-proof.json'; raw = json.dumps(proof, sort_keys=True, indent=2) + '\n'
    if path.exists():
        need(path.read_text() == raw, 'whole retained native route proof')
    else:
        path.write_text(raw)
    print('PASS complete route source/native guidance and genuine controls; visual QA remains pending.')


if __name__ == '__main__':
    main()
