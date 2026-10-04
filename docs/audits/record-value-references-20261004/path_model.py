"""Source-type path/layout oracle; no public/native product is consulted."""
import copy
import re

def resolve(arguments):
    if set(arguments) - {'scope', 'token', 'access', 'context', 'allow_whole'}:
        return {'accepted': 0, 'reason': 'unknown-argument'}
    whole = arguments.get('allow_whole', 0)
    if whole not in (0, 1):
        return {'accepted': 0, 'reason': 'whole-permission'}
    token = arguments['token']
    match = re.fullmatch(r'([A-Za-z_]\w*)(.*)', token, re.S)
    if not match or match[1] not in arguments['scope']:
        return {'accepted': 1, 'product': None, 'reason': 'unrelated-root'}
    name, path = match.groups()
    binding = arguments['scope'][name]
    if arguments['access'] == 'write' and binding['role'] == 'input':
        return {'accepted': 0, 'reason': 'input-write'}
    spec = binding['type_spec']
    if spec is None:
        return {'accepted': 1, 'product': None, 'reason': 'nearest-unresolved'}
    result = {'root': name, 'role': binding['role'], 'path_text': path}
    if not path:
        if spec['kind'] in ('record', 'list') and not whole:
            return {'accepted': 0, 'reason': 'whole-in-scalar-context'}
        result.update(type_spec=copy.deepcopy(spec), width=spec['width'])
        return {'accepted': 1, 'product': result, 'reason': 'whole-root'}
    offset = 0
    remaining = path
    while remaining:
        member = re.match(r'\.([A-Za-z_]\w*)', remaining)
        item = re.match(r'\[([0-9]+)(?::([0-9]+))?\]', remaining)
        if member:
            if spec['kind'] != 'record' or member[1] not in spec['members']:
                return {'accepted': 0, 'reason': 'member-lookup'}
            names = spec['member_order']
            position = names.index(member[1])
            offset += sum(spec['members'][name]['width'] for name in names[position + 1:])
            spec = spec['members'][member[1]]
            remaining = remaining[member.end():]
        elif item:
            first = int(item[1])
            second = int(item[2]) if item[2] is not None else None
            if spec['kind'] == 'list':
                if second is not None or first >= len(spec['items']):
                    return {'accepted': 0, 'reason': 'list-index'}
                offset += sum(child['width'] for child in spec['items'][first + 1:])
                spec = spec['items'][first]
            elif spec['kind'] in ('bit', 'bits'):
                high, low = (first, first) if second is None else (max(first, second), min(first, second))
                if high >= spec['width']:
                    return {'accepted': 0, 'reason': 'scalar-index'}
                offset += low
                width = high - low + 1
                spec = {'kind': 'bit' if width == 1 else 'bits', 'width': width, 'signed': 0}
            else:
                return {'accepted': 0, 'reason': 'non-indexable'}
            remaining = remaining[item.end():]
        else:
            return {'accepted': 0, 'reason': 'path-syntax'}
    if spec['kind'] in ('record', 'list'):
        return {'accepted': 0, 'reason': 'subaggregate'}
    result.update(type_spec=copy.deepcopy(spec), width=spec['width'], low=offset, high=offset + spec['width'] - 1)
    return {'accepted': 1, 'product': result, 'reason': 'scalar-path'}
