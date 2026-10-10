"""Publish qualified preparation, leaving canonical admission explicitly pending."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/coordinate-current-preparation-20261010')
REVISION = '2bcc068255dbf6687ed92f20e8da24cf73351515'
CHAPTER = Path('docs/book/src/90-reference-map.md')
MARKER = 'Atomic current canonical publication remains the next owned step.'
BLOCK = '''The current-coordinate publication now has a qualified complete proposal.
It retains the original core, helper, tooling and parser card sources, every
ordered question and a reviewed paragraph correspondence. The proposed working
set does not grow, and Knowledge Map collection authority remains unchanged.
The parser's earlier epoch-current route is distinguished from its unchanged
historical snapshot and the planned complete maintained current route.

Independent binary Git reconstruction checks complete sources, question/probe
obligations, physical dimensions and genuine loss, borrowed-role, typed-result
and scope-promotion controls. This is reviewed semantic correspondence rather
than a mechanical proof of natural-language equivalence. Live cards and current
reader behavior have not changed. Replay the dated preparation with:

```sh
python3 -B docs/audits/coordinate-current-preparation-20261010/verify.py --snapshot
```

Atomic card/checker/book/source/query/native publication and whole final delivery
remain the next owned steps. The proposal preserves original private/provider/
framework/formatter/toolchain/identity/address/alias gaps and visual, HIAL and
full-CI/push owners.

'''


def git(*args):
    result = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    if result.returncode or result.stderr:
        raise ValueError('whole fixed book source')
    return result.stdout


def counts(rows):
    return {'files': len(rows), 'bytes_total': sum(map(len, rows)),
            'lines_total': sum(r.count(b'\n') for r in rows)}


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def main():
    if (BASE / 'book.json').exists():
        raise ValueError('refuse to overwrite completed preparation publication')
    receipt = json.loads((BASE / 'checks.json').read_bytes())['independent']
    if type(receipt['status']) is not int or receipt['status'] != 0:
        raise ValueError('complete independent preparation success before book write')
    before = git('show', REVISION + ':' + str(CHAPTER))
    if CHAPTER.read_bytes() != before or before.count(MARKER.encode()) != 1:
        raise ValueError('unique complete preparation book insertion')
    after = before.replace(MARKER.encode(), (BLOCK + MARKER).encode(), 1)
    paths = sorted(p for p in git('ls-tree', '-r', '--name-only', REVISION, '--', 'docs/book/src').decode().splitlines()
                   if p.endswith('.md') and Path(p).parent == Path('docs/book/src'))
    if paths != sorted(str(p) for p in Path('docs/book/src').glob('*.md')):
        raise ValueError('whole unchanged book membership')
    original_rows = [git('show', REVISION + ':' + p) for p in paths]
    current_rows = [after if p == str(CHAPTER) else Path(p).read_bytes() for p in paths]
    if [p for p,a,b in zip(paths, original_rows, current_rows) if a != b] != [str(CHAPTER)]:
        raise ValueError('only preparation guidance changes')
    old, new = counts(original_rows), counts(current_rows)
    records = list(map(json.loads, Path('doctrine/live_document_size/surfaces.jsonl').read_text().splitlines()))
    for row in records:
        if row.get('surface_id') == 'shipped_behavior':
            row['reference_contract']['aggregate_change'] = {
                'authority_id': 'COORDINATE-CURRENT-PREPARATION-20261010',
                'owner': (BASE / 'scope.txt').read_text().strip(), 'baseline': old,
                'delta': {k: new[k] - old[k] for k in old},
                'rationale': 'Document complete retained non-growing coordinate proposal and historical/current integration roles; current canonical publication remains separately pending.'}
    CHAPTER.write_bytes(after)
    Path('doctrine/live_document_size/surfaces.jsonl').write_text(''.join(json.dumps(r,sort_keys=True)+'\n' for r in records))
    (BASE / 'book.json').write_text(json.dumps({'revision': REVISION, 'source': str(CHAPTER),
        'block': BLOCK, 'marker': MARKER, 'before': pin(before), 'after': pin(after),
        'book_before': old, 'book_after': new},sort_keys=True,indent=2)+'\n')
    print('PASS whole reversible preparation guide and measured aggregate authority; current canonical publication pending.')


if __name__ == '__main__':
    main()
