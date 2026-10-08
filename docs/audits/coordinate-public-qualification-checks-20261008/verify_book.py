"""Verify the complete source repair, rendered guide and exact aggregate delta."""
import copy
import hashlib
import json
import subprocess
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/coordinate-public-qualification-checks-20261008')
SOURCE = Path('docs/book/src/13k-isf-feature-support-matrix.md')
REVISION = '7a5446252d380e9a6fc784c0b44dc1e9a36d016f'
OUTPUT = '.artifacts/coordinate-public-qualification-book'


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


class Visible(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.parts = []

    def handle_data(self, value):
        self.parts.append(value)


def check(source, native, actual):
    before = subprocess.check_output(['git', 'show', REVISION + ':' + str(SOURCE)]).decode()
    need((BASE / 'book-before.md.txt').read_text() == before, 'complete committed pre-repair book source')
    old = 'selection. Native wrong-caller, line and source controls remain pending:'
    need(before.count(old) == 1 and 'This closes finite native falsification;' in before,
         'exact pre-repair contradictory book status')
    expected = before.replace(old, 'selection. Their historical scopes remain separate from the native-control qualification below:', 1)
    expected = expected.replace('This closes finite native falsification; whole public qualification/publication and',
                                'This closes finite native falsification; final public recipe/fact publication and', 1)
    addition = (BASE / 'book-addition.txt').read_text()
    expected = expected.replace('\nThe own subtest source model now assigns', addition + '\nThe own subtest source model now assigns', 1)
    need(source == expected, 'whole exact public qualification book repair and source conservation')
    need(actual['command'] == ['scripts/run_with_ram_guard.sh', '--', 'mdbook', 'build', 'docs/book', '--dest-dir', OUTPUT]
         and type(actual['status']) is int and actual['status'] == 0, 'exact public qualification native build success')
    visible = Visible(); visible.feed(native)
    text = ' '.join(''.join(visible.parts).split())
    guide = ' '.join(addition.replace('```bash\n', '').replace('```\n', '').split())
    need(guide in text and 'Native wrong-caller, line and source controls remain pending:' not in text,
         'complete public qualification rendered guide and corrected status')


def main():
    source = (BASE / 'book-source.md.txt').read_text()
    native = (BASE / 'book-input.html').read_text(); actual = json.loads((BASE / 'book.json').read_bytes())
    check(source, native, actual)
    controls = []
    for phrase in ('final public recipe/fact publication and original-coordinate intake remain later steps:',
                   'record-value-coordinate-public-qualification-20261008/verify.py',
                   'Every selected and coincident source alternative,'):
        need(native.count(phrase) == 1, 'unique rendered qualification control target')
        changed = native.replace(phrase, 'borrowed', 1)
        try:
            check(source, changed, actual)
        except ValueError as error:
            need(str(error) == 'complete public qualification rendered guide and corrected status', 'intended qualification guide refusal')
            controls.append(dict(control=phrase, status=1, cause=str(error)))
        else:
            raise ValueError('false-green qualification guide control')
    candidate = copy.deepcopy(actual); candidate['status'] = False
    try:
        check(source, native, candidate)
    except ValueError as error:
        need(str(error) == 'exact public qualification native build success', 'intended native Boolean status refusal')
        controls.append(dict(control='Boolean-native-status', status=1, cause=str(error)))
    else:
        raise ValueError('false-green native Boolean status')
    paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', REVISION, 'docs/book/src'], text=True).splitlines()
    paths = sorted(p for p in paths if p.endswith('.md') and Path(p).parent == Path('docs/book/src'))
    need(paths == sorted(str(p) for p in Path('docs/book/src').glob('*.md')), 'complete independent Git/filesystem book population')
    old = [subprocess.check_output(['git', 'show', REVISION + ':' + p]) for p in paths]
    new = [Path(p).read_bytes() for p in paths]
    need(all(a == b for p, a, b in zip(paths, old, new) if p != str(SOURCE)), 'all non-target complete book bytes conserve')
    def measure(raws):
        return dict(files=len(raws), lines_total=sum(raw.count(b'\n') for raw in raws), bytes_total=sum(map(len, raws)))
    before = measure(old); after = measure(new)
    proof = dict(source=pin(source.encode()), native=pin(native.encode()), controls=controls,
                 population=paths, baseline=before, actual=after,
                 delta={k: after[k] - before[k] for k in before},
                 scope='Complete finite public source/native guide and contradiction repair only. Final publication, original identities and visual QA remain pending.')
    path = BASE / 'book-proof.json'; raw = json.dumps(proof, sort_keys=True, indent=2) + '\n'
    if path.exists():
        need(path.read_text() == raw, 'whole retained public qualification book proof')
    else:
        path.write_text(raw)
    print('PASS complete public qualification source/native guide, corrected pending status, exact aggregate and genuine controls; visual QA remains pending.')


if __name__ == '__main__':
    main()
