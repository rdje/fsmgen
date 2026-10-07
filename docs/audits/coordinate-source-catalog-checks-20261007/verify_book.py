"""Qualify the complete scoped source-catalog guide at its saved book epoch."""
import copy
import hashlib
import json
import subprocess
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/coordinate-source-catalog-checks-20261007')
SOURCE = 'docs/book/src/13k-isf-feature-support-matrix.md'
REVISION = 'ac6fa991addfc1537603a4d7fd023b69a048c692'
MARKER = ('The current reader also independently consumes this committed admission’s complete\n'
          'historical and native result evidence before checking present source currency.\n')
BLOCK = '''
The own-source coordinate catalog now binds complete guard/call, named function,
observer wrapper, callback and subtest source spans to their exact UTF-8 bytes
and lexical line ranges. It preserves ordered observer generation and the
original fixture-root invocation recipes. Lexical spans do not yet select
runtime call-site lines or qualify original raw coordinates:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-source-catalog-20261007/verify.py
```
'''


def require(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


class Visible(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.parts = []

    def handle_data(self, data):
        self.parts.append(data)


def check(source, rendered, actual):
    before = subprocess.check_output(['git', 'show', REVISION + ':' + SOURCE]).decode()
    require(before.count(MARKER) == 1 and source == before.replace(MARKER, MARKER + BLOCK),
            'whole source guide exact scoped insertion and prior conservation')
    require(type(actual['status']) is int and actual['status'] == 0
            and actual['command'] == ['scripts/run_with_ram_guard.sh', '--', 'mdbook', 'build',
                'docs/book', '--dest-dir', '.artifacts/coordinate-source-catalog-book'],
            'actual exact same-volume native book build command and integer success')
    visible = Visible(); visible.feed(rendered)
    guide = BLOCK.replace('```bash\n', '').replace('```\n', '')
    require(' '.join(guide.split()) in ' '.join(''.join(visible.parts).split()),
            'complete native source-catalog guide and explicit coordinate deferral')
    return dict(source=pin(source.encode()), native=pin(rendered.encode()), actual=actual,
        scope='Exact scoped saved source/native guide; no live future currency, runtime line selection, original coordinate, formatter/private identity or visual QA claim.')


def main():
    source = (BASE / 'book-source.md.txt').read_text()
    rendered = (BASE / 'book-input.html').read_text()
    actual = json.loads((BASE / 'book.json').read_bytes())
    product = check(source, rendered, actual)
    refusals = []
    cases = [('lost-runtime-deferral', source, rendered.replace('or qualify original raw coordinates:', '', 1), actual),
             ('borrowed-reader-route', source, rendered.replace('record-value-coordinate-source-catalog-20261007/verify.py', 'borrowed.py', 1), actual)]
    for name, s, html, row in cases:
        require(html != rendered, 'genuine native book control')
        try:
            check(s, html, row)
        except ValueError as error:
            require(str(error) == 'complete native source-catalog guide and explicit coordinate deferral',
                    'intended native guide refusal')
            refusals.append(dict(control=name, status=1, cause=str(error)))
        else:
            raise ValueError('false-green native book guide control')
    changed = copy.deepcopy(actual); changed['status'] = False
    try:
        check(source, rendered, changed)
    except ValueError as error:
        require(str(error) == 'actual exact same-volume native book build command and integer success',
                'intended native status refusal')
        refusals.append(dict(control='Boolean-native-status', status=1, cause=str(error)))
    else:
        raise ValueError('false-green native book status')
    product['controls'] = refusals
    destination = BASE / 'book-proof.json'
    encoded = json.dumps(product, sort_keys=True, indent=2) + '\n'
    if destination.exists():
        require(destination.read_text() == encoded, 'whole retained native guide proof')
    else:
        destination.write_text(encoded)
    print('PASS complete saved scoped source/native coordinate catalog guide and genuine controls; runtime line selection and original coordinate join remain pending.')


if __name__ == '__main__':
    main()
