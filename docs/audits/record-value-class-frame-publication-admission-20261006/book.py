"""Qualify the bounded publication-admission guide and native scope controls."""
from html.parser import HTMLParser
import hashlib

COMMAND = 'scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-class-frame-publication-admission-20261006/verify.py'
MARKER = 'The own subtest source model now assigns original refusals'
GUIDE = '''The publication-admission checkpoint authenticates the complete committed
class/frame source models, semantic controls, actual-result programmes and every
transitive admitted member at 017a8f70. Complete source associations, raw objects,
class/frame/body/phase/operand joins and separating controls are reconstructed
and compared as whole values. Existing committed model/raw corpora remain the
durable evidence; this checkpoint does not duplicate their large representations.

Fresh executions cover the full semantic reader, independent actual-result
reader and pre-publication current-tooling reader. Their commands, complete
streams, integer statuses, roles and invocation-time source/input identities
are retained separately. Original native captures and transitive native results
remain retained evidence, never a new recapture. Existing canonical facts,
ordered questions, query routes, source budgets and collection authority stay
unchanged. Semantic retention and atomic current publication remain pending.

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-class-frame-publication-admission-20261006/verify.py
```

The default authenticates whole committed custody, regenerates complete
semantic products, checks saved scoped executions and genuine member, owner,
kind, native-scope, question, authority and borrowed-result refusals, and checks
the saved native guide. It checks the unchanged pre-publication fact epoch;
a qualified successor owns later fact or route changes. It does not rerun those
prerequisite processes or claim live current class/frame publication.
Independent actual-result qualification
also rejects typed status/counts, omitted members, widened guard and real
borrowed narrower successes. Original native class/provider/hooks, private
frames, formatter, scalar encoding, identity, coordinates and address/lifetimes
remain unmeasured or separately owned. Visual QA, HIAL repair and full CI/push
retain their separate owners. Project outputs and scratch remain repository-local.

'''


def transform(before):
    if before.count(MARKER) != 1 or COMMAND in before:
        raise ValueError('unique publication-admission guide insertion')
    return before.replace(MARKER, GUIDE + MARKER, 1)


class Visible(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts, self.codes, self.code = [], [], None

    def handle_starttag(self, tag, attrs):
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
    parsed = Visible(); parsed.feed(html)
    if parsed.codes.count(COMMAND) != 1:
        raise ValueError('native exact publication-admission command')
    expected = GUIDE.replace('```bash\n', '').replace('```\n', '')
    if ' '.join(expected.split()) not in ' '.join(' '.join(parsed.parts).split()):
        raise ValueError('native complete publication-admission scope and retained gaps')


def proof(html):
    check(html)
    result = []
    for name, old, new, cause in (
        ('wrong-command', COMMAND, COMMAND + ' --borrowed', 'native exact publication-admission command'),
        ('invented-recapture', 'never a new recapture', 'now a new recapture', 'native complete publication-admission scope and retained gaps'),
        ('invented-current-publication', 'Semantic retention and atomic current publication remain pending', 'Semantic retention and atomic current publication are complete', 'native complete publication-admission scope and retained gaps'),
        ('lost-native-gap', 'remain unmeasured or separately owned', 'are fully qualified', 'native complete publication-admission scope and retained gaps')):
        changed = html.replace(old, new)
        if changed == html:
            raise ValueError('nongenuine native publication-admission intervention: ' + name)
        try:
            check(changed)
        except ValueError as error:
            if str(error) != cause:
                raise ValueError('wrong native publication-admission refusal: ' + name) from error
            result.append(dict(control=name, status=1, cause=cause))
        else:
            raise ValueError('false-green native publication-admission guide: ' + name)
    return dict(input_identity=dict(bytes=len(html.encode()), sha256=hashlib.sha256(html.encode()).hexdigest()),
                controls=result, visual_QA='pending; separately owned')
