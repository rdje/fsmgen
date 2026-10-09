"""Publish the finite hostile scope and measure the complete reversible book change."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/coordinate-original-hostile-checks-20261009')
REVISION = '32c5f718528c9ca38b72ef0333e26703663674ab'
CHAPTER = Path('docs/book/src/90-reference-map.md')
SURFACES = Path('doctrine/live_document_size/surfaces.jsonl')
OLD = '''Whole hostile qualification and atomic current canonical publication remain
next. Address lifetimes and alias downstream remain separately owned.
'''
NEW = '''The complete dated producer now executes original own-coordinate controls.
It enumerates every recorded own coordinate and selects a representative of
each observed source recipe in each admitted mode. The controls replace a
terminal reported line or filename, or borrow a source declaration from a
different file. Every completed producer control passes the complete predecessor
class, frame, function, visible-argument and forwarding predicates before both
coordinate procedures reject the changed coordinate or source association.

Nested interventions change the child body and its complete forwarded parent
together. Every nonempty original record and every admitted forwarding pair
receives line and filename interventions. Untargeted records, complete function
and argument text, and recorded context remain unchanged. The producer retains
the whole original/source/matching replay and reauthenticates every immutable
original custody member after its controls.

Separate geometry reconstruction agrees on the complete source-linked point and
forwarding allocation. Independent byte-interval examples cover origins,
callers, loads and forwarded errors. Positive adjacent-line controls also pass
for the parser facade in every mode. The first duplicate-allocation and exhausted
candidate-line constructor failures retain beside their verified corrections.
The complete producer is sealed; genuine copied missing, borrowed, extra,
resealed and symlinked corpora are rejected while the originals conserve.

Full independent reconstruction remains unfinished. Its first published attempt
stopped at the unchanged host-memory cutoff before reconstructing the controls.
An earlier producer attempt also retains its full partial-control journal and
matching replay with its non-success status. These stopped attempts do not
supply the missing independent leg. Retry the required complete reader from the
repository root when host headroom permits:

```sh
python3 -B docs/audits/coordinate-original-hostile-checks-20261009/verify_hostile.py
```

Complete independent qualification precedes atomic current canonical
publication. Original private formatting/toolchain/identity, external framework
coordinate rules, address lifetimes and alias downstream retain their existing
owners.
'''


def fixed(*args):
    run = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    if run.returncode != 0 or run.stderr:
        raise ValueError('complete fixed hostile book source')
    return run.stdout


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def metrics(rows):
    return {'files': len(rows), 'bytes_total': sum(map(len, rows)),
            'lines_total': sum(raw.count(b'\n') for raw in rows)}


def main():
    destination = BASE / 'book.json'
    if destination.exists():
        raise ValueError('first hostile book publication only')
    original = fixed('show', REVISION + ':' + str(CHAPTER))
    if CHAPTER.read_bytes() != original or original.count(OLD.encode()) != 1:
        raise ValueError('unique unchanged hostile book source')
    CHAPTER.write_bytes(original.replace(OLD.encode(), NEW.encode(), 1))
    paths = sorted(str(p) for p in Path('docs/book/src').glob('*.md'))
    old_paths = sorted(p for p in fixed('ls-tree', '-r', '--name-only', REVISION, '--', 'docs/book/src').decode().splitlines()
                       if Path(p).parent == Path('docs/book/src') and p.endswith('.md'))
    if paths != old_paths:
        raise ValueError('complete unchanged hostile book membership')
    before_rows = [fixed('show', REVISION + ':' + p) for p in paths]
    after_rows = [Path(p).read_bytes() for p in paths]
    if [p for p, a, b in zip(paths, before_rows, after_rows) if a != b] != [str(CHAPTER)]:
        raise ValueError('only owned hostile book guidance changes')
    before, after = metrics(before_rows), metrics(after_rows)
    owner = (BASE / 'scope.txt').read_text().strip()
    records = list(map(json.loads, SURFACES.read_text().splitlines()))
    for record in records:
        if record.get('surface_id') == 'shipped_behavior':
            record['reference_contract']['aggregate_change'] = {
                'authority_id': 'COORDINATE-ORIGINAL-HOSTILE-CHECKPOINT-20261009', 'baseline': before,
                'delta': {key: after[key] - before[key] for key in before}, 'owner': owner,
                'rationale': 'Publish the complete sealed producer checkpoint, verified geometry/fallback/copied-seal controls and explicit RAM-blocked independent-qualification gap; retain whole qualification, current canonical publication and opaque/private successors under unchanged Knowledge Map authority.'}
    SURFACES.write_text(''.join(json.dumps(row, sort_keys=True) + '\n' for row in records))
    destination.write_text(json.dumps({
        'revision': REVISION, 'owner': owner, 'source': str(CHAPTER),
        'before': pin(original), 'after': pin(CHAPTER.read_bytes()),
        'original_block': OLD, 'current_block': NEW, 'book_before': before, 'book_after': after,
        'legs': {'rederive': 'Whole fixed-Git chapter membership and source bytes measured before/after the unique replacement.',
                 'falsify': 'Independent whole-book reversal, actual source/native receipts and genuine product/receipt controls in verify_delivery.py.',
                 'durability': 'Fixed source revision, exact blocks and identities, tracked measurements and actual receipts; normal staged doctrines and Git hooks.'},
    }, sort_keys=True, indent=2) + '\n')
    print('PASS reversible whole hostile book publication and exact aggregate authority; all ceilings and Knowledge Map authority unchanged.')


if __name__ == '__main__':
    main()
