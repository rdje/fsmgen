"""Measure current task evidence; retain all nodes and every existing ceiling."""
import json
from pathlib import Path

BASE = Path('docs/audits/address-source-boundaries-20261010')
SURFACES = Path('doctrine/live_document_size/surfaces.jsonl')


def main():
    records = list(map(json.loads, SURFACES.read_text().splitlines()))
    row = next(r for r in records if r.get('surface_id') == 'task_evidence')
    if row['state'] == 'rollover_debt':
        raise ValueError('task rollover requires its governed transition')
    paths = sorted({p for pattern in row['targets'] for p in Path('.').glob(pattern)})
    raw = [p.read_bytes() for p in paths]
    actual = {'files': len(paths), 'bytes_total': sum(map(len, raw)),
              'lines_total': sum(r.count(b'\n') for r in raw),
              'bytes_each': max(map(len, raw)), 'lines_each': max(r.count(b'\n') for r in raw),
              'line_bytes_each': max(len(line.rstrip(b'\r')) for r in raw for line in r.split(b'\n'))}
    for key, measured in actual.items():
        if measured > row['enforcement_ceilings'][key]:
            raise ValueError('unchanged task ceiling: ' + key)
        wanted = max(0, min(measured + row['transition']['ratchet_step'][key],
                            row['enforcement_ceilings'][key]) - row['baseline'][key])
        row['transition']['max_growth'][key] = wanted
    SURFACES.write_text(''.join(json.dumps(r, sort_keys=True) + '\n' for r in records))
    (BASE / 'task-metrics.json').write_text(json.dumps({'actual': actual,
        'owner': (BASE / 'scope.txt').read_text().strip(),
        'scope': 'Complete unchanged task collection membership; only measured owned task allowance, never a baseline or ceiling increase.'}, sort_keys=True, indent=2) + '\n')
    print('PASS exact complete task measurements and owned allowance; all ceilings and Knowledge Map authority unchanged.')


if __name__ == '__main__':
    main()
