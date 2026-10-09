"""Publish scoped book guidance and measure its complete aggregate authority."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/coordinate-observer-caller-checks-20261009')
REVISION = '41985a0f3e72dbfe3e4055c57f150206b29bba2f'
CHAPTER = Path('docs/book/src/90-reference-map.md')
SURFACES = Path('doctrine/live_document_size/surfaces.jsonl')
OLD = 'Complete original matching is next. Whole hostile qualification, alias capture\nand downstream, external framework, private formatting/toolchain and address\nmeanings retain their separate owners.\n\nOriginal coordinate selections, opaque framework callers, private runtime\nformatting/toolchain/identity, address lifetimes and alias downstream retain\ntheir separate owners.\n'
NEW = 'The resumed matcher exposed two draft defects before producing a result: an\nopaque-frame list overwrote the source-candidate lookup, then an inherited\nassertion always associated the recorded caller with the outer operation in\npackage `main`. Both complete failed programmes/results remain retained.\n\nThe recorded observer caller now has a separate complete qualification. Each\nwrapper passes its own `[caller]` value to the recorder. Source operation kind\nselects the matching wrapper before any original coordinate comparison. Nested\nmetadata captures therefore retain the inner Value-package caller, while the\nouter scope records retain their own outer caller. A recorded caller snapshot\nmust follow its operation, rather than whichever operation is outermost.\n\nIndependent source binding and original-frame reconstruction qualify every\nrecorded caller, preserving every filename/line alternative and empty/error\nallocation. Controlled public caller examples independently move inner and\nouter calls and verify their packages. Complete recorded-caller replacement in\nthe source model leaves both source selectors unchanged. The first parser\nwrapper draft and its source refusal also retain; the actual source cases use\nthe `parse_source` delegate. Read the complete fixed-seal qualification with:\n\n```sh\npython3 -B docs/audits/coordinate-observer-caller-checks-20261009/verify_callers.py\n```\n\nFull original-coordinate matching resumes after this observer qualification\ncommits. Whole hostile qualification and atomic current publication remain\nnext, with their existing owners. Opaque framework callers, original private\nformatting/toolchain/identity, address lifetimes and alias downstream remain\nseparately owned.\n'

def native(*args):
    run = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    if run.returncode or run.stderr:
        raise ValueError('complete fixed book source')
    return run.stdout


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def metrics(rows):
    return {'files': len(rows), 'bytes_total': sum(map(len, rows)),
            'lines_total': sum(raw.count(b'\n') for raw in rows)}


def main():
    destination = BASE / 'book.json'
    if destination.exists():
        raise ValueError('refuse to rewrite book publication')
    original = native('show', REVISION + ':' + str(CHAPTER))
    if CHAPTER.read_bytes() != original or original.count(OLD.encode()) != 1:
        raise ValueError('unique stable scoped book source')
    CHAPTER.write_bytes(original.replace(OLD.encode(), NEW.encode(), 1))
    paths = sorted(str(p) for p in Path('docs/book/src').glob('*.md'))
    source_paths = sorted(p for p in native('ls-tree', '-r', '--name-only', REVISION, '--', 'docs/book/src').decode().splitlines()
                          if Path(p).parent == Path('docs/book/src') and p.endswith('.md'))
    if paths != source_paths:
        raise ValueError('complete unchanged book membership')
    before_rows = [native('show', REVISION + ':' + p) for p in paths]
    after_rows = [Path(p).read_bytes() for p in paths]
    if [p for p,a,b in zip(paths,before_rows,after_rows) if a != b] != [str(CHAPTER)]:
        raise ValueError('only owned book guidance changes')
    before, after = metrics(before_rows), metrics(after_rows)
    owner = Path('docs/audits/coordinate-observer-caller-20261009/scope.txt').read_text().strip()
    records = list(map(json.loads, SURFACES.read_text().splitlines()))
    for record in records:
        if record.get('surface_id') == 'shipped_behavior':
            record['reference_contract']['aggregate_change'] = {
                'authority_id': 'COORDINATE-OBSERVER-CALLER-20261009', 'baseline': before,
                'delta': {k:after[k]-before[k] for k in before}, 'owner': owner,
                'rationale': 'Publish complete source-selected recorded observer caller qualification, retained first failures and independent public caller interventions; retain resumed full matching and opaque/private successors under unchanged Knowledge Map capacity authority.'}
    SURFACES.write_text(''.join(json.dumps(row, sort_keys=True) + '\n' for row in records))
    destination.write_text(json.dumps({'revision': REVISION, 'owner': owner,
        'source': str(CHAPTER), 'before': pin(original), 'after': pin(CHAPTER.read_bytes()),
        'original_block': OLD, 'current_block': NEW, 'book_before': before, 'book_after': after,
        'legs': {'rederive': 'Whole fixed-Git chapter membership and bytes measured before/after the unique scoped replacement.',
                 'falsify': 'verify_delivery.py independently reconstructs the reversible whole-book change, exact authority and complete actual native delivery receipts, with genuine controls.',
                 'durability': 'Fixed source revision, tracked exact blocks/identities/measurements and actual receipts; normal staged doctrines and Git hooks.'}}, sort_keys=True, indent=2) + '\n')
    print('PASS unique reversible whole-book change and exact aggregate authority; no Knowledge Map allowance changes.')


if __name__ == '__main__':
    main()
