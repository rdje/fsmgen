"""Source-only full root recipes; no native API/copy/result input is read."""
import json
from pathlib import Path

BASE = Path(__file__).parent
ROOTS = json.loads(Path('docs/audits/record-value-copy-fields-20261004/source-models.json').read_text())['roots']

def hydrate(value, root=None):
    if isinstance(value, dict):
        if value == {'$reference': '.'}:
            assert root is not None
            return root
        result = {}
        root = result if root is None else root
        for key, child in value.items():
            result[key] = hydrate(child, root)
        return result
    if isinstance(value, list):
        return [hydrate(child, root) for child in value]
    return value

def graph(value, seen=None, path=''):
    if not isinstance(value, (dict, list)):
        return value
    seen = {} if seen is None else seen
    if id(value) in seen:
        return ['reference', seen[id(value)]]
    seen[id(value)] = path
    if isinstance(value, dict):
        return ['hash', {key: graph(value[key], seen, path + '/' + key.replace('~', '~0').replace('/', '~1')) for key in sorted(value)}]
    return ['array', [graph(child, seen, path + '/' + str(i)) for i, child in enumerate(value)]]

def recipes():
    pool = {name: hydrate(value) for name, value in ROOTS.items()}
    def spec(name):
        return pool[name if ':' in name else 'authored:' + name]
    def binding(role, kind):
        return {'role': role, 'type_spec': spec(kind) if kind is not None else None}
    def outer(source, target):
        return {'packet': binding('input', source), 'held': binding('storage', target),
            'output': binding('output', target), 'scalar': binding('output', 'source:scalar')}
    rows = []
    def add(label, roots, local=None, accepted=True, line=68, helper=None, package='main', path='./t/1986-isf-record-port-value-gates.t', extra=None):
        arguments = ['outer', roots, 'local', local or {}]
        if extra:
            arguments += extra
        rows.append({'label': label, 'arguments': graph(arguments), 'accepted': int(accepted),
            'caller': [package, path, line], 'helper': helper})
    add('first-touch', {'packet': binding('input', 'source:first-touch-frame')}, line=51)
    add('resolved-alias', outer('frame', 'alias'))
    for name in ('renamed', 'reordered', 'signed_data', 'four', 'two', 'bit_kind'):
        add('identity:' + name, outer('frame', name))
    add('explicit-state', outer('four', 'two'))
    add('nested-flat', outer('nested', 'flat'))
    add('nested-list-order', outer('nested', 'source:swapped-nested-list'))
    add('nested-paths', outer('nested', 'nested'))
    add('local-unresolved', outer('frame', 'frame'), {'packet': binding('local', None)})
    add('formal-output', outer('frame', 'frame'), {'packet': binding('output', 'nested')})
    add('local-scalar', outer('frame', 'frame'), {'packet': binding('local', 'source:scalar')})
    add('input-unresolved', outer('frame', 'frame'), {'packet': binding('input', None)})
    add('storage-only', outer('frame', 'signed_data'))
    add('imported-local', outer('imported:shared.frame', 'frame'))
    for name in ('unknown key', 'bad root width', 'bad scalar signed', 'missing signed',
            'aggregate signed', 'aggregate state', 'bad state', 'duplicate order',
            'unlisted member', 'cyclic member', 'deferred kind'):
        add('malformed:' + name, outer('malformed:' + name, 'frame'), accepted=False, helper=26 + len(rows) - 18)
    add('unknown-role', {'packet': binding('inout', 'frame')}, accepted=False, line=270, helper=37)
    add('unknown-scope-key', {}, accepted=False, line=271, helper=38, extra=['surprise', 1])
    add('closed-control', outer('frame', 'frame'))
    refused = {'done': {'role': 'output', 'type_spec': {'kind': 'bits', 'width': 1, 'signed': 0}},
        'value': binding('output', 'source:refused-output-frame')}
    for i, line in enumerate((32, 32, 32, 60, 32, 32, 60)):
        add('refused-output-projection:' + str(i), refused, line=line, helper=41,
            package='FSM::Support::ISFRecordPortScopes', path='perl/FSM/Support/ISFRecordPortScopes.pm')
    add('refused-output-samples', refused, line=32, helper=41,
        package='FSM::Support::ISFRecordPortContexts', path='perl/FSM/Support/ISFRecordPortContexts.pm')
    assert len(rows) == 40 and sum(row['accepted'] for row in rows) == 27
    return rows

if __name__ == '__main__':
    (BASE / 'source-recipes.json').write_text(json.dumps(recipes(), sort_keys=True, indent=2) + '\n')
    print('PASS source-only forty complete ordered root/role/type/mask/extra/caller recipes; twenty-seven intended preparations and thirteen refusals. No native product is read.')
