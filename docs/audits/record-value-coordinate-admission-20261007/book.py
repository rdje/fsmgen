"""Qualify the rendered admission checkpoint without claiming coordinate meaning."""
import hashlib
from pathlib import Path

COMMAND = 'scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-admission-20261007/verify.py'
BLOCK = '''Raw-coordinate qualification first admits the complete predecessor source and
actual-result evidence. Its saved admission checks the dated source epoch; it
does not establish coordinate meanings or later current currency:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-admission-20261007/verify.py
```

The historical publication's independent result qualifier expects its original
fact, book and authority epoch. It rejects later live publication changes.
Admission executes that unchanged qualifier in a disposable same-volume copy of
the committed epoch and checks every source member before and after, preserving
the live sources and removing the fixture. The maintained current reader above
separately checks present currency. Independent coordinate source recipes and
the original-coordinate join remain pending; original private, formatter and
toolchain identities remain unmeasured.

'''


def proof(html):
    namespace = {'__name__': 'coordinate_native_guide', '__file__': 'docs/audits/record-value-class-frame-publication-20261006/book.py'}
    path = Path(namespace['__file__'])
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    parsed = namespace['Visible'](); parsed.feed(html)
    visible = ' '.join(' '.join(parsed.parts).split())
    text = BLOCK.replace('```bash\n', '').replace('```\n', '').replace('`', '')
    if parsed.codes.count(COMMAND) != 1 or ' '.join(text.split()) not in visible:
        raise ValueError('unique complete native coordinate admission scope and checkpoint')
    return dict(command=COMMAND, block=BLOCK, bytes=len(html.encode()),
        sha256=hashlib.sha256(html.encode()).hexdigest(),
        scope='Complete rendered saved-admission/current/unchanged-historical roles; coordinate meanings and visual QA remain pending.')
