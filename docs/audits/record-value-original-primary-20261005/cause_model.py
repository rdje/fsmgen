"""Independent finite validation/cause model over qualified source inputs.

This models the pinned original record-value workload, not arbitrary Perl APIs.
Primitive projection below is used only for declared physical predicates;
source graphs and raw kinds remain separately qualified by the prerequisites.
"""
import re


class Primary(ValueError):
    pass


def must(condition, message):
    if not condition:
        raise Primary(message)


def scalar(value):
    return type(value) in (str, int)


def positive(value):
    return scalar(value) and re.fullmatch(r'[1-9][0-9]*', str(value)) is not None


def binary(value):
    return scalar(value) and str(value) in ('0', '1')


def identifier(value):
    return type(value) is str and re.fullmatch(r'[A-Za-z_]\w*', value) is not None


def role(value):
    return value in ('input', 'output', 'storage', 'local')


def keys(value, required, optional, context):
    must(type(value) is dict, context + ' must be a map')
    must(set(required) <= set(value), context + ' lacks required facts')
    must(set(value) <= set(required) | set(optional), context + ' has unknown facts')


def metadata_type(spec, path='', active=None):
    active = set() if active is None else active
    must(type(spec) is dict, 'invalid resolved member type')
    must(id(spec) not in active, 'cyclic resolved type')
    active = active | {id(spec)}
    must(positive(spec.get('width')), 'invalid resolved type width')
    kind = spec.get('kind', '')
    if kind in ('bit', 'bits'):
        must(kind != 'bit' or int(spec['width']) == 1, 'bit type width must be one')
        must('signed' not in spec or binary(spec['signed']), 'invalid resolved signed property')
        must('state_model' not in spec or spec['state_model'] in ('two_state', 'four_state'), 'invalid resolved state model')
        return
    width = 0
    if kind == 'record':
        members, order = spec.get('members'), spec.get('member_order')
        must(type(members) is dict and type(order) is list and bool(order), 'record requires ordered members')
        must(len(members) == len(order), 'record member inventory disagrees')
        seen = set()
        for name in order:
            must(identifier(name) and name not in seen and name in members, 'invalid or duplicate record member')
            seen.add(name)
            metadata_type(members[name], path + '.' + name, active)
            width += int(members[name]['width'])
    elif kind == 'list':
        must(bool(path), 'list-root interface metadata remains unsupported')
        items = spec.get('items')
        must(type(items) is list and bool(items), 'list requires ordered items')
        for index, item in enumerate(items):
            metadata_type(item, path + '[' + str(index) + ']', active)
            width += int(item['width'])
    else:
        raise Primary('unsupported resolved type kind')
    must(width == int(spec['width']), 'resolved aggregate width disagrees with members')


def closed_type(spec, context):
    kind = spec['kind']
    extra = ['members', 'member_order'] if kind == 'record' else ['items'] if kind == 'list' else []
    keys(spec, ['kind', 'width', 'signed'] + extra, [] if extra else ['state_model'], context + ' resolved type')
    must(binary(spec['signed']), context + ' has invalid resolved signed fact')
    if extra:
        must(int(spec['signed']) == 0, context + ' aggregate has a scalar signed overlay')
        children = [spec['members'][name] for name in spec['member_order']] if kind == 'record' else spec['items']
        for child in children:
            closed_type(child, context)


def value_type(spec, context):
    must(type(spec) is dict, context + ' lacks a resolved type')
    checked = dict(kind='record', width=spec['width'], signed=0,
                   member_order=['value'], members={'value': spec}) if spec.get('kind') == 'list' else spec
    try:
        metadata_type(checked)
    except Primary as error:
        raise Primary(context + ' has invalid resolved type: Invalid ISF interface port metadata: ' + str(error))
    closed_type(spec, context)


def signature(value):
    if type(value) is dict:
        return tuple((key, signature(value[key])) for key in sorted(value))
    if type(value) is list:
        return tuple(signature(item) for item in value)
    return str(value) if value is not None else None


def reference_value(value, context):
    keys(value, ['root', 'role', 'path_text', 'type_spec', 'width'], ['low', 'high'], context + ' value')
    must(identifier(value['root']) and role(value['role']) and type(value['path_text']) is str,
         context + ' has invalid declaration facts')
    value_type(value['type_spec'], context)
    must(positive(value['width']) and int(value['width']) == int(value['type_spec']['width']),
         context + ' value width disagrees with resolved type')
    leaf = bool(value['path_text'])
    must(leaf == ('low' in value and 'high' in value), context + ' value range disagrees with path')
    must(leaf or ('low' not in value and 'high' not in value), context + ' whole value cannot have a range')
    if leaf:
        must(value['type_spec']['kind'] not in ('record', 'list') and int(value['low']) >= 0
             and int(value['high']) >= 0 and int(value['high']) - int(value['low']) + 1 == int(value['width']),
             context + ' has invalid scalar range')


