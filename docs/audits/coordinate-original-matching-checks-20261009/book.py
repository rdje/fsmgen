"""Publish scoped book guidance and measure its complete aggregate authority."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/coordinate-original-matching-checks-20261009')
REVISION = '39249cb445399c2318275829e5c7f10e0094d0c4'
CHAPTER = Path('docs/book/src/90-reference-map.md')
SURFACES = Path('doctrine/live_document_size/surfaces.jsonl')
OLD = 'Intake leaves every coordinate selection empty. Applying the independently\ndeclared statement alternatives to original callers is the next owned slice.\nThe alias capture remains in custody with its downstream meanings separately\nowned. External framework, private formatting/toolchain and address meanings\nremain unmeasured.\n'
NEW = 'Intake preserves every original coordinate without selecting its meaning.\nThe first complete match rejects the first/closing-only source alternatives:\nsome helper calls and guards report interior expression lines. A complete\ncensus retains every observation and mismatch, the first failed matcher and\nits separately marked unexecuted verifier draft. No original alternative has\nbeen widened.\n\nFinite public caller and compiler fixtures reproduce callback/pattern and\nlive-operand guard attribution. Moving the relevant expression changes its\nreported line; moving a later constant message does not. Constant-only guard\nprobes remain as counterexamples. The first ambiguous fixture selector and\nits corrected producer both retain. These are finite current public results;\noriginal private formatter/toolchain meanings remain unmeasured.\n\n```sh\npython3 -B docs/audits/coordinate-original-matching-checks-20261009/verify_diagnosis.py\n```\n\nThe next owned slice qualifies superseding source-derived alternatives before\ncomplete original matching resumes. Whole hostile qualification, alias\ncapture/downstream, external framework, private formatting/toolchain and\naddress meanings retain their separate owners.\n'


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
    owner = Path('docs/audits/coordinate-original-mismatch-20261009/scope.txt').read_text().strip()
    records = list(map(json.loads, SURFACES.read_text().splitlines()))
    for record in records:
        if record.get('surface_id') == 'shipped_behavior':
            record['reference_contract']['aggregate_change'] = {
                'authority_id': 'COORDINATE-ORIGINAL-MISMATCH-20261009', 'baseline': before,
                'delta': {k:after[k]-before[k] for k in before}, 'owner': owner,
                'rationale': 'Publish complete original-coordinate mismatch diagnosis and finite public caller/compiler controls; qualify superseding recipes next and conserve all original opaque scope and capacity authority.'}
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
