"""Publish and qualify exact current versus retained class/frame guidance."""
from html.parser import HTMLParser
import hashlib
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-publication-20261006')
COMMAND = 'scripts/run_with_ram_guard.sh -- python3 -B ' + str(BASE / 'verify.py') + ' --current'
DEFAULT = COMMAND.removesuffix(' --current')
BUILD = COMMAND + ' --build .artifacts/class-frame-publication-book'
MARKER = 'The own subtest source model now assigns original refusals'
EPOCH = '''The following observer and tooling guides are retained publication checkpoints.
Their earlier current commands check their exact fact epochs. They do not prove
the newly published class/frame facts; use the complete current reader below.
The old programmes, source contracts, native results and seals remain immutable.

'''
GUIDE = '''The complete finite class/frame publication now retains every prior core,
observer and tooling proposition, qualifier, example and ordered question, and
adds the qualified source-class/frame/body/phase/operand join. Every original
nonempty error binds source-inferred class and guard family to its complete own
and finite public phase, function order and visible argument roles. Empty
allocations, source contexts and opaque raw bytes retain. Nested Metadata and
new outer Value keep separate class/phase roles while the entire inner operand
passes through catch, interpolation and the new throw. Source associations were
qualified before the new raw intake. Genuine class/family/phase/order/argument/
population/native-promotion controls conserve predecessor meanings; changing
opaque inner-frame bytes passes those local meanings but breaks whole forwarding.

The current route checks all three complete canonical cards, actual direct and
cached question ownership, every collection-capacity dimension, exact source
budgets and canonical source selection, relative endpoints, current bytes,
ignore policy and indexed members. Its native variant additionally checks every
copied canonical source and the rendered current/retained guide:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-class-frame-publication-20261006/verify.py --current
```

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-class-frame-publication-20261006/verify.py --current --build .artifacts/class-frame-publication-book
```

The core reverify chain still runs the original helper join, finite copy join
and separate fresh finite copy-probe replay before this current check. Tooling
still runs its original destination-locality replay. The fresh finite probe is
not an original raw-error recapture. Earlier admission and retention guides
describe their checkpoints; explicit old-epoch checks refuse the changed facts.

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-class-frame-publication-20261006/verify.py
```

Default replay authenticates complete committed custody, reconstructs the full
retention and class/frame meanings and controls, and checks the saved publication
snapshot and native guide. It cannot establish current currency. Unrelated book
progress is permitted by the current reader. The collection allowance is never
widened; every original fact/question retains. This remains reviewed prose
equivalence rather than unrestricted mechanical natural-language proof.
Original native class/provider/hooks, private frames, formatter, encoding,
hidden arguments, identity, coordinates and address/lifetime meanings remain
unmeasured or separately owned. Visual QA, HIAL repair and full CI/push retain
their owners. Project outputs and scratch remain repository-local.

'''


def old_frame():
    p = Path('docs/audits/record-value-tooling-current-reader-20261006/verify.py')
    ns = {'__name__':'retained_tooling_guide','__file__':str(p)}
    exec(compile(p.read_bytes(),str(p),'exec'),ns)
    return ns['FRAME']


def transform(before):
    frame = old_frame()
    if before.count(MARKER) != 1 or before.count(frame) != 1 or EPOCH in before or COMMAND in before:
        raise ValueError('unique exact current guide and retained checkpoint insertion')
    return before.replace(frame,EPOCH + frame,1).replace(MARKER,GUIDE + MARKER,1)


class Visible(HTMLParser):
    def __init__(self):
        super().__init__(); self.parts,self.codes,self.code = [],[],None
    def handle_starttag(self,tag,attrs):
        if tag == 'code': self.code = []
    def handle_data(self,data):
        self.parts.append(data)
        if self.code is not None: self.code.append(data)
    def handle_endtag(self,tag):
        if tag == 'code' and self.code is not None:
            self.codes.append(''.join(self.code).strip()); self.code = None


def check(html):
    parsed = Visible(); parsed.feed(html)
    if any(parsed.codes.count(command) != 1 for command in (COMMAND,DEFAULT,BUILD)):
        raise ValueError('native exact distinct current default and build commands')
    visible = ' '.join(' '.join(parsed.parts).split())
    for block in (EPOCH,GUIDE):
        text = block.replace('```bash\n','').replace('```\n','').replace('`','')
        if ' '.join(text.split()) not in visible:
            raise ValueError('native complete current retained semantic scope and remaining gaps')


def proof(html):
    check(html); result = []
    for name,old,new,cause in (
        ('borrowed-current-command',COMMAND,DEFAULT,'native exact distinct current default and build commands'),
        ('invented-default-currency','It cannot establish current currency','It establishes current currency','native complete current retained semantic scope and remaining gaps'),
        ('invented-original-recapture','not an original raw-error recapture','an original raw-error recapture','native complete current retained semantic scope and remaining gaps'),
        ('lost-native-gap','unmeasured or separately owned','fully measured and qualified','native complete current retained semantic scope and remaining gaps'),
        ('lost-opaque-inner-operand','opaque inner-frame bytes','fully interpreted inner-frame bytes','native complete current retained semantic scope and remaining gaps')):
        changed = html.replace(old,new)
        if changed == html: raise ValueError('nongenuine native current publication intervention: ' + name)
        try: check(changed)
        except ValueError as error:
            if str(error) != cause: raise ValueError('wrong native current publication refusal: ' + name) from error
            result.append(dict(control=name,status=1,cause=cause))
        else: raise ValueError('false-green native current publication scope: ' + name)
    return dict(input_identity=dict(bytes=len(html.encode()),sha256=hashlib.sha256(html.encode()).hexdigest()),controls=result,visual_QA='pending; separately owned')
