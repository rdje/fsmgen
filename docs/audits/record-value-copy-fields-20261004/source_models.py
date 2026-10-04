"""Source-declared candidates and public virtual carriers, never native inference."""
import copy
import json
from pathlib import Path

BASE = Path(__file__).parent
authored = json.loads(Path('docs/audits/record-value-fields-20261004/authored-models.json').read_text())
models = {'authored:' + name: copy.deepcopy(spec) for name, spec in authored['types'].items()}
models['imported:shared.frame'] = copy.deepcopy(authored['imported']['shared.frame'])
models['source:scalar'] = copy.deepcopy(authored['scalar'])
models['source:first-touch-frame'] = copy.deepcopy(authored['types']['frame'])
models['source:refused-output-frame'] = {'kind': 'record', 'width': 1, 'signed': 0,
    'member_order': ['flag'], 'members': {'flag': {'kind': 'bit', 'width': 1, 'signed': 0}}}
swapped = copy.deepcopy(authored['types']['nested'])
swapped['members']['body']['members']['lanes']['items'].reverse()
models['source:swapped-nested-list'] = swapped

frame = authored['types']['frame']
def candidate(name):
    value = copy.deepcopy(frame)
    models['malformed:' + name] = value
    return value

candidate('unknown key')['extra'] = 1
candidate('bad root width')['width'] = 9
candidate('bad scalar signed')['members']['data']['signed'] = 2
del candidate('missing signed')['members']['data']['signed']
candidate('aggregate signed')['signed'] = 1
candidate('aggregate state')['state_model'] = 'two_state'
candidate('bad state')['members']['data']['state_model'] = 'unknown'
candidate('duplicate order')['member_order'] = ['flag', 'flag']
candidate('unlisted member')['members']['extra'] = copy.deepcopy(authored['scalar'])
candidate('cyclic member')['members']['data'] = {'$reference': '.'}
candidate('deferred kind')['kind'] = 'deferred_imported_alias'

# Scalar index/slice products have the published unsigned bit/bits carrier
# contract. These are generated path facts, not new authored declarations.
models['generated:scalar-index'] = {'kind': 'bit', 'width': 1, 'signed': 0}
models['generated:scalar-slice'] = {'kind': 'bits', 'width': 3, 'signed': 0}

def nodes(value, path=''):
    result = []
    if isinstance(value, dict):
        if 'kind' in value and 'width' in value:
            result.append((path, value))
        for key, child in value.items():
            result.extend(nodes(child, path + '/' + key))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            result.extend(nodes(child, path + '/' + str(index)))
    return result

submodels = {}
for name, spec in list(models.items()):
    for path, node in nodes(spec):
        submodels[name + ':' + path] = copy.deepcopy(node)
for name, spec in list(submodels.items()):
    if '$reference' in json.dumps(spec):
        continue
    submodels['wrapper:' + name] = {'kind': 'record', 'width': spec['width'], 'signed': 0,
        'member_order': ['value'], 'members': {'value': copy.deepcopy(spec)}}

(BASE / 'source-models.json').write_text(json.dumps({'roots': models, 'nodes': submodels,
    'authority': 'Complete source-declared fixtures/mutations plus public scalar index/slice '
        'and one-member validation/traversal wrapper contracts. Expected shapes are built '
        'without native stream inspection. Width/signed stage spellings must remain raw in '
        'actual graphs; these source shapes do not authorize final product or caller-kind coercion.'},
    sort_keys=True, indent=2) + '\n')
print('PASS complete source-declared candidate/public virtual carrier models built; '
    'all-copy source/stage role reader remains required.')