def path_result(spec, path):
    while path:
        member = re.match(r'\.([A-Za-z_]\w*)', path)
        item = re.match(r'\[([0-9]+)(?::([0-9]+))?\]', path)
        if member:
            if spec['kind'] != 'record':
                return None, 'member_on_non_record'
            if member[1] not in spec['members']:
                return None, 'unknown_member'
            spec = spec['members'][member[1]]
            path = path[member.end():]
        elif item:
            index = int(item[1])
            if spec['kind'] == 'list' and item[2] is None:
                if index >= len(spec['items']):
                    return None, 'list_index_out_of_range'
                spec = spec['items'][index]
            elif spec['kind'] in ('bit', 'bits'):
                if index >= int(spec['width']):
                    return None, 'scalar_index_out_of_range'
                low = int(item[2]) if item[2] is not None else index
                if low > index:
                    return None, 'invalid_scalar_slice'
                spec = dict(kind='bits' if item[2] is not None else 'bit', width=index - low + 1, signed=0)
            else:
                return None, 'index_on_non_indexable'
            path = path[item.end():]
        else:
            return None, 'parse_error'
    return spec, None


def values(kind, arguments):
    must(type(arguments) is list and len(arguments) % 2 == 0, 'finite named source arguments')
    args = dict(zip(arguments[::2], arguments[1::2]))
    if kind == 'scope':
        keys(args, ['outer', 'local'], [], 'scope')
        for layer in ('outer', 'local'):
            roots = args[layer]
            must(type(roots) is dict, layer + ' roots must be a map')
            for name in sorted(roots):
                must(identifier(name), 'invalid declaration root')
                root = roots[name]; context = "root '" + name + "'"
                keys(root, ['role', 'type_spec'], [], context)
                must(role(root['role']), context + ' has invalid role')
                if root['type_spec'] is not None:
                    value_type(root['type_spec'], context)
    elif kind == 'reference':
        keys(args, ['scope', 'token', 'access', 'context'], ['allow_whole'], 'reference')
        context, token, access, scope = (args[key] for key in ('context', 'token', 'access', 'scope'))
        must(type(scope) is dict, 'reference scope must be a map')
        must(type(context) is str and bool(context), 'reference requires context')
        must(access in ('read', 'write'), context + ' has invalid access')
        must(binary(args.get('allow_whole', 0)), context + ' has invalid whole-value permission')
        match = re.match(r'([A-Za-z_]\w*)(.*)', token) if type(token) is str else None
        if match is None or match[1] not in scope:
            return
        name, path = match.groups(); root = scope[name]
        keys(root, ['role', 'type_spec'], [], context + " root '" + name + "'")
        must(role(root['role']), context + " root '" + name + "' has invalid role")
        must(access != 'write' or root['role'] != 'input', context + " cannot write declared input '" + token + "'")
        if root['type_spec'] is None:
            return
        value_type(root['type_spec'], context + " root '" + name + "'")
        spec = root['type_spec']
        if not path:
            must(int(args.get('allow_whole', 0)) or spec['kind'] not in ('record', 'list'),
                 context + " requires a scalar value; '" + token + "' is a whole " + spec['kind'])
        else:
            spec, code = path_result(spec, path)
            must(code is None, context + " has invalid declared path '" + token + "': " + str(code))
            must(spec['kind'] not in ('record', 'list'), context + " requires a scalar leaf; '" + token + "' resolves to " + spec['kind'])
    elif kind == 'copy':
        keys(args, ['source', 'target', 'context'], [], 'copy')
        context = args['context']; must(type(context) is str and bool(context), 'copy requires context')
        source, target = args['source'], args['target']
        for value in (source, target):
            if value is not None:
                reference_value(value, context)
        whole = lambda value: type(value) is dict and not value['path_text'] and value['type_spec']['kind'] == 'record'
        port = lambda value: whole(value) and value['role'] in ('input', 'output')
        if not (port(source) or port(target)):
            return
        must(whole(source) and whole(target), context + ' whole record port copy requires declared record roots')
        must(target['role'] != 'input', context + " cannot write declared input '" + target['root'] + "'")
        must(signature(source['type_spec']) == signature(target['type_spec']),
             context + " record port copy from '" + source['root'] + "' to '" + target['root'] + "' requires the same resolved record type")


def primary(kind, arguments):
    try:
        if kind in ('scope', 'reference', 'copy'):
            values(kind, arguments)
        elif kind == 'capture':
            interface = arguments[0]
            if interface is not None:
                for direction in ('inputs', 'outputs'):
                    for port in interface[direction]:
                        if 'type' in port:
                            metadata_type(port['type_spec'])
        # Other families retain separately qualified successful source/product
        # meanings. This finite workload has no rejection in those families.
    except Primary as error:
        prefix = 'Invalid ISF interface port metadata: ' if kind == 'capture' else 'Invalid ISF record value: '
        return prefix + str(error)
    return None
