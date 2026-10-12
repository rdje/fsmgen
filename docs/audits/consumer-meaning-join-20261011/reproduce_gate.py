"""Reproduce the exact immutable expected/actual bookkeeping refusal."""
import runpy
from join_common import *

if __name__ == '__main__':
    source = json.loads((BASE / 'formal-programmes-v2.json').read_bytes())['programmes']
    name = str(BASE / 'complete.py')
    need(Path(name).read_bytes() == source[name]['body'].encode(), 'whole immutable first corrected qualifier source')
    row = json.loads((BASE / 'controls-actual.json').read_bytes())
    need(type(row['expected_status']) is int and row['expected_status'] == 0
         and type(row['status']) is int and row['status'] == 1, 'independent distinct actual and declared failure roles')
    first = runpy.run_path(name, run_name='immutable_first_corrected_qualifier')
    first['gate']('controls', ['python3', '-B', str(BASE / 'controls.py')], 1, current=True)
    raise ValueError('first expected/actual bookkeeping unexpectedly accepted')
