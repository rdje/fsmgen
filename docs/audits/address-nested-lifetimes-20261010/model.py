"""Join runtime source graphs and every active core/operation reference slot."""
import itertools


def encode(value, seen=None, path=''):
    seen = {} if seen is None else seen
    if type(value) not in (dict, list):
        return value
    if id(value) in seen:
        return ['reference', seen[id(value)]]
    seen[id(value)] = path
    def child(key, item):
        return encode(item, seen, path + '/' + str(key).replace('~', '~0').replace('/', '~1'))
    return ['hash', {key: child(key, value[key]) for key in sorted(value)}] if type(value) is dict else [
        'array', [child(i, item) for i, item in enumerate(value)]]


def paths(value):
    found = {}
    def walk(item, path):
        if type(item) not in (dict, list) or id(item) in found:
            return
        found[id(item)] = path
        for key, child in (((k, item[k]) for k in sorted(item)) if type(item) is dict else enumerate(item)):
            walk(child, path + '/' + str(key).replace('~', '~0').replace('/', '~1'))
    walk(value, '')
    return found


def relations(bindings, held):
    distinct, unresolved = [], []
    for left, right in itertools.combinations(sorted(held), 2):
        a, b = bindings[left], bindings[right]
        if a['reference_kind'] != b['reference_kind']:
            reason = 'different reference kinds'
        elif a['reference_kind'] == 'CODE':
            unresolved.append([left, right])
            continue
        elif a['origin']['kind'] != 'joint_source_node' or b['origin']['kind'] != 'joint_source_node':
            reason = 'fresh source local/caller allocation held by active calls or observer records'
        elif a['origin']['pool'] == b['origin']['pool']:
            reason = 'distinct nodes of one complete qualified source graph'
        elif 'constructed' in (a['origin']['pool'], b['origin']['pool']):
            reason = 'fresh source interface construction while supplied/private roots remain held'
        else:
            reason = 'finite detached-copy hypothesis; original provider identity not measured'
        distinct.append({'bindings': [left, right], 'reason': reason})
    return distinct, unresolved


