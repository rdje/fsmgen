"""Reproduce the complete proposed current input and its genuine controls."""
from pathlib import Path

path = Path('docs/audits/record-value-tooling-current-reader-20261006/verify.py')
ns = {'__name__': 'tooling_preflight', '__file__': str(path)}
exec(compile(path.read_bytes(), str(path), 'exec'), ns)
record = ns['current_input']()
record['cards'] = ns['expected_cards']()
record['chapter'] = ns['transform_chapter'](ns['git'](ns['CHAPTER']).decode())
ns['check_current'](record)
controls = ns['controls'](record)
print('PASS complete proposed current source and genuine controls:', len(controls['companion']), len(controls['observer']))
