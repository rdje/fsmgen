"""Publish scoped book guidance and measure its complete aggregate authority."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/coordinate-expression-alternative-checks-20261009')
REVISION = 'a3efbe6489451f76cdb3fda343adb6aa556f2dc7'
CHAPTER = Path('docs/book/src/90-reference-map.md')
SURFACES = Path('doctrine/live_document_size/surfaces.jsonl')
OLD = 'The next owned slice qualifies superseding source-derived alternatives before\ncomplete original matching resumes. Whole hostile qualification, alias\ncapture/downstream, external framework, private formatting/toolchain and\naddress meanings retain their separate owners.\n'
NEW = "Source-only superseding candidates now retain every prior statement, label,\nfilename and source identity, adding exact predicate-expression endings and\nhelper-pattern starts. Their literal UTF8 spans are independently reconstructed\nfrom the complete original own source. `predicate_expression_closing` names\nthe final byte of a guard predicate; `pattern_expression_first` names the first\nbyte of a helper's pattern argument. The original statement first/closing\nlabels remain available, including equivalent labels on the same line.\n\nThe independent reader replays finite public caller/compiler examples and\nunchanged source-only prerequisites. These are conditional candidates, with\nno universal line-formatting prediction and every original selection empty:\n\n```sh\npython3 -B docs/audits/coordinate-expression-alternative-checks-20261009/verify_alternatives.py\n```\n\nMandatory non-growing canonical causal-fact admission is next, before complete\noriginal matching resumes. Whole hostile qualification, alias capture and\ndownstream, external framework, private formatting/toolchain and address\nmeanings retain their separate owners.\n"


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
    owner = Path('docs/audits/coordinate-expression-alternatives-20261009/scope.txt').read_text().strip()
    records = list(map(json.loads, SURFACES.read_text().splitlines()))
    for record in records:
        if record.get('surface_id') == 'shipped_behavior':
            record['reference_contract']['aggregate_change'] = {
                'authority_id': 'COORDINATE-EXPRESSION-ALTERNATIVES-20261009', 'baseline': before,
                'delta': {k:after[k]-before[k] for k in before}, 'owner': owner,
                'rationale': 'Publish complete source-only expression alternatives and finite public/compiler qualification; retain mandatory canonical admission, empty original selections, opaque successor scopes and unchanged capacity authority.'}
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
