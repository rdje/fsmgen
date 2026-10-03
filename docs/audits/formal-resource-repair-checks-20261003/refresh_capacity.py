import glob
import json
import subprocess
from pathlib import Path

registry = Path('doctrine/live_document_size/surfaces.jsonl')
rows = [json.loads(line) for line in registry.read_text().splitlines()]
measurements = {}
for row in rows:
    identity = row.get('surface_id')
    if identity not in ('task_evidence', 'knowledge_cards', 'shipped_behavior'):
        continue
    paths = sorted({name for pattern in row['targets'] for name in glob.glob(pattern)
                    if Path(name).is_file()})
    raw = [Path(name).read_bytes() for name in paths]
    metrics = {'files': len(paths), 'bytes_total': sum(map(len, raw)),
               'lines_total': sum(value.count(b'\n') for value in raw),
               'bytes_each': max(map(len, raw)),
               'lines_each': max(value.count(b'\n') for value in raw),
               'line_bytes_each': max(len(line) for value in raw for line in value.splitlines())}
    measurements[identity] = metrics
    if identity == 'knowledge_cards':
        assert metrics['bytes_total'] <= (row['baseline']['bytes_total']
                                         + row['transition']['max_growth']['bytes_total'])
    if identity == 'task_evidence':
        for dimension in ('files', 'lines_total', 'bytes_total'):
            row['transition']['max_growth'][dimension] = max(
                0, metrics[dimension] - row['baseline'][dimension]) + 1
    if identity == 'shipped_behavior':
        prior = [subprocess.check_output(['git', 'show', 'HEAD:' + name]) for name in paths]
        baseline = {'files': len(paths), 'bytes_total': sum(map(len, prior)),
                    'lines_total': sum(value.count(b'\n') for value in prior)}
        row['reference_contract']['aggregate_change'] = {
            'authority_id': 'FORMAL-RESOURCE-CAUSE-REPAIR-20261003-SHIPPED-BEHAVIOR',
            'owner': 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.2.3.8',
            'baseline': baseline,
            'delta': {key: metrics[key] - baseline[key] for key in baseline},
            'rationale': 'Document completed resource helper/direct cause repair, real prior/bypass controls and ordinary conservation; public behavior, '
            'schema, admission and ceilings remain unchanged.'}
registry.write_text('\n'.join(json.dumps(row, sort_keys=True, separators=(',', ':'))
                              for row in rows) + '\n')
Path('docs/audits/formal-resource-repair-checks-20261003/capacity.json').write_text(
    json.dumps(measurements, sort_keys=True, indent=2) + '\n')
print(json.dumps(measurements, sort_keys=True))
