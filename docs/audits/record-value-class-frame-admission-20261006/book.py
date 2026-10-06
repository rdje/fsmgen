"""Verify the complete native admission guide and genuine scope interventions."""
from html.parser import HTMLParser

COMMAND = 'scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-class-frame-admission-20261006/verify.py'
GUIDE = '''Class/frame prerequisite admission now authenticates the complete declared
source-reader and publication audit closure against committed abdf385d. Every
regular member, completed source owner and immutable original capture belongs
to that custody check. Whole empty/nonempty error populations and serialized
bodies regenerate without normalization.

The admission also retains actual fresh class/primary/raw, API and complete
parser/observer/helper/subtest reader executions with their controls. Public
documentation/accessors and authored public fixtures, including native source
mutants, ran again through installed public interfaces. The original capture
and earlier native probes remain retained evidence. The public-header replay
explicitly uses saved transitive prerequisite executions at af4999e7 while
regenerating its source/header/control products. The latest publication and
tooling actual-result reader also reexecuted; its saved native captures remain
saved. Invocation-time source identities, complete commands, statuses and both
streams preserve these distinct roles.

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-class-frame-admission-20261006/verify.py
```

This default command authenticates the committed input domain, regenerates the
whole raw inventory and admission controls, and checks the saved actual replay
results and native guide. It does not rerun those readers or establish live
currency. The sealed admission refuses recapture. Independent result checking
rejects typed status/count substitutions, source/member/owner loss, invented
scope and genuinely borrowed successes.

Admission is not a class/frame semantic join. That independent join remains
the next task, followed by qualified publication. Original native class,
provider/version, hooks, private framework meaning, complete formatter/settings,
hidden arguments, reference identity, coordinates and address/lifetimes remain
unmeasured or separately owned. Current facts, query routes, collection authority
and prior seals remain unchanged. All project output and scratch stay local;
installed public toolchain access is necessary and read-only. Visual QA, HIAL
host-native repair and full CI/push remain separately owned.

'''


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
        raise ValueError('native exact admission command')
    expected = GUIDE.replace('```bash\n', '').replace('```\n', '')
    if ' '.join(expected.split()) not in ' '.join(' '.join(parsed.parts).split()):
        raise ValueError('native complete admission scope and retained gaps')


def proof(html):
    check(html)
    output = []
    for name, before, after, cause in [
        ('wrong-command', COMMAND, COMMAND + ' --borrowed', 'native exact admission command'),
        ('invented-join', 'Admission is not a class/frame semantic join.', 'Admission closes the class/frame semantic join.', 'native complete admission scope and retained gaps'),
        ('invented-recapture', 'earlier native probes remain retained evidence.', 'earlier native probes were recaptured.', 'native complete admission scope and retained gaps'),
        ('lost-gap', 'Original native class,', 'Original measured class,', 'native complete admission scope and retained gaps')]:
        changed = html.replace(before, after)
        if changed == html:
            raise ValueError('nongenuine native admission intervention: ' + name)
        try:
            check(changed)
        except ValueError as error:
            if str(error) != cause:
                raise ValueError('wrong native admission refusal: ' + name) from error
            output.append(dict(control=name, status=1, cause=cause))
        else:
            raise ValueError('false-green native admission control: ' + name)
    import hashlib
    return dict(input_identity=dict(bytes=len(html.encode()), sha256=hashlib.sha256(html.encode()).hexdigest()),
                controls=output, visual_QA='pending; separately owned')
