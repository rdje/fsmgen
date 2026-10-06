"""Scoped installed public-profile guidance; native/source meanings stay open."""
from html.parser import HTMLParser

COMMAND = 'scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-public-framework-profile-20261006/verify.py --current'
GUIDE = '''The dated installed public framework profile now pins complete caller/eval,
Carp and Test::More/Test::Builder documentation plus runtime version and public
documentation-location accessors. These public contracts describe callback
argument forwarding, block-eval/error roles and trace interfaces. Debugger
argument snapshots are best effort and may reflect aliases or later changes;
they do not establish original argument or reference identity.

This qualifies the installed public documentation/profile only. Independent
public native controls and the original outer-boundary join remain next steps.
The original framework/provider version and private implementation, full trace
display, scalar encoding, hidden suffixes, coordinates and addresses remain
unmeasured. Necessary installed toolchain documentation is read-only; all
project captures and scratch stay inside the repository.

Default replay verifies the dated saved profile. Explicit current replay also
reexecutes the pinned public commands and compares every raw output byte:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-public-framework-profile-20261006/verify.py --current
```

'''


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
        raise ValueError('native exact public-profile current command')
    expected = GUIDE.replace('```bash\n', '').replace('```\n', '')
    if ' '.join(expected.split()) not in ' '.join(' '.join(parser.parts).split()):
        raise ValueError('native complete public-profile scope and historical gaps')


def proof(html):
    check(html)
    controls = []
    for name, before, after, cause in (
        ('extra-profile-argument', COMMAND, COMMAND + ' --borrowed', 'native exact public-profile current command'),
        ('invented-original-version', 'unmeasured. Necessary installed', 'measured. Necessary installed', 'native complete public-profile scope and historical gaps'),
        ('invented-argument-identity', 'they do not establish original argument or reference identity.', 'they establish original argument and reference identity.', 'native complete public-profile scope and historical gaps'),
    ):
        changed = html.replace(before, after)
        if changed == html:
            raise ValueError('nongenuine native profile intervention: ' + name)
        try:
            check(changed)
        except ValueError as error:
            if str(error) != cause:
                raise ValueError('wrong native profile refusal: ' + name) from error
            controls.append(dict(control=name, status=1, cause=str(error)))
        else:
            raise ValueError('false-green native public-profile guide: ' + name)
    return dict(command=COMMAND, controls=controls, visual_QA='pending; separately owned')
