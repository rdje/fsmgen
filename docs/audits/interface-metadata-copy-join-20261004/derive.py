"""Whole original/current member correspondence producer; separate reader required."""
import json
from pathlib import Path
BASE = Path(__file__).parent
old = json.loads(Path('docs/audits/interface-metadata-copy-controls-20261004/ordinary.json').read_text())
current = json.loads(Path('docs/audits/interface-metadata-copy-repair-20261004/ordinary.json').read_text())
originals = []
cursor = 0
for index, row in enumerate(old['copies']):
    if row['kind'] == 'test' and row['caller'][2] in (41, 116):
        originals.append({'original': index, 'current': None, 'role': 'typed readonly snapshot replaces lossy baseline', 'source_line': row['caller'][2]})
        continue
    while current['copies'][cursor]['kind'] == 'cycle': cursor += 1
    originals.append({'original': index, 'current': cursor, 'role': 'strong test fixture copy' if row['kind'] == 'test' else 'private detached numeric validation copy', 'source_line': row['caller'][2]})
    cursor += 1
cycles = [i for i, r in enumerate(current['copies']) if r['kind'] == 'cycle']

def fields(node, path='', found=None):
    found = [] if found is None else found
    if not isinstance(node, list):
        found.append((path, type(node).__name__, node)); return found
    kind, body = node
    if kind == 'reference': return found
    for key, value in sorted(body.items()) if kind == 'hash' else enumerate(body):
        escaped = str(key).replace('~', '~0').replace('/', '~1')
        fields(value, path + '/' + escaped, found)
    return found
widths = []
for index, copied in enumerate(current['copies']):
    before, after = fields(copied['before']), fields(copied['copy'])
    assert [r[0] for r in before] == [r[0] for r in after]
    for a, b in zip(before, after):
        if a != b:
            widths.append({'copy': index, 'api': copied['api'], 'path': a[0], 'before_kind': a[1], 'before_value': a[2], 'after_kind': b[1], 'after_value': b[2]})
original_fields = json.loads(Path('docs/audits/interface-metadata-fields-20261004/fields.json').read_text())['rows']
api = [{'original': i, 'current': i, 'role': r['kind'], 'accepted': r['accepted'], 'helper': r['helper']} for i,r in enumerate(old['api'])]
consumer = []
for i,row in enumerate(current['consumers']):
    copy_check = any(row['label'].endswith(s) for s in ('copy preserves original kinds and sharing', 'copy preserves kinds and sharing', 'copy preserves reference population', 'copy is isolated from source'))
    consumer.append({'current':i,'label':row['label'],'role':'strong copy check' if copy_check else 'qualified original consumer','kind':row['kind'],'helper':row['helper']})
(BASE/'join.json').write_text(json.dumps({'copies':originals,'cycle_copies':cycles,'original_fields':original_fields,'current_private_fields':widths,'api':api,'consumers':consumer},indent=2,sort_keys=True)+'\n')
