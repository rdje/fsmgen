"""Exact native command and scoped guidance proof; this is not visual QA."""
import hashlib
import json
import subprocess
from html.parser import HTMLParser

COMMAND = 'scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-parser-context-join-20261006/verify.py'
GUIDANCE = '''The complete own parser context replay
joins the finite parser/API core, observer operation, helper and subtest/load
source roles throughout every retained refusal. Per-phase core order, operation
overlap, wrapper/helper/body/entry/load adjacency and complete own frame coverage
agree. Completed nested API allocations conserve separately; their empty error
footprints supply no active throw frames.

The source-only guides below retain their inventory/model roles. This context
replay adds the finite frame join; full combined fact publication is the next
stage. External framework intervals, original formatter/provider versions,
scalar encoding, hidden suffixes, referent contents/identity, coordinates and
addresses remain unmeasured. The source load operator stays do; the recorded
require marker agrees only with its file role. Replay from the repository root:'''


class Visible(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts, self.codes, self.code, self.hrefs = [], [], None, []

    def handle_starttag(self, tag, attributes):
        if tag == 'a':
            href = dict(attributes).get('href', '')
            if href.startswith('reference-source/'):
                self.hrefs.append(href)
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
        raise ValueError('native exact context-join replay command')
    admitted = {json.loads(line)['asset'] for line in subprocess.check_output(
        ['git', 'show', 'b0fd54bb086db4f1a01c45d6d121c68b35594613:docs/book/src/reference-source/routes.jsonl'], text=True).splitlines()}
    if not parser.hrefs or not set(parser.hrefs) <= admitted:
        raise ValueError('native complete admitted source-link destinations')
    text = ' '.join(' '.join(parser.parts).split())
    if text.count(' '.join(GUIDANCE.split())) != 1:
        raise ValueError('native complete context-join guidance and missing legs')


def proof(html):
    check(html)
    controls = []
    for name, before, after, cause in [
        ('extra-command-argument', COMMAND, COMMAND + ' --borrowed', 'native exact context-join replay command'),
        ('broadened-scope', 'Completed nested API allocations conserve separately;', 'All nested API calls remain active;', 'native complete context-join guidance and missing legs'),
        ('lost-identity-gap', 'scalar encoding, hidden suffixes, referent contents/identity, coordinates and', 'coordinates and', 'native complete context-join guidance and missing legs'),
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
    # The new proof scopes are repository evidence, not admitted source assets.
    for name in ('parser-function-order', 'parser-argument-roles', 'parser-context-join'):
        target = 'reference-source/docs/audits/record-value-' + name + '-20261006/scope.txt.source.txt'
        changed = html.replace('The complete own parser context replay', '<a href="' + target + '">The complete own parser context replay</a>', 1)
        if changed == html:
            raise ValueError('vacuous source-link control')
        try:
            check(changed)
        except ValueError as error:
            if str(error) != 'native complete admitted source-link destinations':
                raise ValueError('wrong source-link control cause') from error
            controls.append({'control': 'unadmitted-' + name + '-link', 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green unadmitted source link')
    raw = html.encode()
    return {'native_identity': {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()},
            'command': COMMAND, 'controls': controls, 'visual_QA': 'not performed; separately owned'}
