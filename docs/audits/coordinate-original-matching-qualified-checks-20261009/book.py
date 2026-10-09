"""Publish scoped book guidance and measure its complete aggregate authority."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/coordinate-original-matching-qualified-checks-20261009')
REVISION = 'c8fe740b93f6be988d74729d0baf4b11fabda96a'
CHAPTER = Path('docs/book/src/90-reference-map.md')
SURFACES = Path('doctrine/live_document_size/surfaces.jsonl')
OLD = 'Full original-coordinate matching resumes after this observer qualification\ncommits. Whole hostile qualification and atomic current publication remain\nnext, with their existing owners. Opaque framework callers, original private\nformatting/toolchain/identity, address lifetimes and alias downstream remain\nseparately owned.\n'
NEW = 'Complete dated original own-coordinate matching now joins every error origin,\nown caller/eval and lexical-load position to the independently declared source\ncandidates. Operation-specific observer snapshots join the same matched phase.\nA separate sequential walker checks the complete original frame intervals,\nincluding every explicitly opaque framework frame.\n\nEach selection retains its reported filename/line, all source alternatives and\nevery matching label. Labels that share a line remain equivalent possibilities.\nFor example, this original guard call matches both source labels at line107,\nwhile the distinct statement-closing alternative remains available:\n\n```json\n{\n  "recipe_id": "admitted/guard-call/value/GUARDS.values.16",\n  "reported_filename": "perl/FSM/Support/ISFRecordPortValues.pm",\n  "reported_line": 107,\n  "matching_line_labels": ["first", "predicate_expression_closing"],\n  "all_line_alternatives": {"closing": 108, "first": 107, "predicate_expression_closing": 107}\n}\n```\n\nRead the complete fixed-seal matching qualification with:\n\n```sh\npython3 -B docs/audits/coordinate-original-matching-qualified-checks-20261009/verify_matching.py\n```\n\nThe product retains complete original error/argument/context bytes, empty\nallocations, full used and unused source candidates and explicit opaque owners.\nFresh original-intake, expression and observer readers independently regenerate\ncomplete results. This dated own-coordinate match does not measure original\nprivate formatting/toolchain/identity or external framework coordinate rules.\nWhole hostile qualification and atomic current canonical publication remain\nnext. Address lifetimes and alias downstream remain separately owned.\n'

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
    owner = Path('docs/audits/coordinate-original-matching-qualified-20261009/scope.txt').read_text().strip()
    records = list(map(json.loads, SURFACES.read_text().splitlines()))
    for record in records:
        if record.get('surface_id') == 'shipped_behavior':
            record['reference_contract']['aggregate_change'] = {
                'authority_id': 'COORDINATE-ORIGINAL-MATCHING-QUALIFIED-20261009', 'baseline': before,
                'delta': {k:after[k]-before[k] for k in before}, 'owner': owner,
                'rationale': 'Publish complete dated original own-coordinate matching, all equivalent alternatives, independent sequential traversal and unchanged original/source/observer readers; retain whole hostile qualification, current canonical publication and opaque/private successors under unchanged Knowledge Map capacity authority.'}
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
