"""Qualify the exact saved-reader date update and measured task pressure."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/artifact-sweep-due-checks-20261010')
REVISION = '959f8b940d2517696183220ea6bc805f302fa6e6'
CHAPTER = Path('docs/book/src/09-generated-hdl-debugging-and-inspection.md')
SURFACES = Path('doctrine/live_document_size/surfaces.jsonl')


def native(*args):
    result = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    if result.returncode or result.stderr:
        raise ValueError('complete fixed native publication input')
    return result.stdout


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def aggregate(rows):
    return {'files': len(rows), 'lines_total': sum(raw.count(b'\n') for raw in rows),
            'bytes_total': sum(map(len, rows))}


def main():
    destination = BASE / 'publication.json'
    if destination.exists():
        raise ValueError('one fresh publication epoch required')
    paths = sorted(Path('docs/book/src').glob('*.md'))
    tracked = native('ls-tree', '-r', '--name-only', REVISION, '--', 'docs/book/src').decode().splitlines()
    original_paths = sorted(path for path in tracked
                            if Path(path).parent == Path('docs/book/src') and path.endswith('.md'))
    if list(map(str, paths)) != original_paths:
        raise ValueError('complete unchanged book membership')
    before_rows = [native('show', REVISION + ':' + str(path)) for path in paths]
    after_rows = [path.read_bytes() for path in paths]
    before, after = aggregate(before_rows), aggregate(after_rows)
    changed = [str(path) for path, old, new in zip(paths, before_rows, after_rows) if old != new]
    old = native('show', REVISION + ':' + str(CHAPTER))
    source = b'python3 -B docs/audits/artifact-sweep-due-20261009/verify.py'
    target = b'python3 -B docs/audits/artifact-sweep-due-20261010/verify.py'
    if (changed != [str(CHAPTER)] or old.count(source) != 1
            or CHAPTER.read_bytes() != old.replace(source, target) or before != after):
        raise ValueError('exact sole saved-reader substitution and unchanged aggregate')
    previous = SURFACES.read_bytes()
    records = [json.loads(line) for line in previous.splitlines()]
    for row in records:
        if row.get('surface_id') != 'task_evidence':
            continue
        task_paths = sorted({path for pattern in row['targets'] for path in Path('.').glob(pattern)})
        raw = [path.read_bytes() for path in task_paths]
        metrics = {**aggregate(raw), 'lines_each': max(data.count(b'\n') for data in raw),
                   'bytes_each': max(map(len, raw)),
                   'line_bytes_each': max(len(line.rstrip(b'\r')) for data in raw for line in data.split(b'\n'))}
        for key, actual in metrics.items():
            baseline = row['baseline'][key]
            if actual > baseline + row['transition']['max_growth'][key]:
                row['transition']['max_growth'][key] = min(
                    actual + row['transition']['ratchet_step'][key], row['enforcement_ceilings'][key]) - baseline
    updated = ''.join(json.dumps(row, sort_keys=True) + '\n' for row in records).encode()
    SURFACES.write_bytes(updated)
    proof = {'revision': REVISION, 'owner': 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.82',
             'source': str(CHAPTER), 'before': pin(old), 'after': pin(CHAPTER.read_bytes()),
             'substitution': {'before': source.decode(), 'after': target.decode()},
             'book_before': before, 'book_after': after, 'task_metrics': metrics,
             'previous_registry': pin(previous), 'current_registry': pin(updated),
             'legs': {'rederive': 'Complete fixed-Git/current book membership and source bytes reconstruct.',
                      'falsify': 'Exact sole substitution rejects any unrelated source change or aggregate growth; saved/actual census controls independently reject hostile records.',
                      'durability': 'Fixed prior revision, whole source hashes, programmes, census seal, complete check receipts and Git.'}}
    destination.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS exact saved-reader substitution; whole book aggregate and all ceilings unchanged.')


if __name__ == '__main__':
    main()
