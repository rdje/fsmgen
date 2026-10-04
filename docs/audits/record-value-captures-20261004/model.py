"""Source-directed declared metadata projection; native results are not inputs."""
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

def hydrate(value, root=None):
    if isinstance(value, dict):
        if value == {'$reference': '.'}:
            assert root is not None
            return root
        result = {}
        root = result if root is None else root
        result.update({key: hydrate(child, root) for key, child in value.items()})
        return result
    if isinstance(value, list):
        return [hydrate(child, root) for child in value]
    return value

def type_meaning(value, seen=None):
    """Only source type width/signed spelling projects; raw inputs stay bound."""
    if not isinstance(value, (dict, list)):
        return value
    seen = {} if seen is None else seen
    if id(value) in seen:
        return seen[id(value)]
    result = {} if isinstance(value, dict) else []
    seen[id(value)] = result
    if isinstance(value, dict):
        for key, child in value.items():
            result[key] = int(child) if 'kind' in value and key in ('width', 'signed') else type_meaning(child, seen)
    else:
        result.extend(type_meaning(child, seen) for child in value)
    return result

class Refusal(Exception):
    pass

def require(predicate, message):
    if not predicate:
        raise Refusal(message)

def scalar_leaves(spec, path='', low=0, ancestors=()):
    require(isinstance(spec, dict), 'invalid resolved member type')
    require(id(spec) not in ancestors, 'cyclic resolved type')
    require(type(spec.get('width')) is int and spec['width'] > 0, 'invalid resolved type width')
    kind = spec.get('kind')
    if kind in ('bit', 'bits'):
        require(kind != 'bit' or spec['width'] == 1, 'bit type width must be one')
        require('signed' not in spec or type(spec['signed']) is int and spec['signed'] in (0, 1), 'invalid resolved signed property')
        require('state_model' not in spec or spec['state_model'] in ('two_state', 'four_state'), 'invalid resolved state model')
        field = {'path': path, 'width': spec['width'], 'lsb': low, 'msb': low + spec['width'] - 1, 'signed': spec.get('signed', 0)}
        if 'state_model' in spec:
            field['state_model'] = spec['state_model']
        return [field]
    if kind == 'record':
        names, members = spec.get('member_order'), spec.get('members')
        require(isinstance(names, list) and isinstance(members, dict) and bool(names), 'record requires ordered members')
        require(len(members) == len(names), 'record member inventory disagrees')
        require(len(names) == len(set(names)) and all(isinstance(name, str) and re.fullmatch(r'[A-Za-z_]\w*', name) and name in members for name in names), 'invalid or duplicate record member')
        children = [(path + ('.' if path else '') + name, members[name]) for name in names]
    elif kind == 'list':
        require(bool(path), 'list-root interface metadata remains unsupported')
        items = spec.get('items')
        require(isinstance(items, list) and bool(items), 'list requires ordered items')
        children = [(path + '[' + str(i) + ']', child) for i, child in enumerate(items)]
    else:
        raise Refusal('unsupported resolved type kind')
    # Visit source order before testing the aggregate sum, as the public
    # contract refuses the cyclic/invalid child before any packed projection.
    groups = [scalar_leaves(child, name, 0, ancestors + (id(spec),)) for name, child in children]
    require(sum(child['width'] for _, child in children) == spec['width'], 'resolved aggregate width disagrees with members')
    cursor = low + spec['width']
    result = []
    for (_, child), fields in zip(children, groups):
        cursor -= child['width']
        result.extend(dict(field, lsb=field['lsb'] + cursor, msb=field['msb'] + cursor) for field in fields)
    return result

def capture(interface, default_domain):
    if interface is None:
        return None
    require(isinstance(interface, dict), 'expected declared interface')
    require(default_domain is None or isinstance(default_domain, str) and re.fullmatch(r'[A-Za-z_]\w*', default_domain), 'invalid default domain')
    result = []
    for group, role in [('inputs', 'input'), ('outputs', 'output')]:
        require(isinstance(interface.get(group), list), 'expected ' + group + ' array')
        for port in interface[group]:
            require(isinstance(port, dict), 'expected declared port')
            require(isinstance(port.get('name'), str) and bool(port['name']), 'invalid declared port name')
            require(type(port.get('width')) is int and port['width'] > 0, 'invalid declared port width')
            entry = {'name': port['name'], 'direction': role, 'width': port['width']}
            domain = port.get('domain', default_domain)
            if domain is not None:
                entry['domain'] = domain
            if 'type' in port:
                spec = port.get('type_spec')
                require(isinstance(spec, dict), "port '" + port['name'] + "' lacks resolved type")
                fields = scalar_leaves(spec)
                require(port['width'] == spec['width'], "port '" + port['name'] + "' type width disagrees")
                entry.update(type=port['type'], type_kind=spec['kind'])
                if spec['kind'] == 'record':
                    entry['fields'] = fields
                else:
                    require(spec['kind'] in ('bit', 'bits'), "port '" + port['name'] + "' unsupported root type")
            else:
                require('type_spec' not in port, "port '" + port['name'] + "' has type facts without an alias")
            result.append(entry)
    return result
