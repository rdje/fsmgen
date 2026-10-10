"""Runtime construction and forwarding graphs for every qualified helper view."""
import itertools
import json

SCOPE = ('Complete finite helper/callback/own-subtest source bindings and source-held lifetimes. '
         'Graph carriers are symbolic source checkpoints, not native allocations or later scalar-flag snapshots. '
         'Original numeric/provider/formatter/Regexp/CODE identity, external framework/global retention, '
         'parser/actor/context roles and canonical publication remain open.')


def same(left, right):
    return json.dumps(left, sort_keys=True) == json.dumps(right, sort_keys=True)


def positions(value):
    result = {}
    def visit(item, path):
        if type(item) not in (list, dict) or id(item) in result:
            return
        result[id(item)] = path
        for key, child in (((k, item[k]) for k in sorted(item)) if type(item) is dict else enumerate(item)):
            visit(child, path + '/' + str(key).replace('~', '~0').replace('/', '~1'))
    visit(value, '')
    return result


def profile(helper, direct, thaw, encode):
    supplied = thaw(helper['supplied_arguments'])
    family = helper['call_shape']['active']['function'] if helper['call_shape']['active'] else None
    operations, completed = [], []
    for operation in helper['named_operations']:
        if operation['kind'] == 'reference':
            if family == 'copy':
                old = thaw(operation['supplied'])
                formal = [supplied[0], *old[1:]]
                completed.append(formal)
            elif family == 'reference':
                formal = supplied
            else:
                formal = thaw(operation['supplied'])
                completed.append(formal)
            values = ['scope', formal[0], 'token', formal[1], 'access', formal[2] if len(formal) > 2 else 'read',
                      'allow_whole', formal[3] if len(formal) > 3 else 0, 'context', 'control']
            if not same(encode(formal), operation['supplied']):
                raise ValueError('complete supplied named-reference source checkpoint')
        elif operation['kind'] == 'scope':
            values = ['outer', {'packet': {'role': 'input', 'type_spec': supplied[0]},
                               'held': {'role': 'storage', 'type_spec': supplied[1]},
                               'output': {'role': 'output', 'type_spec': supplied[1]},
                               'scalar': {'role': 'output', 'type_spec': {'kind': 'bits', 'width': 7, 'signed': 0}}},
                      'local', {}]
        elif operation['kind'] == 'copy':
            values = thaw(operation['normalized_operation_inputs'])
        else:
            raise ValueError('complete finite named operation source family')
        if not same(encode(values), operation['normalized_operation_inputs']):
            raise ValueError('whole named operation source constructor/forwarding graph')
        operations.append(values)
    outer = thaw(direct) if direct is not None else None
    whole = [supplied, operations, completed, outer]
    paths = positions(whole)
    return whole, paths, family


def event(inputs, mode, domain, index, phase):
    for pair in inputs['nested_pairs']:
        if pair['mode'] == mode and domain == 'api':
            if index == pair['capture_api'] or (index == pair['scope_api'] and phase == 0):
                return ['inner-Metadata', pair['capture_api']]
            if index == pair['scope_api']:
                return ['new-Value', pair['scope_api']]
    return ['own-source-throw', domain, index, phase]


