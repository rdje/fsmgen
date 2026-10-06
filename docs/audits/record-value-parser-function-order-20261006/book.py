"""Exact native command and scoped guidance proof; this is not visual QA."""
import hashlib
from html.parser import HTMLParser

COMMAND = 'scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-parser-function-order-20261006/verify.py'
GUIDANCE = '''The separate parser function-order replay
now binds independently selected own parser/context ancestry to every retained
parser refusal and throw phase. It preserves complete raw bodies and opaque
outer intervals and excludes returned delegates from active own frames.
Genuine raw function/order and complete mode/member/kind controls reject.
This qualifies own function order only. Visible arguments, complete nested
API/helper context, formatter, coordinates and reference identity retain their
separate owners. Replay from the repository root:'''


class Visible(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts, self.codes, self.code = [], [], None

    def handle_starttag(self, tag, attributes):
        if tag == 'code':
            self.code = []

    def handle_data(self, data):
        self.parts.append(data)
        if self.code is not None:
            self.code.append(data)

    def handle_endtag(self, tag):
        if tag == 'code' and self.code is not None:
            self.codes.append(''.join(self.code).strip())
            self.code = None


def check(html):
    parser = Visible()
    parser.feed(html)
    if parser.codes.count(COMMAND) != 1:
        raise ValueError('native exact function-order replay command')
    text = ' '.join(' '.join(parser.parts).split())
    if text.count(' '.join(GUIDANCE.split())) != 1:
        raise ValueError('native complete own-order guidance and missing legs')


def proof(html):
    check(html)
    controls = []
    for name, before, after, cause in [
        ('extra-command-argument', COMMAND, COMMAND + ' --borrowed', 'native exact function-order replay command'),
        ('broadened-scope', 'This qualifies own function order only.', 'This qualifies every native meaning.', 'native complete own-order guidance and missing legs'),
        ('lost-identity-gap', 'formatter, coordinates and reference identity retain their', 'formatter and coordinates retain their', 'native complete own-order guidance and missing legs'),
    ]:
        changed = html.replace(before, after)
        if changed == html:
            raise ValueError('vacuous native book control: ' + name)
        try:
            check(changed)
        except ValueError as error:
            if str(error) != cause:
                raise ValueError('wrong native book control cause: ' + name) from error
            controls.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green native book control: ' + name)
    raw = html.encode()
    return {'native_identity': {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()},
            'command': COMMAND, 'controls': controls, 'visual_QA': 'not performed; separately owned'}
