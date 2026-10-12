"""Development-only reader composition; no formal join or parent acceptance."""
from join_common import *
import child_readers

if __name__ == '__main__':
    results = {}
    for role in child_readers.ROLES:
        admitted = child_readers.admit(role)
        candidate = admitted['candidate']
        counts = [sum(row['meaning'] is not None for row in mode['consumers']) for mode in candidate['modes']]
        results[role] = dict(modes=[mode['mode'] for mode in candidate['modes']], meanings_per_mode=counts,
                             qualification=pin(canonical(admitted['qualification'])), source=pin(canonical(admitted['custody'])))
    save('development-interface.json', dict(owner=PLAN['owner'], results=results,
         condition='Development-only committed child-reader interface composition; formal source/meaning/operand/truth join and all acceptance remain open.'))
    print('PASS development-only isolated committed helper/remaining reader interfaces; no formal acceptance.')
