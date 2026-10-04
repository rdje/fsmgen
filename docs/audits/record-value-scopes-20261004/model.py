"""Independent scope semantics from authored roots and qualified copy stages."""
import copy
import re

def thaw(value, seen=None, path=''):
    if not isinstance(value, list):
        return value
    seen = {} if seen is None else seen
    kind, body = value
    if kind == 'reference':
        return seen[body]
    assert kind in ('hash', 'array')
    result = {} if kind == 'hash' else []
    seen[path] = result
    for key, child in (body.items() if kind == 'hash' else enumerate(body)):
        segment = str(key).replace('~', '~0').replace('/', '~1')
        item = thaw(child, seen, path + '/' + segment)
        if kind == 'hash':
            result[key] = item
        else:
            result.append(item)
    return result

def source_projection(value, seen=None):
    """Only declared type width/signed spelling projects; raw graphs retain."""
    if not isinstance(value, (dict, list)):
        return value
    seen = {} if seen is None else seen
    if id(value) in seen:
        return seen[id(value)]
    result = {} if isinstance(value, dict) else []
    seen[id(value)] = result
    if isinstance(value, dict):
        for key, child in value.items():
            if 'kind' in value and key in ('width', 'signed'):
                assert type(child) in (int, str) and re.fullmatch(r'[0-9]+', str(child))
                result[key] = int(child)
            else:
                result[key] = source_projection(child, seen)
    else:
        result.extend(source_projection(child, seen) for child in value)
    return result

def type_valid(spec, ancestors=()):
    if not isinstance(spec, dict) or id(spec) in ancestors:
        return False
    kind = spec.get('kind')
    if kind not in ('record', 'list', 'bit', 'bits'):
        return False
    required = {'kind', 'width', 'signed'}
    if kind == 'record':
        required |= {'member_order', 'members'}
    if kind == 'list':
        required |= {'items'}
    optional = {'state_model'} if kind in ('bit', 'bits') else set()
    if not required <= set(spec) <= required | optional:
        return False
    if type(spec['width']) is not int or spec['width'] <= 0 or spec['signed'] not in (0, 1):
        return False
    if kind in ('bit', 'bits'):
        return (kind != 'bit' or spec['width'] == 1) and spec.get('state_model', 'two_state') in ('two_state', 'four_state')
    if spec['signed'] != 0:
        return False
    if kind == 'record':
        names, members = spec['member_order'], spec['members']
        if not isinstance(names, list) or not isinstance(members, dict) or not names:
            return False
        if any(not isinstance(name, str) or not re.fullmatch(r'[A-Za-z_]\w*', name) for name in names):
            return False
        if len(set(names)) != len(names) or set(names) != set(members):
            return False
        children = [members[name] for name in names]
    else:
        children = spec['items']
        if not isinstance(children, list) or not children:
            return False
    return all(type_valid(child, ancestors + (id(spec),)) for child in children) and sum(child['width'] for child in children) == spec['width']

def prepared_type(source, raw):
    # Rebuild every source-owned key, property and recursive position. The
    # recorded own clone supplies only exact preparation width/signed kinds.
    assert isinstance(source, dict) and isinstance(raw, dict) and set(source) == set(raw)
    result = {}
    for key, child in source.items():
        if key in ('width', 'signed'):
            assert int(raw[key]) == child
            result[key] = copy.deepcopy(raw[key])
        elif key == 'members':
            result[key] = {name: prepared_type(child[name], raw[key][name]) for name in child}
        elif key == 'items':
            result[key] = [prepared_type(a, b) for a, b in zip(child, raw[key])]
            assert len(child) == len(raw[key])
        else:
            assert child == raw[key]
            result[key] = copy.deepcopy(child)
    if source['kind'] in ('record', 'list'):
        result['signed'] = source['signed']  # Explicit numeric aggregate overlay validation.
    return result

def scope_model(recipe, private, graph):
    values = thaw(recipe['arguments'])
    arguments = dict(zip(values[::2], values[1::2]))
    if set(arguments) != {'outer', 'local'}:
        assert not private and recipe['accepted'] == 0
        return None, []
    result, stages = {}, []
    for layer in ('outer', 'local'):
        for name in sorted(arguments[layer]):
            source = arguments[layer][name]
            assert set(source) == {'role', 'type_spec'}
            stage = private[len(stages)]
            raw = thaw(stage['copy'])
            assert graph(source_projection(raw)) == graph(source), 'whole private stage must retain independently authored source identity'
            stages.append({'name': name, 'layer': layer, 'copy_index': stage['index']})
            if source['role'] not in ('input', 'output', 'storage', 'local') or (source['type_spec'] is not None and not type_valid(source['type_spec'])):
                assert len(stages) == len(private) and recipe['accepted'] == 0
                return None, stages
            result[name] = {'role': source['role'], 'type_spec': None if source['type_spec'] is None
                else prepared_type(source['type_spec'], raw['type_spec'])}
    assert len(stages) == len(private) and recipe['accepted'] == 1
    return graph(result), stages
