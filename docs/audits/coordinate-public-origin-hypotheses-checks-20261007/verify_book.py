"""Qualify the complete scoped source-only origin guide at its saved epoch."""
import copy
import hashlib
import json
import subprocess
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/coordinate-public-origin-hypotheses-checks-20261007')
SOURCE = 'docs/book/src/13k-isf-feature-support-matrix.md'
REVISION = '52e2769325318ba5e9f79ff84353e32b44d7b086'
OLD_BLOCK = '\nPublic coordinate hypotheses preserve the source-selected first and closing\nline and filename alternatives fixed before observations. Dated executions\nretain complete source, command, output, frame and error bytes. For these own\nfixtures, multiline calls and block eval boundaries select their opening lines;\nwhen both source alternatives occupy the same line, both labels remain valid.\nThe readers replay pre-native sources, captured custody and caller/boundary\nselection. Trace origins and native wrong-caller, line and source controls\nremain pending:\n\n```bash\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-public-hypotheses-20261007/verify.py\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-public-capture-20261007/verify.py\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-public-caller-selection-20261007/verify.py\n```\n'
BLOCK = '\nPublic coordinate hypotheses preserve the source-selected first and closing\nline and filename alternatives fixed before observations. Dated executions\nretain complete source, command, output, frame and error bytes. For these own\nfixtures, multiline calls and block eval boundaries select their opening lines;\nwhen both source alternatives occupy the same line, both labels remain valid.\nThe readers replay pre-native sources, captured custody and caller/boundary\nselection. Trace origins and native wrong-caller, line and source controls\nremain pending:\n\n```bash\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-public-hypotheses-20261007/verify.py\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-public-capture-20261007/verify.py\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-public-caller-selection-20261007/verify.py\n```\n\nPublic origin hypotheses now bind the complete own observer calls, outer\ninvocations, boundaries and longmess/confess statements to source alternatives\nand full public Carp/eval documentation before origin interpretation.\nCarp global, internal and formatter settings remain unmeasured.\nThe source model selects no trace/error origin yet:\n\n```bash\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-public-origin-hypotheses-20261007/verify.py\n```\n'


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
                'docs/book', '--dest-dir', '.artifacts/coordinate-public-origin-hypotheses-book'],
            'actual exact same-volume native book build command and integer success')
    visible = Visible(); visible.feed(rendered)
    guide = BLOCK.replace('```bash\n', '').replace('```\n', '')
    require(' '.join(guide.split()) in ' '.join(''.join(visible.parts).split()),
            'complete native pure-source origin guide and unmeasured/unselected scope')
    return dict(source=pin(source.encode()), native=pin(rendered.encode()), actual=actual,
        scope='Exact scoped saved source/native guide; no live future currency, unrestricted runtime coordinate selection, original coordinate, formatter/private identity or visual QA claim.')


def main():
    source = (BASE / 'book-source.md.txt').read_text()
    rendered = (BASE / 'book-input.html').read_text()
    actual = json.loads((BASE / 'book.json').read_bytes())
    product = check(source, rendered, actual)
    refusals = []
    cases = [('lost-configuration-gap', source, rendered.replace('Carp global, internal and formatter settings remain unmeasured.', '', 1), actual),
             ('borrowed-origin-reader', source, rendered.replace('record-value-coordinate-public-origin-hypotheses-20261007/verify.py', 'borrowed.py', 1), actual),
             ('lost-unselected-origin-scope', source, rendered.replace('The source model selects no trace/error origin yet:', '', 1), actual)]
    for name, s, html, row in cases:
        require(html != rendered, 'genuine native book control')
        try:
            check(s, html, row)
        except ValueError as error:
            require(str(error) == 'complete native pure-source origin guide and unmeasured/unselected scope',
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
    print('PASS complete saved source/native pure-source origin guide and genuine controls; origin interpretation and all original identity meanings remain pending.')


if __name__ == '__main__':
    main()
