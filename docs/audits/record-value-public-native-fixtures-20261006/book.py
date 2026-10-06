"""Finite public fixture guide and native rejection controls."""
from html.parser import HTMLParser

COMMAND = 'scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-public-native-fixtures-20261006/verify.py --current'
GUIDE = '''Independent current public fixtures now qualify authored Test::More and
Test::Builder callback bodies and forwarded scalar arguments, own caller edges,
block-eval success/failure roles, isolated do/require loads and configurable
Carp trace argument visibility. Expected roles come from separate own source and
published contracts before native outputs are consumed. Successful mutated
fixture processes separate wrong body, argument, eval, call and trace policies.

The first shared-file fixture exposed a load-cache interaction: this do
invocation registered the identifier before require, so require skipped its
body. Separate own filenames isolate both operators. The first trace also
retained the direct emitting helper as a location rather than a named call;
only the authored outer call and argument-policy difference are qualified.
These are finite current observations, with the complete first refusal retained.

Default replay verifies saved source/native evidence. Explicit current replay
also compares complete raw current fixture output and reruns behavioral controls:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-public-native-fixtures-20261006/verify.py --current
```

External framework names stay opaque. These fixtures do not measure original
framework/provider versions, private operations, full formatter or hidden
arguments, reference identity, direct-emitter/source coordinates or addresses.
The finite original public-boundary join and full current fact publication
remain the next owned steps. All project outputs and scratch stay local;
installed public toolchain access is necessary and read-only.

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
    p = Visible(); p.feed(html)
    if p.codes.count(COMMAND) != 1:
        raise ValueError('native exact public fixture current command')
    expected = GUIDE.replace('```bash\n', '').replace('```\n', '')
    if ' '.join(expected.split()) not in ' '.join(' '.join(p.parts).split()):
        raise ValueError('native complete public fixture scope and historical gaps')


def proof(html):
    check(html)
    result = []
    for name, before, after, cause in [
        ('extra-fixture-argument', COMMAND, COMMAND + ' --borrowed', 'native exact public fixture current command'),
        ('invented-historical-version', 'do not measure original', 'measure original', 'native complete public fixture scope and historical gaps'),
        ('invented-private-meaning', 'External framework names stay opaque.', 'External framework names are explained.', 'native complete public fixture scope and historical gaps'),
    ]:
        changed = html.replace(before, after)
        if changed == html:
            raise ValueError('nongenuine native fixture guide intervention: ' + name)
        try:
            check(changed)
        except ValueError as error:
            if str(error) != cause:
                raise ValueError('wrong native fixture guide refusal: ' + name) from error
            result.append(dict(control=name, status=1, cause=str(error)))
        else:
            raise ValueError('false-green native fixture guide: ' + name)
    return dict(command=COMMAND, controls=result, visual_QA='pending; separately owned')
