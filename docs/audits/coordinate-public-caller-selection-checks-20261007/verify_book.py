"""Qualify the complete scoped public caller-selection guide at its saved epoch."""
import copy
import hashlib
import json
import subprocess
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/coordinate-public-caller-selection-checks-20261007')
SOURCE = 'docs/book/src/13k-isf-feature-support-matrix.md'
REVISION = '3ae29914b6a74f4009a52b6c9e8136f2bd471039'
OLD_BLOCK = '\nPublic coordinate hypotheses preserve the source-selected first and closing\nline and filename alternatives fixed before observations. Dated executions now\nretain complete source, command, output, frame and error bytes. The readers\nreplay pre-native sources and captured custody; line/filename selection and\nnative wrong-caller, line and source controls remain pending:\n\n```bash\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-public-hypotheses-20261007/verify.py\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-public-capture-20261007/verify.py\n```\n'
BLOCK = '\nPublic coordinate hypotheses preserve the source-selected first and closing\nline and filename alternatives fixed before observations. Dated executions\nretain complete source, command, output, frame and error bytes. For these own\nfixtures, multiline calls and block eval boundaries select their opening lines;\nwhen both source alternatives occupy the same line, both labels remain valid.\nThe readers replay pre-native sources, captured custody and caller/boundary\nselection. Trace origins and native wrong-caller, line and source controls\nremain pending:\n\n```bash\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-public-hypotheses-20261007/verify.py\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-public-capture-20261007/verify.py\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-public-caller-selection-20261007/verify.py\n```\n'


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
    require(before.count(OLD_BLOCK) == 1 and source == before.replace(OLD_BLOCK, BLOCK),
            'whole source guide exact scoped replacement and prior conservation')
    require(type(actual['status']) is int and actual['status'] == 0
            and actual['command'] == ['scripts/run_with_ram_guard.sh', '--', 'mdbook', 'build',
                'docs/book', '--dest-dir', '.artifacts/coordinate-public-caller-selection-book'],
            'actual exact same-volume native book build command and integer success')
    visible = Visible(); visible.feed(rendered)
    guide = BLOCK.replace('```bash\n', '').replace('```\n', '')
    require(' '.join(guide.split()) in ' '.join(''.join(visible.parts).split()),
            'complete native public caller-selection guide and pending origin/control scope')
    return dict(source=pin(source.encode()), native=pin(rendered.encode()), actual=actual,
        scope='Exact scoped saved source/native guide; no live future currency, unrestricted runtime coordinate selection, original coordinate, formatter/private identity or visual QA claim.')


def main():
    source = (BASE / 'book-source.md.txt').read_text()
    rendered = (BASE / 'book-input.html').read_text()
    actual = json.loads((BASE / 'book.json').read_bytes())
    product = check(source, rendered, actual)
    refusals = []
    cases = [('lost-origin-deferral', source, rendered.replace('Trace origins and native wrong-caller, line and source controls', '', 1), actual),
             ('borrowed-reader-route', source, rendered.replace('record-value-coordinate-public-caller-selection-20261007/verify.py', 'borrowed.py', 1), actual),
             ('lost-equivalent-label-scope', source, rendered.replace('both labels remain valid.', '', 1), actual)]
    for name, s, html, row in cases:
        require(html != rendered, 'genuine native book control')
        try:
            check(s, html, row)
        except ValueError as error:
            require(str(error) == 'complete native public caller-selection guide and pending origin/control scope',
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
    print('PASS complete saved source/native public caller-selection guide and genuine controls; origins, native semantic controls and original join remain pending.')


if __name__ == '__main__':
    main()
