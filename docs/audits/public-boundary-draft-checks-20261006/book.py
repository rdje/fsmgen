"""Check the native guide's explicit draft-only scope."""
from html.parser import HTMLParser

COMMAND = 'scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-public-boundary-draft-20261006/verify_draft.py'
GUIDE = '''A source-bound draft for the next fact publication preserves the ordered
questions and authored subtest/do-load section within a non-growing card budget.
The draft check qualifies construction and physical deltas; semantic retention
of removed or re-formed narration remains a separate prerequisite. A coherently
omitted parser-receiver fact still passes the narrow draft check. The publication
slice must reject that loss before changing any live fact or current query route.
The canonical fact card remains unchanged at this draft checkpoint.

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-public-boundary-draft-20261006/verify_draft.py
```

'''


class Visible(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts, self.codes, self.code = [], [], None

    def handle_starttag(self, tag, attrs):
        if tag == 'code':
            self.code = []

    def handle_data(self, text):
        self.parts.append(text)
        if self.code is not None:
            self.code.append(text)

    def handle_endtag(self, tag):
        if tag == 'code' and self.code is not None:
            self.codes.append(''.join(self.code).strip())
            self.code = None


def check(html):
    p = Visible(); p.feed(html)
    if p.codes.count(COMMAND) != 1:
        raise ValueError('native exact draft-only guarded command')
    expected = GUIDE.replace('```bash\n', '').replace('```\n', '')
    if ' '.join(expected.split()) not in ' '.join(' '.join(p.parts).split()):
        raise ValueError('native complete draft-only scope and missing semantic leg')


def proof(html):
    check(html); results = []
    for name, before, after, cause in (
        ('extra-command-argument', COMMAND, COMMAND + ' --current', 'native exact draft-only guarded command'),
        ('borrowed-semantic-retention', 'semantic retention\nof removed', 'complete semantic retention\nof removed', 'native complete draft-only scope and missing semantic leg'),
        ('invented-live-publication', 'fact card remains unchanged', 'fact card is published', 'native complete draft-only scope and missing semantic leg'),
    ):
        changed = html.replace(before, after)
        if changed == html:
            raise ValueError('nongenuine draft guide control: ' + name)
        try:
            check(changed)
        except ValueError as error:
            if str(error) != cause:
                raise ValueError('wrong draft guide refusal: ' + name) from error
            results.append(dict(control=name, status=1, cause=str(error)))
        else:
            raise ValueError('false-green draft guide: ' + name)
    return dict(command=COMMAND, controls=results, visual_QA='pending; separately owned')
