"""Native finite public-header compatibility guide; private history stays open."""
from html.parser import HTMLParser

COMMAND = 'scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-public-boundary-join-20261006/verify.py'
GUIDE = '''The complete finite original public boundary join now compares source-selected
named-subtest bodies, own eval/delegate/load boundaries and recorded public
Test::Builder/Test::More headers. Published interfaces and separate current
fixtures select the public symbols and path before original traces are examined.
Across the original cases and throw phases, visible authored-name displays and
CODE kinds agree with the public signatures and body/delegate/entry/load order.
Receiver tokens stay opaque; truncated displays qualify only visible prefixes.

Wrong public names, callback kinds, extra public frames and an early delegate
first pass the prior own-source semantic composite within their intervention
epoch, then fail the new public-header check. That local acceptance never
replaces original ancestry: complete committed roots, actual seal checkers and
every original raw body remain independently authenticated and conserved.

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-public-boundary-join-20261006/verify.py
```

This qualifies finite source/header compatibility with the dated exercised
public interfaces. It does not establish the original framework/provider
versions, private delegation or eval purposes, original formatter/settings,
hidden suffixes, scalar encoding, receiver/callback contents or identity,
coordinates or addresses. Private framework frames and eval intervals remain
opaque. The authored load operator remains do despite its displayed require
marker. Full current fact publication and the class/frame and coordinate/address
joins retain their own next steps; current compatibility never supplies missing
historical identity.

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
    p = Visible()
    p.feed(html)
    if p.codes.count(COMMAND) != 1:
        raise ValueError('native exact original public join command')
    visible = ' '.join(' '.join(p.parts).split())
    for stale in ('original outer-boundary join remains the next step.',
                  'The finite original public-boundary join and full current fact publication remain the next owned steps.'):
        if stale in visible:
            raise ValueError('native completed public join deferrals retired')
    expected = GUIDE.replace('```bash\n', '').replace('```\n', '')
    if ' '.join(expected.split()) not in ' '.join(' '.join(p.parts).split()):
        raise ValueError('native full finite public compatibility and historical gaps')


def proof(html):
    check(html)
    result = []
    for name, before, after, cause in [
        ('extra-public-join-argument',COMMAND,COMMAND+' --borrowed','native exact original public join command'),
        ('stale-profile-next-step','</body>','<p>original outer-boundary join remains the next step.</p></body>','native completed public join deferrals retired'),
        ('invented-original-version','does not establish the original','establishes the original','native full finite public compatibility and historical gaps'),
        ('invented-private-eval-purpose','Private framework frames and eval intervals remain','Private framework frames and eval intervals are explained and remain','native full finite public compatibility and historical gaps'),
    ]:
        changed = html.replace(before, after)
        if changed == html:
            raise ValueError('nongenuine public join guide intervention: ' + name)
        try:
            check(changed)
        except ValueError as error:
            if str(error) != cause:
                raise ValueError('wrong native public join refusal: ' + name) from error
            result.append(dict(control=name, status=1, cause=str(error)))
        else:
            raise ValueError('false-green native public join guide: ' + name)
    return dict(command=COMMAND, controls=result, visual_QA='pending; separately owned')
