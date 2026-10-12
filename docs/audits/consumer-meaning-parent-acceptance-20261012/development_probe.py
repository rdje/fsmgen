"""Non-acceptance probe of complete committed meaning interfaces and native kinds."""
from acceptance_common import *
import meaning_readers

if __name__ == '__main__':
    results = {role: meaning_readers.admit(role) for role in meaning_readers.ROLES}
    counts = {}
    for role, result in results.items():
        modes = result['candidate']['modes']
        counts[role] = [(row['mode'], sum(value['meaning'] is not None for value in row['consumers'])) for row in modes]
        need(len(modes) == 3 and all(len(row['consumers']) == 125 for row in modes),
             'development-only whole reader interface population')
    join = results['join']['candidate']
    width = join['modes'][1]['consumers'][16]['native']['expected'][1]['storage'][1][0][1]['signals'][1][0][1]['type_spec'][1]['members'][1]['data'][1]['width']
    need(type(width) is str and width == '7', 'development-only actual original Storable copy kind')
    save('development-interface.json', dict(owner=PLAN['owner'], counts=counts,
        source={role: pin(canonical(result['custody'])) for role, result in results.items()},
        qualification={role: pin(canonical(result['qualification'])) for role, result in results.items()},
        storable_expected_width=dict(value=width, primitive='string'),
        condition='Development-only isolated interface/kind probe. No parent contract, complete controls, formal acceptance or higher closure inferred.'))
    print('PASS development-only complete committed helper/remaining/join interfaces and original Storable kind; no formal acceptance.')
