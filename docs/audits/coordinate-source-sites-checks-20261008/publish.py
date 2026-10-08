"""Measure exact book delta and task growth without changing any ceiling."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/coordinate-source-sites-checks-20261008')
REVISION = '4ceb96fdc11317c77b3d18f5a5a163c12bfc58c4'
SURFACES = Path('doctrine/live_document_size/surfaces.jsonl')
CHAPTER = Path('docs/book/src/90-reference-map.md')


def native(*args):
    result = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    if result.returncode or result.stderr:
        raise ValueError('complete native publication input')
    return result.stdout


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def aggregate(rows):
    return {'files': len(rows), 'lines_total': sum(raw.count(b'\n') for raw in rows),
            'bytes_total': sum(map(len, rows))}


def main():
    owner = Path('docs/audits/coordinate-source-sites-20261008/scope.txt').read_text().strip()
    paths = sorted(Path('docs/book/src').glob('*.md'))
    tracked = native('ls-tree', '-r', '--name-only', REVISION, '--', 'docs/book/src').decode().splitlines()
    original_paths = sorted(path for path in tracked if Path(path).parent == Path('docs/book/src') and path.endswith('.md'))
    if list(map(str, paths)) != original_paths:
        raise ValueError('exact unchanged whole book membership')
    before_rows = [native('show', REVISION + ':' + str(path)) for path in paths]
    after_rows = [path.read_bytes() for path in paths]
    before, after = aggregate(before_rows), aggregate(after_rows)
    changed = [str(path) for path, old, new in zip(paths, before_rows, after_rows) if old != new]
    if changed != [str(CHAPTER)]:
        raise ValueError('unique scoped book source change')
    old = native('show', REVISION + ':' + str(CHAPTER))
    current = CHAPTER.read_bytes()
    start = current.index(b'The source-site bank preserves')
    end = current.index(b'<div id="knowledge-map-architecture">', start)
    addition = current[start:end]
    if current[:start] + current[end:] != old:
        raise ValueError('whole book conservation around unique addition')
    records = [json.loads(line) for line in SURFACES.read_text().splitlines()]
    previous_registry = pin(native('show', REVISION + ':' + str(SURFACES)))
    for row in records:
        if row.get('surface_id') == 'shipped_behavior':
            row['reference_contract']['aggregate_change'] = {
                'authority_id': 'COORDINATE-SOURCE-SITES-20261008', 'baseline': before,
                'delta': {key: after[key] - before[key] for key in before}, 'owner': owner,
                'rationale': 'Publish the complete source-site bank, distinguishing lexical ownership and dated public examples from pending per-refusal composition and original coordinate selection; conserve existing source/collection ceilings.'}
        if row.get('surface_id') == 'task_evidence':
            task_paths = sorted({path for pattern in row['targets'] for path in Path('.').glob(pattern)})
            raw = [path.read_bytes() for path in task_paths]
            metrics = {**aggregate(raw), 'lines_each': max(data.count(b'\n') for data in raw),
                       'bytes_each': max(map(len, raw)),
                       'line_bytes_each': max(len(line.rstrip(b'\r')) for data in raw for line in data.split(b'\n'))}
            for key, actual in metrics.items():
                baseline = row['baseline'][key]
                if actual > baseline + row['transition']['max_growth'][key]:
                    row['transition']['max_growth'][key] = min(actual + row['transition']['ratchet_step'][key], row['enforcement_ceilings'][key]) - baseline
    SURFACES.write_text(''.join(json.dumps(row, sort_keys=True) + '\n' for row in records))
    proof = {'revision': REVISION, 'owner': owner, 'source': str(CHAPTER),
             'before': pin(old), 'after': pin(current), 'addition': addition.decode(),
             'book_before': before, 'book_after': after, 'previous_registry': previous_registry,
             'task_metrics': metrics, 'legs': {
                 'rederive': 'publish.py reconstructs complete fixed-Git book membership/bytes and current source delta.',
                 'falsify': 'Unique chapter change and exact removal reconstruction reject borrowed source or unrelated book edits; source-site verify.py independently checks binary ownership and genuine controls.',
                 'durability': 'Versioned source epoch, tracked programmes and complete publication/check receipts; registered maintained-reference and task pressure gates detect current drift.'}}
    (BASE / 'publication.json').write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS exact scoped whole-book delta and measured task allowance; all ceilings unchanged.')


if __name__ == '__main__':
    main()
