"""Check the complete additive source guide, native text and exact book aggregate."""
import copy
import hashlib
import json
import subprocess
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/coordinate-native-semantic-checks-20261008')
SOURCE = Path('docs/book/src/13k-isf-feature-support-matrix.md')
REVISION = '857ba30485c5a176263e6e5779779051294d6f23'
OUTPUT = '.artifacts/coordinate-native-semantic-book'


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
    addition = (BASE / 'book-addition.txt').read_text()
    start = before.index('\nThe own subtest source model now assigns', before.index('\nPublic coordinate hypotheses preserve'))
    expected = (before[:start] + addition + before[start:]).replace('these plans before execution. Native semantic refusal qualification remains pending:', 'the committed pre-execution plans:', 1).replace('the captures again. Semantic refusal qualification remains a separate step:', 'the captures again. Its dated custody scope remains separate from semantics:', 1)
    need(source == expected, 'whole exact additive plan guide and prior source conservation')
    need(actual['command'] == ['scripts/run_with_ram_guard.sh', '--', 'mdbook', 'build', 'docs/book', '--dest-dir', OUTPUT]
         and type(actual['status']) is int and actual['status'] == 0, 'exact plan native build and integer success')
    visible = Visible(); visible.feed(native)
    guide = addition.replace('```bash\n', '').replace('```\n', '')
    need(' '.join(guide.split()) in ' '.join(''.join(visible.parts).split()), 'whole native plan guide and unexecuted boundary')


def main():
    source = (BASE / 'book-source.md.txt').read_text()
    native = (BASE / 'book-input.html').read_text(); actual = json.loads((BASE / 'book.json').read_bytes())
    check(source, native, actual)
    controls = []
    for text in ('This closes finite native falsification;',
                 'original/private/formatter/toolchain/address identities remain open.',
                 'record-value-coordinate-native-semantic-20261008/verify.py'):
        changed = native.replace(text, 'borrowed', 1)
        need(native.count(text) == 1 and changed != native, 'genuine unique native plan guide mutation')
        try:
            check(source, changed, actual)
        except ValueError as error:
            need(str(error) == 'whole native plan guide and unexecuted boundary', 'intended native guide refusal')
            controls.append(dict(control=text, status=1, cause=str(error)))
        else:
            raise ValueError('false-green native plan guide')
    candidate = copy.deepcopy(actual); candidate['status'] = False
    try:
        check(source, native, candidate)
    except ValueError as error:
        need(str(error) == 'exact plan native build and integer success', 'intended Boolean native status refusal')
        controls.append(dict(control='Boolean-native-status', status=1, cause=str(error)))
    else:
        raise ValueError('false-green Boolean native status')
    names = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', REVISION, 'docs/book/src']).decode().splitlines()
    paths = sorted(p for p in names if p.endswith('.md') and Path(p).parent == Path('docs/book/src'))
    need(paths == sorted(str(p) for p in Path('docs/book/src').glob('*.md')), 'whole independent Git and filesystem book population')
    def measure(raws):
        return dict(files=len(raws), lines_total=sum(raw.count(b'\n') for raw in raws), bytes_total=sum(map(len, raws)))
    old = [subprocess.check_output(['git', 'show', REVISION + ':' + p]) for p in paths]
    new = [Path(p).read_bytes() for p in paths]
    need(all(a == b for p, a, b in zip(paths, old, new) if p != str(SOURCE)), 'every non-target whole book source conserves')
    before = measure(old); after = measure(new)
    proof = dict(source=pin(source.encode()), native=pin(native.encode()), controls=controls,
                 revision=REVISION, population=paths, baseline=before, actual=after,
                 delta={key: after[key] - before[key] for key in before},
                 scope='Exact additive source-only plan guide and native text. Visual QA, whole public qualification and original identities remain pending.')
    path = BASE / 'book-proof.json'; raw = json.dumps(proof, sort_keys=True, indent=2) + '\n'
    if path.exists():
        need(path.read_text() == raw, 'whole retained plan guide proof')
    else:
        path.write_text(raw)
    print('PASS complete finite native semantic source/native guide, exact aggregate and genuine refusals; whole public and original identities remain pending.')


if __name__ == '__main__':
    main()
