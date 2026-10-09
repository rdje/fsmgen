"""Publish scoped book guidance and measure its complete aggregate authority."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/coordinate-expression-fact-checks-20261009')
REVISION = '6b3783bb03f5f0d65619dddbba31ea4fda3d0890'
CHAPTER = Path('docs/book/src/90-reference-map.md')
SURFACES = Path('doctrine/live_document_size/surfaces.jsonl')
OLD = 'Mandatory non-growing canonical causal-fact admission is next, before complete\noriginal matching resumes. Whole hostile qualification, alias capture and\ndownstream, external framework, private formatting/toolchain and address\nmeanings retain their separate owners.\n'
NEW = 'Canonical expression-attribution facts and the public probe now live in the\ntooling card `docs/knowledge/mdbook-build-destination-locality.md`.\nIts current reader consumes the sealed expression qualification. Exact prior\ncard bytes remain retrievable, with every prior question/probe preserved\nthrough non-growing semantic compaction under unchanged collection limits.\nComplete original matching is next. Whole hostile qualification, alias capture\nand downstream, external framework, private formatting/toolchain and address\nmeanings retain their separate owners.\n'

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
    owner = Path('docs/audits/coordinate-expression-fact-20261009/scope.txt').read_text().strip()
    records = list(map(json.loads, SURFACES.read_text().splitlines()))
    for record in records:
        if record.get('surface_id') == 'shipped_behavior':
            record['reference_contract']['aggregate_change'] = {
                'authority_id': 'COORDINATE-EXPRESSION-FACT-20261009', 'baseline': before,
                'delta': {k:after[k]-before[k] for k in before}, 'owner': owner,
                'rationale': 'Publish canonical expression-attribution fact and probe through exact-source semantic compaction, with all prior meanings/questions/probes, empty original selections and unchanged Knowledge Map capacity authority.'}
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
