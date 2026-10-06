"""Retain and diagnose the actual smart-punctuation failure before exact repair."""
import difflib
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-retention-20261006')
CHECKS = Path('docs/audits/class-frame-retention-checks-20261006')
actual = json.loads((CHECKS / 'native-result.json').read_text())
phases = json.loads((CHECKS / 'native-phases.json').read_text())
assert type(actual['status']) is int and actual['status'] == 1
assert len(phases['phases']) == 5 and [r['status'] for r in phases['phases']] == [0,0,0,0,1]
assert 'native complete semantic-retention scope and retained gaps' in actual['stdout']
source = BASE / 'book.py'; ns = {'__name__':'diagnose_native_retention'}
exec(compile(source.read_bytes(),str(source),'exec'),ns)
render = Path('.artifacts/class-frame-retention-book/13k-isf-feature-support-matrix.html')
parsed = ns['Visible'](); parsed.feed(render.read_text())
visible = ' '.join(' '.join(parsed.parts).split()); start = visible.index('The semantic-retention checkpoint')
end = visible.index('The own subtest source model',start)
expected = ' '.join(ns['GUIDE'].replace('```bash\n','').replace('```\n','').split())
observed = visible[start:end].strip()
changes = [(expected[a:b],observed[c:d]) for op,a,b,c,d in difflib.SequenceMatcher(a=expected,b=observed).get_opcodes() if op != 'equal']
assert changes == [('--','–')], 'exact sole smart-punctuation root cause'
retained = {}
for source,name in ((BASE / 'book.py','first-book.py.txt'),(render,'first-book-input.html'),
                    (CHECKS / 'native-result.json','first-native-result.json'),(CHECKS / 'native-phases.json','first-native-phases.json')):
    target = CHECKS / name
    assert source.is_file() and not source.is_symlink() and source.stat().st_dev == Path.cwd().stat().st_dev and not target.exists()
    raw = source.read_bytes(); target.write_bytes(raw); assert target.read_bytes() == raw
    retained[str(target)] = dict(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())
output = CHECKS / 'native-failure.json'; assert not output.exists()
output.write_text(json.dumps(dict(changes=changes,retained=retained,expected=expected,observed=observed,
    cause='mdBook smart punctuation renders plain --live-unchanged as an en dash; exact option must be authored as inline code.',
    scope='Actual first complete native attempt and original guide/render preserved before source repair; no native success claimed.'),sort_keys=True,indent=2) + '\n')
for name in ('native-result.json','native-phases.json'):
    assert (CHECKS / name).read_bytes() == (CHECKS / ('first-' + name)).read_bytes()
    (CHECKS / name).unlink()
print('PASS retained actual first native failure; sole -- to en-dash rendering mismatch independently identified before repair.')
