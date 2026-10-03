import json
from collections import Counter
from pathlib import Path
B=Path('docs/audits/prepared-reservation-helper-causes-20261003')
data=json.loads((B/'causes.json').read_text())
print('Cause consumer bands:',Counter((r['band'],r['direct'],r['assertions'][1],r['primary_matched']) for r in data['rows']))
assert all(json.dumps(r['before'],sort_keys=True)==json.dumps(r['after'],sort_keys=True) for r in data['rows'])
print('Inputs: whole graph values/kinds unchanged.')
print('Unrelated matches:',sum(r['band']!='current_fixture' and r['assertions'][1] for r in data['rows']))
print('Safe earlier helper labels:',[r['label'] for r in data['rows'] if not r['direct'] and r['band']=='earlier_reference' and not r['assertions'][1]])
print('First unrelated native error:',next(r['error'].splitlines()[:2] for r in data['rows'] if r['band']=='earlier_reference'))
api=json.loads((B/'default-api.json').read_text())['rows'];print('Default actual API records:',len(api),Counter(r['accepted'] for r in api))
