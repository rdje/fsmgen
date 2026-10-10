"""Refuse a prospective canonical working-set increase before live writes."""
import json
import runpy
import subprocess
import sys

m = runpy.run_path(sys.argv[1])
rows = {}
for path in m['PATHS']:
    raw = subprocess.check_output(['git', '--no-replace-objects', 'show', m['REVISION'] + ':' + path])
    new = m['proposal'](path, raw)
    rows[path] = {'before_bytes': len(raw), 'after_bytes': len(new), 'before_lines': raw.count(b'\n'), 'after_lines': new.count(b'\n')}
print(json.dumps(rows, sort_keys=True), flush=True)
for dimension in ('bytes', 'lines'):
    if sum(r['after_' + dimension] for r in rows.values()) > sum(r['before_' + dimension] for r in rows.values()):
        raise ValueError('non-growing complete proposed card ' + dimension)
print('PASS prospective complete card working set does not grow.')