def derive(inputs, thaw):
    cases = []
    for source in inputs['cases']:
        meta_input = source['metadata_input']
        pair, legacy = meta_input['pair'], source['metadata_hypothesis']
        scope_api, capture_api = pair['scope_api'], pair['capture_api']
        arguments = thaw(source['scope_operation_source']['source_input_graph'])
        value_root = thaw(source['value_private']['result'])
        spec = value_root['type_spec']
        if spec['kind'] == 'list':
            raise ValueError('finite nested source profile excludes Value list wrapping')
        constructed = {'inputs': [{'name': 'value', 'type': 'resolved_value', 'width': spec['width'], 'type_spec': spec}], 'outputs': []}
        if encode([constructed]) != pair['capture_input_model']:
            raise ValueError('complete source constructor and qualified capture input graph')
        metadata_root = thaw(meta_input['private']['result'])
        joint = [arguments, value_root, constructed, metadata_root]
        canonical = paths(joint)
        bindings = {}
        def node(item):
            path = canonical[id(item)]
            pool = {'0': 'supplied_scope', '1': 'value_private', '2': 'constructed', '3': 'metadata_private'}[path.split('/')[1]]
            origin = {'kind': 'joint_source_node', 'node': path, 'pool': pool}
            if pool == 'value_private':
                origin['copy_index'] = source['value_private']['domain'][1]
            if pool == 'metadata_private':
                origin['copy_index'] = meta_input['private']['domain'][1]
            key = 'node:' + path
            bindings[key] = {'reference_kind': 'HASH' if type(item) is dict else 'ARRAY', 'origin': origin}
            return key
        value_root_key, meta_root_key, constructed_key = node(value_root), node(metadata_root), node(constructed)
        value_spec_key = node(spec)
        scope_arguments = {i: node(arg) for i, arg in enumerate(arguments) if type(arg) in (dict, list)}
        for kind, api, expression in (('scope', scope_api, '$value{record_value_scope}'), ('capture', capture_api, '$capture')):
            bindings['saved:' + kind] = {'reference_kind': 'CODE', 'origin': {'kind': 'saved_lookup', 'expression': expression}}
            bindings['caller:' + kind] = {'reference_kind': 'ARRAY', 'origin': {'kind': 'observer_caller_snapshot', 'api': api, 'expression': '[caller]'}}
        for key, role in (('metadata:sink', 'fresh:sink'), ('metadata:active', 'fresh:active')):
            descriptor = legacy['bindings'][role]
            bindings[key] = {'reference_kind': descriptor['reference_kind'], 'origin': {
                'kind': 'metadata_recursion_local', 'capture_api': capture_api, 'source': descriptor['origin']}}
        views = []
        for name, record, phase, inner in (('capture-inner', capture_api, 0, True),
                                           ('scope-inner', scope_api, 0, True),
                                           ('scope-outer', scope_api, 1, False)):
            frames = (meta_input['capture']['frames'] + source['inherited']['inner_path']) if inner else source['inherited']['new_outer_path']
            occurrences = []
            legacy_slots = {(r['frame'], r['argument']): r['binding'] for r in legacy['occurrences']}
            for fi, frame in enumerate(frames):
                for ai, arg in enumerate(frame['arguments']):
                    if arg['kind'] != 'reference':
                        continue
                    function = frame['function']
                    if inner and fi < len(meta_input['capture']['frames']):
                        old = legacy['bindings'][legacy_slots[fi, ai]]['origin']
                        if old['kind'] == 'supplied_capture_input':
                            key = constructed_key
                        elif old['kind'] == 'qualified_metadata_private_result':
                            key = 'node:/3' + old['node']
                            value = metadata_root
                            for segment in old['node'].split('/')[1:]:
                                value = value[int(segment)] if type(value) is list else value[segment.replace('~1', '/').replace('~0', '~')]
                            if node(value) != key:
                                raise ValueError('complete shared Metadata source graph canonical node')
                        else:
                            key = 'metadata:sink' if old['kind'] == 'fresh_scalar_path_sink' else 'metadata:active'
                    elif function.endswith('::_validate_type'):
                        key = value_spec_key
                    elif function.endswith('::record_value_scope'):
                        key = scope_arguments[ai]
                    elif function == 'main::call_api':
                        kind = frame['arguments'][0]['value']
                        key = 'saved:' + kind if ai == 1 else 'caller:' + kind if ai == 2 else (
                            constructed_key if kind == 'capture' else scope_arguments[ai - 3])
                    elif function == 'main::__ANON__':
                        kind = 'capture' if frame['call_site'] == 'installed_capture_wrapper' else 'scope'
                        key = constructed_key if kind == 'capture' else scope_arguments[ai]
                    else:
                        raise ValueError('every nested core/operation source reference slot declared')
                    if bindings[key]['reference_kind'] != arg['reference_kind']:
                        raise ValueError('nested source reference kind conserves qualified frames')
                    occurrences.append({'frame': fi, 'argument': ai, 'role': arg['role'], 'binding': key})
            active = {row['binding'] for row in occurrences} | {value_root_key, value_spec_key}
            if inner:
                active |= {meta_root_key, constructed_key, 'metadata:sink', 'metadata:active'}
            retained = ['caller:capture', 'caller:scope', 'saved:capture', 'saved:scope']
            held = active | set(retained)
            distinct, unresolved = relations(bindings, held)
            old_case = source['capture_operation_hypothesis'] if record == capture_api else source['scope_operation_hypothesis']
            bridges = []
            by_slot = {(r['frame'], r['argument']): r['binding'] for r in occurrences}
            for operation in old_case['operations']:
                if operation['domain'][3] != phase:
                    continue
                start = next(i for i, f in enumerate(frames) if f['function'] == operation['frames'][0]['function'])
                if [f['function'] for f in frames[start:start + 4]] != [f['function'] for f in operation['frames']]:
                    raise ValueError('whole original nested operation boundary shape')
                resolved = {}
                for occurrence in operation['occurrences']:
                    key = by_slot[start + occurrence['frame'], occurrence['argument']]
                    previous = resolved.setdefault(occurrence['binding'], key)
                    if previous != key:
                        raise ValueError('one original operation source referent has one joined binding')
                bridges.append({'domain': operation['domain'], 'canonical_invocation': [operation['kind'], capture_api if operation['kind'] == 'capture' else scope_api],
                                'bindings': resolved, 'previous_input_topology': operation['input_topology'],
                                'joined_input_topology': 'complete qualified nested source graph'})
            views.append({'name': name, 'record_api': record, 'phase': phase, 'frames': frames,
                          'event': ['inner-Metadata', capture_api] if inner else ['new-Value', scope_api],
                          'occurrences': occurrences, 'active_bindings': sorted(active), 'source_retained_bindings': retained,
                          'active_invocations': [['scope', scope_api], ['capture', capture_api]] if inner else [['scope', scope_api]],
                          'inactive_invocations': [] if inner else [['capture', capture_api]],
                          'returned_copy_delegates': [
                              {'kind': 'value-private', 'copy_index': source['value_private']['domain'][1], 'result_binding': value_root_key, 'active_source_holder': True, 'activation': 'returned before this throw; inactive delegate'},
                              {'kind': 'metadata-private', 'copy_index': meta_input['private']['domain'][1], 'result_binding': meta_root_key, 'active_source_holder': inner, 'activation': 'returned before this throw; inactive delegate'}],
                          'no_active_own_holder': [] if inner else sorted([constructed_key, meta_root_key, 'metadata:sink', 'metadata:active']),
                          'operation_bridges': bridges, 'simultaneously_live_distinct': distinct,
                          'unresolved_distinctions': unresolved})
        cases.append({'mode': source['mode'], 'scope_api': scope_api, 'capture_api': capture_api,
                      'joint_source_graph': encode(joint), 'bindings': bindings, 'views': views,
                      'retention_contract': 'Observer @api records retain both caller snapshots; saved lookups remain in the observer lexical scope. Inactive source calls do not establish object death or external/provider retention.'})
    return {'cases': cases, 'scope': 'Complete finite nested Metadata/Value source alias, active-operation and retained-snapshot hypotheses across all source-record/throw views. Graph carrier arrays are symbolic packaging. Original numeric/private/provider/formatter/CODE identity, external/global retention, helper/parser roles and canonical publication remain open.'}
