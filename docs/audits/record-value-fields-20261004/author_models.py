"""Independent authored layouts; never derive expectations from native products."""
import copy
import json
from pathlib import Path

BASE = Path(__file__).parent

def scalar(kind, width, signed=0, state=None):
    result = {'kind': kind, 'width': width, 'signed': signed}
    if state is not None:
        result['state_model'] = state
    return result

def record(*pairs):
    return {'kind': 'record', 'width': sum(spec['width'] for _, spec in pairs),
        'signed': 0, 'member_order': [name for name, _ in pairs],
        'members': {name: spec for name, spec in pairs}}

def items(*specs):
    return {'kind': 'list', 'width': sum(spec['width'] for spec in specs),
        'signed': 0, 'items': list(specs)}

def bit(state=None):
    return scalar('bit', 1, state=state)

def bits(width, signed=0, state=None):
    return scalar('bits', width, signed, state)

# These literals follow the authored controls fixture, independent of parser,
# metadata, traversal and Storable normalization implementations.
types = {
    'frame': record(('flag', bit()), ('data', bits(7))),
    'renamed': record(('tag', bit()), ('data', bits(7))),
    'reordered': record(('data', bits(7)), ('flag', bit())),
    'signed_data': record(('flag', bit()), ('data', bits(7, 1))),
    'four': record(('flag', bit()), ('data', bits(7, state='four_state'))),
    'two': record(('flag', bit()), ('data', bits(7, state='two_state'))),
    'bit_kind': record(('flag', bits(1)), ('data', bits(7))),
    'nested': record(('header', bits(2)), ('body', record(
        ('count', bits(3, 1, 'four_state')),
        ('lanes', items(bit('two_state'), bits(2)))))),
    'flat': record(('header', bits(2)), ('count', bits(3, 1, 'four_state')),
        ('lane0', bit('two_state')), ('lane1', bits(2))),
    'lanes': items(bit(), bits(2)),
}
types['alias'] = copy.deepcopy(types['frame'])
result = {
    'authority': 'Whole original authored controls fixture/shared.fsm package and existing '
        'public packed type/range contracts. Hand-authored recursive identities/layouts; '
        'no native result or provider is called to build expected types.',
    'types': types,
    'imported': {'shared.frame': copy.deepcopy(types['frame'])},
    'scalar': bits(7),
    'layouts': {
        'frame': [['flag', 1, 7, 7, 0, None, 'bit'], ['data', 7, 0, 6, 0, None, 'bits']],
        'alias': [['flag', 1, 7, 7, 0, None, 'bit'], ['data', 7, 0, 6, 0, None, 'bits']],
        'renamed': [['tag', 1, 7, 7, 0, None, 'bit'], ['data', 7, 0, 6, 0, None, 'bits']],
        'reordered': [['data', 7, 1, 7, 0, None, 'bits'], ['flag', 1, 0, 0, 0, None, 'bit']],
        'signed_data': [['flag', 1, 7, 7, 0, None, 'bit'], ['data', 7, 0, 6, 1, None, 'bits']],
        'four': [['flag', 1, 7, 7, 0, None, 'bit'], ['data', 7, 0, 6, 0, 'four_state', 'bits']],
        'two': [['flag', 1, 7, 7, 0, None, 'bit'], ['data', 7, 0, 6, 0, 'two_state', 'bits']],
        'bit_kind': [['flag', 1, 7, 7, 0, None, 'bits'], ['data', 7, 0, 6, 0, None, 'bits']],
        'nested': [['header', 2, 6, 7, 0, None, 'bits'],
            ['body.count', 3, 3, 5, 1, 'four_state', 'bits'],
            ['body.lanes[0]', 1, 2, 2, 0, 'two_state', 'bit'],
            ['body.lanes[1]', 2, 0, 1, 0, None, 'bits']],
        'flat': [['header', 2, 6, 7, 0, None, 'bits'],
            ['count', 3, 3, 5, 1, 'four_state', 'bits'],
            ['lane0', 1, 2, 2, 0, 'two_state', 'bit'], ['lane1', 2, 0, 1, 0, None, 'bits']],
        'lanes': [['[0]', 1, 2, 2, 0, None, 'bit'], ['[1]', 2, 0, 1, 0, None, 'bits']],
    },
}
(BASE / 'authored-models.json').write_text(json.dumps(result, sort_keys=True, indent=2) + '\n')
print('PASS complete independent authored recursive type/property/order/layout models written; '
    'actual source/copy/private-stage/product join remains required.')