def derive(inputs, thaw, encode):
    subtests = {mode['mode']: mode for mode in inputs['subtests']['modes']}
    operations = {(row['mode'], row['domain'], row['index']): row for row in inputs['operation_inputs']}
    body_indices = {body['name']: index for index, body in enumerate(inputs['subtests']['bodies'])}
    modes = []
    for source_mode in inputs['helper_modes']:
        mode = source_mode['mode']
        own = {(row['domain'], row['index']): row for row in subtests[mode]['cases']}
        profiles, bindings, helper_keys = [], {}, {}
        def bind(key, kind, origin):
            descriptor = {'reference_kind': kind, 'origin': origin}
            if key in bindings and bindings[key] != descriptor:
                raise ValueError('one complete source referent descriptor per mode')
            bindings[key] = descriptor
            return key
        def code(key, expression, subtest=None, helper=None):
            origin = {'kind': 'source_code_handle', 'expression': expression}
            if subtest is not None:
                origin['subtest'] = subtest
            if helper is not None:
                origin['helper'] = helper
            return bind(key, 'CODE', origin)
        public = code('saved-public-subtest', "$subtest = Test::More->can('subtest')")
        for helper in source_mode['helpers']:
            hi = helper['index']
            records = [row for row in source_mode['cases'] if row['helper'] == hi]
            if not records:
                raise ValueError('every source helper owns refusal records')
            sub = own[records[0]['domain'], records[0]['index']]
            si = body_indices[sub['name']]
            body = code('subtest:' + str(si) + ':body', 'authored subtest body', subtest=si)
            wrapper = code('subtest:' + str(si) + ':wrapped', 'observer subtest callback', subtest=si)
            saved = code('subtest:' + str(si) + ':helper', "main->can('refuses')", subtest=si)
            callback = code('helper:' + str(hi) + ':callback', 'original parameterless refuses callback', helper=hi)
            pattern = bind('helper:' + str(hi) + ':pattern', 'Regexp',
                           {'kind': 'source_pattern_parameter', 'helper': hi, 'pattern': records[0]['pattern'],
                            'source_declaration': helper['source_declaration']})
            caller = bind('helper:' + str(hi) + ':caller', 'ARRAY',
                          {'kind': 'observer_helper_caller_snapshot', 'helper': hi, 'expression': '[caller]', 'holder': '@helpers'})
            direct = None
            if helper['call_shape']['completed']:
                direct = operations[mode, records[0]['domain'], records[0]['index']]['source_input_graph']
            whole, paths, family = profile(helper, direct, thaw, encode)
            formal_keys = {}
            def node(item):
                path = paths[id(item)]
                return bind('helper:' + str(hi) + ':node:' + path,
                            'HASH' if type(item) is dict else 'ARRAY',
                            {'kind': 'qualified_helper_source_node', 'helper': hi, 'node': path})
            for i, value in enumerate(whole[0]):
                if type(value) in (dict, list):
                    formal_keys[i] = node(value)
            forwarding, returned_holders = [], []
            for oi, operation in enumerate(helper['named_operations']):
                values = whole[1][oi]
                if operation['kind'] == 'reference':
                    forwarding.append({'operation': operation['index'], 'named_argument': 'scope', 'binding': node(values[1])})
                elif operation['kind'] == 'scope':
                    forwarding += [{'operation': operation['index'], 'named_argument': role, 'binding': node(values[pos])}
                                   for role, pos in (('outer', 1), ('local', 3))]
                elif operation['kind'] == 'copy':
                    previous = [op for op in helper['named_operations'][:oi] if op['kind'] == 'reference']
                    if len(previous) != 2:
                        raise ValueError('complete copy helper returned source/target operations')
                    returned_holders += [{'returned_operation': op['index'], 'holder_operation': operation['index'],
                                          'named_argument': role, 'binding': node(values[pos])}
                                         for op, role, pos in zip(previous, ('source', 'target'), (1, 3), strict=True)]
            if helper['call_shape']['completed']:
                source_body = helper['call_shape']['body']
                roles = [role for role in ('source', 'target') if role + ' => reference(' in source_body]
                if len(roles) != 1 or len(helper['named_operations']) != 1:
                    raise ValueError('complete direct callback returned-reference holder source')
                values = whole[3]
                pos = values.index(roles[0]) + 1
                returned_holders.append({'returned_operation': helper['named_operations'][0]['index'],
                                         'holder_operation': records[0]['index'], 'named_argument': roles[0],
                                         'binding': node(values[pos])})
            activations = []
            for operation in helper['named_operations']:
                api = operation['index']
                caller_key = bind('api:' + str(api) + ':caller', 'ARRAY',
                                  {'kind': 'observer_api_caller_snapshot', 'api': api,
                                   'expression': '[caller]', 'holder': '@api'})
                lookup = {'reference': 'record_value_reference', 'scope': 'record_value_scope',
                          'copy': 'validate_record_port_copy'}[operation['kind']]
                saved_key = code('saved-api:' + operation['kind'], '$value{' + lookup + '}')
                activations.append({'index': api, 'kind': operation['kind'], 'activation': operation['phase'],
                                    'caller_binding': caller_key, 'saved_operation_binding': saved_key})
            profiles.append({'helper': hi, 'subtest': si, 'name': sub['name'], 'source_recipe': helper,
                             'graph': encode(whole), 'formal_bindings': {str(i): key for i, key in formal_keys.items()},
                             'forwarding': forwarding, 'returned_result_holders': returned_holders,
                             'named_activations': activations})
            helper_keys[hi] = (si, body, wrapper, saved, callback, pattern, caller, formal_keys)
        cases = []
        for case in source_mode['cases']:
            sub = own[case['domain'], case['index']]
            si, body, wrapper, saved, callback, pattern, caller, formals = helper_keys[case['helper']]
            profile_row = profiles[case['helper']]
            views = []
            for phase, path in enumerate(case['paths']):
                frames = path + sub['body_frames'] + sub['entry_frames']
                occurrences = []
                for fi, frame in enumerate(frames):
                    for ai, arg in enumerate(frame['arguments']):
                        if arg['kind'] not in ('reference', 'regex_source'):
                            continue
                        if frame['function'] in ('main::scope_for', 'main::reference', 'main::copy'):
                            key = formals[ai]
                        elif frame['function'] == 'main::refuses' or frame.get('call_site') == 'installed_observer_helper_wrapper':
                            key = callback if ai == 0 else pattern
                        elif frame.get('role') == 'saved_public_delegate':
                            key = wrapper
                        elif frame.get('role') == 'own_subtest_entry':
                            key = body
                        else:
                            raise ValueError('every helper/callback/subtest reference slot declared')
                        occurrences.append({'frame': fi, 'argument': ai, 'role': arg['role'], 'binding': key})
                held = sorted({row['binding'] for row in occurrences} | {body, wrapper, saved, public, callback, pattern, caller}
                              | {row['binding'] for row in profile_row['forwarding'] + profile_row['returned_result_holders']}
                              | {op[key] for op in profile_row['named_activations']
                                 for key in ('caller_binding', 'saved_operation_binding')})
                opaque = [list(pair) for pair in itertools.combinations(held, 2)
                          if bindings[pair[0]]['reference_kind'] == bindings[pair[1]]['reference_kind'] == 'CODE']
                distinct = [list(pair) for pair in itertools.combinations(held, 2) if list(pair) not in opaque]
                views.append({'domain': [mode, case['domain'], case['index'], phase],
                              'event': event(inputs, mode, case['domain'], case['index'], phase),
                              'frames': frames, 'occurrences': occurrences, 'held_bindings': held,
                              'retained_bindings': [caller] + [op['caller_binding'] for op in profile_row['named_activations']],
                              'active_named_operations': [op['index'] for op in profile_row['named_activations'] if op['activation'] == 'active'],
                              'inactive_named_operations': [op['index'] for op in profile_row['named_activations']
                                                                                      if op['activation'] == 'returned_before_outer_operation'],
                              'opaque_CODE_relations': opaque, 'source_distinct_bindings': distinct,
                              'distinction_scope': 'Different source kinds, fresh retained caller arrays, or distinct complete source graph nodes; detached returns are finite source hypotheses, not native identity.',
                              'public_delegate_activation': 'active own source call; internal framework interval opaque',
                              'opaque_framework_interval': {'after': len(path) + len(sub['body_frames']) - 1,
                                                            'before': len(path) + len(sub['body_frames']),
                                                            'scope': sub['external_interval']}})
            cases.append({'domain': case['domain'], 'index': case['index'], 'helper': case['helper'],
                          'subtest': si, 'views': views})
        modes.append({'mode': mode, 'bindings': bindings, 'profiles': profiles, 'cases': cases})
    return {'modes': modes, 'scope': SCOPE}
