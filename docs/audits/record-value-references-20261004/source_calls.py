"""Complete original reference call sequence, authored from source control flow."""
import json
import copy
import sys
from pathlib import Path

BASE = Path(__file__).parent

def scope_sources():
    sys.path.insert(0, 'docs/audits/record-value-scopes-20261004')
    from model import thaw
    from source_recipes import graph, recipes
    rows = []
    for recipe in recipes():
        if recipe['accepted']:
            items = thaw(recipe['arguments'])
            arguments = dict(zip(items[::2], items[1::2]))
            rows.append({'label': recipe['label'], 'scope': graph({**arguments['outer'], **arguments['local']})})
    roots = json.loads(Path('docs/audits/record-value-copy-fields-20261004/source-models.json').read_text())['roots']
    storage = thaw(next(row['scope'] for row in rows if row['label'] == 'storage-only'))
    storage['old'] = {'role': 'storage', 'type_spec': copy.deepcopy(roots['authored:frame'])}
    rows.append({'label': 'storage-only+old', 'scope': graph(storage)})
    storage['lanes'] = {'role': 'storage', 'type_spec': copy.deepcopy(roots['authored:lanes'])}
    rows.append({'label': 'storage-only+old+lanes', 'scope': graph(storage)})
    return rows

def calls():
    rows = []
    def add(token, access='read', whole=0, helper=None, context='control', line=77,
            package='main', path='./t/1986-isf-record-port-value-gates.t'):
        rows.append({'token': token, 'access': access, 'allow_whole': whole, 'helper': helper,
            'context': context, 'caller': [package, path, line]})
    def pair(source, target, helper=None):
        add(source, whole=1, helper=helper)
        add(target, 'write', 1, helper=helper)
    add('packet.data', context='first touch', line=55)
    pair('packet', 'held')
    pair('held', 'output')
    pair('packet', 'output')
    add('packet', whole=1)
    add('packet', whole=1)
    add('packet', 'write', 1, helper=1)
    add('packet.data', 'write', helper=2)
    add('output.data', 'write')
    for helper in range(3, 12):
        pair('packet', 'held', helper)
    for token in ('packet.body.count', 'packet.body.lanes[0]', 'packet.body.count', 'packet.body.count'):
        add(token)
    for helper, token in enumerate(('packet', 'packet.body', 'packet.body.lanes', 'packet.unknown',
            'packet.body.lanes[2]', 'packet.body.count[3]', 'packet..count'), 12):
        add(token, helper=helper)
    add('held.body', 'write', 1, helper=19)
    add('packet.data')
    add('packet.body.count', 'write')
    add('packet.data', helper=20)
    add('packet', 'write')
    add('packet.data', helper=21)
    add('packet[5:3]', 'write')
    add('packet[0]')
    add('packet', 'write', helper=22)
    add('mode.BUSY')
    add('shared.CONSTANT')
    pair('old', 'held')
    pair('scalar', 'scalar')
    pair('scalar', 'output', 23)
    add('output', 'write', 1, helper=24)
    add('lanes[1]')
    pair('lanes', 'output', 25)
    pair('packet', 'held')
    add('packet', whole=2, helper=39, context='permission', line=274)
    add('packet', whole=1)
    add('held', 'write', 1, helper=40)
    add('value.flag', 'write', 1, helper=41, context="transaction 'main' set target", line=255,
        package='FSM::Support::ISFRecordPortContexts', path='perl/FSM/Support/ISFRecordPortContexts.pm')
    assert len(rows) == 68
    return rows

if __name__ == '__main__':
    (BASE / 'source-calls.json').write_text(json.dumps(calls(), sort_keys=True, indent=2) + '\n')
    print('PASS source-only sixty-eight complete ordered reference call/access/whole/context/helper/caller recipes. No native argument or product is read.')
