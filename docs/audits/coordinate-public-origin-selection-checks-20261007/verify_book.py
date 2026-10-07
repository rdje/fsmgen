"""Qualify the exact scoped dated public origin selection source/native guide."""
import copy
import hashlib
import json
import subprocess
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/coordinate-public-origin-selection-checks-20261007')
SOURCE = 'docs/book/src/13k-isf-feature-support-matrix.md'
REVISION = 'b3b1bc6164b1a0ea0943d2399ad90de11ecad9de'
OUTPUT = '.artifacts/coordinate-public-origin-selection-book'
EXTRA = '''
For the retained public captures, longmess origin headers join the observer
call sites. Confess headers join the own confess statement inside eval.
These headers qualify only the retained public fixtures. Every raw header and
following trace byte remains intact; private frames and formatter settings
remain unmeasured. The saved origin reader preserves all matching source
alternatives and rejects borrowed source, line, message and scope candidates:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-public-origin-selection-20261007/verify.py
```
'''


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def replacement(before):
    start = before.index('\nPublic coordinate hypotheses preserve')
    stop = before.index('\nThe own subtest source model now assigns', start)
    old = before[start:stop]
    pending = 'selection. Trace origins and native wrong-caller, line and source controls\nremain pending:'
    need(old.count(pending) == 1, 'exact committed predecessor origin deferral')
    return old, old.replace(pending, 'selection. Native wrong-caller, line and source controls remain pending:') + EXTRA


class Visible(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.parts = []

    def handle_data(self, data):
        self.parts.append(data)


def check(source, native, actual):
    before = subprocess.check_output(['git', 'show', REVISION + ':' + SOURCE]).decode()
    old, new = replacement(before)
    need(source == before.replace(old, new), 'whole scoped origin-selection source replacement and prior conservation')
    need(actual['command'] == ['scripts/run_with_ram_guard.sh', '--', 'mdbook', 'build', 'docs/book', '--dest-dir', OUTPUT]
         and type(actual['status']) is int and actual['status'] == 0,
         'whole exact same-volume native build and integer success')
    visible = Visible(); visible.feed(native)
    guide = new.replace('```bash\n', '').replace('```\n', '')
    need(' '.join(guide.split()) in ' '.join(''.join(visible.parts).split()),
         'complete native finite origin selection guide and unmeasured scope')
    return dict(source=pin(source.encode()), native=pin(native.encode()), actual=actual,
                scope='Exact dated scoped source/native guide, complete prior caller/hypothesis facts and finite origin/header scope; no visual QA, future currency, original/private/formatter/toolchain identity or native bad-variant signoff.')


def main():
    source = (BASE / 'book-source.md.txt').read_text()
    native = (BASE / 'book-input.html').read_text()
    actual = json.loads((BASE / 'book.json').read_bytes())
    proof = check(source, native, actual)
    controls = []
    for name, old in [('lost-finite-scope', 'These headers qualify only the retained public fixtures.'),
                      ('borrowed-origin-reader', 'record-value-coordinate-public-origin-selection-20261007/verify.py'),
                      ('lost-byte-conservation', 'Every raw header and')]:
        changed = native.replace(old, 'borrowed', 1)
        need(changed != native, 'genuine finite-origin native guide control')
        try:
            check(source, changed, actual)
        except ValueError as error:
            need(str(error) == 'complete native finite origin selection guide and unmeasured scope',
                 'intended complete native origin guide refusal')
            controls.append(dict(control=name, status=1, cause=str(error)))
        else:
            raise ValueError('false-green finite-origin native guide control')
    changed = copy.deepcopy(actual); changed['status'] = False
    try:
        check(source, native, changed)
    except ValueError as error:
        need(str(error) == 'whole exact same-volume native build and integer success', 'intended typed native result refusal')
        controls.append(dict(control='Boolean-native-status', status=1, cause=str(error)))
    else:
        raise ValueError('false-green typed native result')
    proof['controls'] = controls
    path = BASE / 'book-proof.json'; raw = json.dumps(proof, sort_keys=True, indent=2) + '\n'
    if path.exists():
        need(path.read_text() == raw, 'whole retained finite origin native guide proof')
    else:
        path.write_text(raw)
    print('PASS complete saved source/native finite public origin guide and genuine controls; native bad variants and original identities remain pending.')


if __name__ == '__main__':
    main()
