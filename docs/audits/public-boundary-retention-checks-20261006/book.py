"""Check the native retention-only guide independently of draft construction."""
from html.parser import HTMLParser

COMMAND = 'scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-public-boundary-retention-20261006/verify.py'
GUIDE = '''The superseding retention proposal has a complete reviewed source-fact and
removal map. It preserves each unique source meaning, including the declared
parser receiver and broader observer/display/frame gaps. Removed helper-input
and joined-status narration maps to the richer retained join; the authored
subtest/do-load section stays byte-exact. The revised whole card does not grow
in encoded bytes or line feeds. Genuine fact, gap, question and review-row loss
refuses, including the coherent receiver deletion accepted by the draft check.

The review map records the engineer's semantic equivalence judgments. Its
checker proves the complete declared source census, target presence and tested
loss rejection; it does not decide unrestricted natural-language equivalence.
Completed public-header source and original-population controls authenticate
separately. Replay the retained proposal from the repository root:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-public-boundary-retention-20261006/verify.py
```

This is proposal qualification. Atomic live fact publication, actual current
queries and reader routes remain the next slice. `--live-unchanged` additionally
checks that the pre-publication card and its collection authority still match
their committed sources; it must stop accepting after publication. Default
replay preserves the source/proposal snapshot and does not borrow live currency.
Original framework/provider/private/formatter/reference/coordinate/address
meanings and visual QA remain unmeasured or separately owned.

'''


class Visible(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts, self.codes, self.current = [], [], None

    def handle_starttag(self, tag, attrs):
        if tag == 'code':
            self.current = []

    def handle_data(self, data):
        self.parts.append(data)
        if self.current is not None:
            self.current.append(data)

    def handle_endtag(self, tag):
        if tag == 'code' and self.current is not None:
            self.codes.append(''.join(self.current).strip())
            self.current = None


def check(html):
    p = Visible(); p.feed(html)
    if p.codes.count(COMMAND) != 1:
        raise ValueError('native exact guarded retention-only command')
    expected = GUIDE.replace('```bash\n', '').replace('```\n', '').replace('`', '').replace("engineer's", 'engineer’s')
    if ' '.join(expected.split()) not in ' '.join(' '.join(p.parts).split()):
        raise ValueError('native complete retention-only guide and publication boundary')


def controls(html):
    check(html); results = []
    for key, old, new, cause in (
        ('extra-current-argument', COMMAND, COMMAND + ' --current', 'native exact guarded retention-only command'),
        ('borrowed-current-publication', 'remain the next slice', 'are qualified now', 'native complete retention-only guide and publication boundary'),
        ('invented-semantic-oracle', 'does not decide', 'decides', 'native complete retention-only guide and publication boundary'),
        ('lost-identity-gap', 'meanings and visual QA remain unmeasured', 'meanings and visual QA are complete', 'native complete retention-only guide and publication boundary'),
    ):
        candidate = html.replace(old, new)
        if candidate == html:
            raise ValueError('nongenuine native retention intervention: ' + key)
        try:
            check(candidate)
        except ValueError as error:
            if str(error) != cause:
                raise ValueError('wrong native retention refusal: ' + key) from error
            results.append(dict(control=key, status=1, cause=cause))
        else:
            raise ValueError('false-green native retention control: ' + key)
    return results
