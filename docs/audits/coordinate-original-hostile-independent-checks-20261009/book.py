"""Publish the finite hostile scope and measure the complete reversible book change."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/coordinate-original-hostile-independent-checks-20261009')
REVISION = '1626bd7ca68741492d1b5bc9377f32dd9f64d334'
CHAPTER = Path('docs/book/src/90-reference-map.md')
SURFACES = Path('doctrine/live_document_size/surfaces.jsonl')
OLD = '''Full independent reconstruction remains unfinished. Its first published attempt
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
NEW = '''Full independent reconstruction now qualifies the complete dated product.
The reader rebuilds every source-linked coordinate and forwarding interval,
then constructs every observed recipe/mode intervention using separate byte
intervals. Each intervention passes the complete unchanged predecessor
predicates before both coordinate procedures reject its changed coordinate or
source association. The complete result matches the sealed producer product.

The independent run freshly replays the complete original/source/matching
reader chain and reauthenticates every original custody member before and after
its interventions. Whole-result controls reject missing points, recipes,
forwarded pairs and empty allocations, borrowed intervention data, false
predecessor results, Boolean statuses and borrowed reader commands or output.
It also reproduces the first duplicate-allocation and exhausted-line failures,
and verifies the retained interrupted producer prefix against the whole result.

Every stopped RAM-guarded attempt retains its non-success status and original
streams. Those attempts do not supply independent success; the completed replay
does. The original seal, programmes, products and guard cutoffs remain unchanged.
Reproduce the full fixed-seal qualification from the repository root:

```sh
python3 -B docs/audits/coordinate-original-hostile-checks-20261009/verify_hostile.py
```

Atomic current canonical publication remains the next owned step. This dated
qualification leaves original private formatting/toolchain/identity, external
framework coordinate rules, address lifetimes and alias downstream with their
existing owners.
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
    receipt = json.loads((BASE / 'checks.json').read_bytes())['published-independent']
    command = ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B',
               'docs/audits/coordinate-original-hostile-checks-20261009/verify_hostile.py']
    if type(receipt['status']) is not int or receipt['status'] != 0 or receipt['command'] != command:
        raise ValueError('complete actual independent hostile success before publication')
    result = json.loads(receipt['stdout'])
    if result['result'] != 'PASS complete independent original-coordinate hostile qualification and predecessor preservation':
        raise ValueError('complete actual independent hostile result before publication')
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
                'authority_id': 'COORDINATE-ORIGINAL-HOSTILE-INDEPENDENT-20261009', 'baseline': before,
                'delta': {key: after[key] - before[key] for key in before}, 'owner': owner,
                'rationale': 'Publish whole original matching hostile qualification, finite source-recipe/mode intervention scope, predecessor preservation and independent byte-interval controls; retain current canonical publication and opaque/private successors under unchanged Knowledge Map authority.'}
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
