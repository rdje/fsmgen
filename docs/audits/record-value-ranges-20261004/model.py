"""Declared-type range oracle, independent of native or value-gate products."""
import copy
import re

def resolve(root, text):
    spec, remaining, offset = root, text, 0
    if not text:
        return {'ok': 0, 'code': 'empty_path'}
    while remaining:
        member = re.match(r'\.([A-Za-z_]\w*)', remaining)
        index = re.match(r'\[([0-9]+)(?::([0-9]+))?\]', remaining)
        if member:
            name = member[1]
            if spec['kind'] != 'record':
                label = ('signed ' if spec.get('signed') else '') + ('bit' if spec['kind'] == 'bit' else 'bits[' + str(spec['width']) + ']')
                return {'ok': 0, 'code': 'member_on_non_record', 'member_name': name, 'current_type_label': label}
            if name not in spec['members']:
                return {'ok': 0, 'code': 'unknown_member', 'member_name': name, 'known_members': copy.deepcopy(spec['member_order'])}
            names = spec['member_order']
            offset += sum(spec['members'][later]['width'] for later in names[names.index(name) + 1:])
            spec = spec['members'][name]
            remaining = remaining[member.end():]
        elif index:
            first = int(index[1])
            second = int(index[2]) if index[2] is not None else None
            if spec['kind'] == 'list':
                if second is not None:
                    return {'ok': 0, 'code': 'list_range_not_supported'}
                if first >= len(spec['items']):
                    return {'ok': 0, 'code': 'list_index_out_of_range', 'index': first, 'max_index': len(spec['items']) - 1}
                offset += sum(child['width'] for child in spec['items'][first + 1:])
                spec = spec['items'][first]
            else:
                assert spec['kind'] in ('bit', 'bits')
                if second is None and first >= spec['width']:
                    return {'ok': 0, 'code': 'scalar_index_out_of_range', 'index': first, 'scalar_width': spec['width']}
                if second is not None and max(first, second) >= spec['width']:
                    return {'ok': 0, 'code': 'scalar_slice_out_of_range', 'high': first, 'low': second, 'scalar_width': spec['width']}
                low, high = (first, first) if second is None else (min(first, second), max(first, second))
                offset += low
                width = high - low + 1
                spec = {'kind': 'bit' if width == 1 else 'bits', 'width': width, 'signed': 0}
            remaining = remaining[index.end():]
        else:
            return {'ok': 0, 'code': 'parse_error', 'remaining': remaining}
    return {'ok': 1, 'low': offset, 'high': offset + spec['width'] - 1, 'width': spec['width'], 'type_spec': copy.deepcopy(spec)}

def prepared(source, raw):
    """Rebuild all source keys; own clone input supplies only scalar spelling."""
    assert set(source) == set(raw)
    result = {}
    for key, value in source.items():
        if key in ('width', 'signed'):
            assert type(raw[key]) in (int, str) and int(raw[key]) == value
            result[key] = raw[key]
        elif key == 'members':
            assert set(value) == set(raw[key])
            result[key] = {name: prepared(child, raw[key][name]) for name, child in value.items()}
        elif key == 'items':
            assert len(value) == len(raw[key])
            result[key] = [prepared(a, b) for a, b in zip(value, raw[key])]
        else:
            assert value == raw[key]
            result[key] = copy.deepcopy(value)
    return result
