"""Qualify the semantic-retention proposal guide and genuine native scope losses."""
from html.parser import HTMLParser
import hashlib

COMMAND = 'scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-class-frame-retention-20261006/verify.py'
MARKER = 'The own subtest source model now assigns original refusals'
GUIDE = '''The semantic-retention checkpoint prepares the complete core, observer and
tooling fact proposal before changing live cards or reader routes. Every original
sentence or clause maps to reviewed survivor text, with its qualifiers, examples,
identity, ordered questions, evidence and replay obligations retained. Exact code
literals and original front matter stay unchanged. This is engineer-reviewed
prose equivalence; mechanical coverage is not unrestricted natural-language proof.

The additions bind the complete qualified source-class/frame/body/phase/operand
join and its separating controls. Full original physical and logical membership,
global question allocation and every collection-capacity dimension are checked.
Compaction does not grow the complete proposed byte or line-feed population or
widen its collection authority. Actual loss controls cover propositions,
qualifiers, questions, source members, completed owners, kinds and native scope.

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-class-frame-retention-20261006/verify.py
```

The default regenerates the complete frozen proposal and semantic authority,
checks the saved fresh admission execution, retained first failed budgets,
controls and native guide. It does not claim live current fact publication.
The additional `--live-unchanged` check requires the old complete fact epoch;
atomic publication and updated current routes remain a separate successor.
The preparation and fresh replay roles qualify this unchanged pre-publication
epoch; original native captures and transitive native executions are retained,
never recaptured. Private frames, native class/provider/hooks, formatter,
encoding, hidden arguments, identity, coordinates and address/lifetime meanings
remain unmeasured or separately owned. Visual QA, HIAL repair and full CI/push
retain their owners. Project outputs and scratch remain repository-local.

'''


def transform(before):
    if before.count(MARKER) != 1 or COMMAND in before:
        raise ValueError('unique complete semantic-retention guide insertion')
    return before.replace(MARKER,GUIDE + MARKER,1)


class Visible(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts,self.codes,self.code = [],[],None

    def handle_starttag(self,tag,attrs):
        if tag == 'code':
            self.code = []

    def handle_data(self,data):
        self.parts.append(data)
        if self.code is not None:
            self.code.append(data)

    def handle_endtag(self,tag):
        if tag == 'code' and self.code is not None:
            self.codes.append(''.join(self.code).strip())
            self.code = None


def check(html):
    parsed = Visible(); parsed.feed(html)
    if parsed.codes.count(COMMAND) != 1:
        raise ValueError('native exact semantic-retention command')
    expected = GUIDE.replace('```bash\n','').replace('```\n','').replace('`','')
    if ' '.join(expected.split()) not in ' '.join(' '.join(parsed.parts).split()):
        raise ValueError('native complete semantic-retention scope and retained gaps')


def proof(html):
    check(html)
    result = []
    for name,old,new,cause in (
        ('wrong-command',COMMAND,COMMAND + ' --borrowed','native exact semantic-retention command'),
        ('invented-current-publication','It does not claim live current fact publication','It qualifies live current fact publication','native complete semantic-retention scope and retained gaps'),
        ('invented-recapture','never recaptured','newly recaptured','native complete semantic-retention scope and retained gaps'),
        ('lost-human-review-limit','mechanical coverage is not unrestricted natural-language proof','mechanical coverage proves unrestricted natural-language equivalence','native complete semantic-retention scope and retained gaps'),
        ('lost-native-gap','remain unmeasured or separately owned','are fully qualified','native complete semantic-retention scope and retained gaps')):
        changed = html.replace(old,new)
        if changed == html:
            raise ValueError('nongenuine native semantic-retention intervention: ' + name)
        try:
            check(changed)
        except ValueError as error:
            if str(error) != cause:
                raise ValueError('wrong native semantic-retention refusal: ' + name) from error
            result.append(dict(control=name,status=1,cause=cause))
        else:
            raise ValueError('false-green native semantic-retention guide: ' + name)
    return dict(input_identity=dict(bytes=len(html.encode()),sha256=hashlib.sha256(html.encode()).hexdigest()),
                controls=result,visual_QA='pending; separately owned')
