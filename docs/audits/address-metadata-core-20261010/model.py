"""Record qualified predicate traversal objects; shared Perl locals are explicit."""
import itertools


def object_paths(root):
    paths = {}
    def visit(value, path):
        if type(value) not in (dict, list) or id(value) in paths:
            return
        paths[id(value)] = path
        for key, child in (((k, value[k]) for k in sorted(value)) if type(value) is dict else enumerate(value)):
            visit(child, path + '/' + str(key).replace('~', '~0').replace('/', '~1'))
    visit(root, '')
    return paths


def observe(cause_source, spec):
    namespace = {'__name__': 'metadata_core_predicates'}
    exec(compile(cause_source, '<qualified-metadata-cause>', 'exec'), namespace)
    original = namespace['metadata_type']
    stack, active, sink, failures = [], [], [], []
    def traverse(value, path='', predicate_active=None):
        if type(value) is not dict:
            raise ValueError('finite Metadata source traversal requires qualified HASH types')
        was_active = id(value) in active
        stack.append((value, path))
        if not was_active:
            active.append(id(value))
        try:
            original(value, path, predicate_active)
            if value.get('kind') in ('bit', 'bits'):
                sink.append(path)
        except namespace['Primary'] as error:
            if not failures:
                failures.append({'message': str(error), 'stack': list(stack),
                                 'active': list(active), 'sink': list(sink)})
            raise
        finally:
            stack.pop()
            if not was_active:
                active.remove(id(value))
    namespace['metadata_type'] = traverse
    try:
        traverse(spec)
    except namespace['Primary']:
        pass
    if len(failures) != 1:
        raise ValueError('one complete Metadata source failure event')
    return failures[0]


def derive(inputs, factory, thaw):
    rows = []
    for source in inputs['cases']:
        pair, captured, private = source['pair'], source['capture'], source['private']
        supplied = thaw(pair['capture_input_model'])
        expected = factory['derive'](inputs['sources']['cause_model'], 'capture', supplied)
        if expected != {key: captured[key] for key in ('primary', 'guard', 'metadata_primary', 'frames')}:
            raise ValueError('complete unchanged qualified Metadata path and predicate')
        copied = thaw(private['result'])
        if len(copied['inputs']) != 1 or copied['outputs']:
            raise ValueError('complete finite constructed interface selects one input traversal')
        paths = object_paths(copied)
        event = observe(inputs['sources']['cause_model'], copied['inputs'][0]['type_spec'])
        if captured['metadata_primary'] != 'Invalid ISF interface port metadata: ' + event['message']:
            raise ValueError('qualified private clone preserves the complete Metadata source predicate')
        recursive = [frame for frame in captured['frames'] if frame['function'].endswith('::_collect_scalar_paths')]
        if [frame['arguments'][1]['value'] for frame in recursive] != [p for _, p in reversed(event['stack'])]:
            raise ValueError('whole Metadata runtime-predicate active ancestry')
        bindings = {
            'input:/0': {'reference_kind': 'HASH', 'origin': {'kind': 'supplied_capture_input', 'node': '/0'}},
            'fresh:sink': {'reference_kind': 'ARRAY', 'origin': {'kind': 'fresh_scalar_path_sink', 'paths': event['sink']}},
            'fresh:active': {'reference_kind': 'HASH', 'origin': {'kind': 'fresh_active_type_path',
                             'nodes': sorted(paths[value] for value in event['active'])}},
        }
        occurrences, ordinal = [], 0
        for fi, frame in enumerate(captured['frames']):
            for ai, arg in enumerate(frame['arguments']):
                if arg['kind'] != 'reference':
                    continue
                if frame['function'].endswith('::capture_interface_port_metadata'):
                    key = 'input:/0'
                elif ai == 0:
                    value, _ = list(reversed(event['stack']))[ordinal]
                    path = paths[id(value)]
                    key = 'copy:' + str(private['domain'][1]) + ':' + path
                    bindings[key] = {'reference_kind': 'HASH', 'origin': {'kind': 'qualified_metadata_private_result',
                                     'api': captured['index'], 'copy_index': private['domain'][1], 'node': path}}
                else:
                    key = 'fresh:sink' if ai == 2 else 'fresh:active'
                if bindings[key]['reference_kind'] != arg['reference_kind']:
                    raise ValueError('every Metadata source reference has its qualified kind')
                occurrences.append({'frame': fi, 'argument': ai, 'role': arg['role'], 'binding': key})
            if frame['function'].endswith('::_collect_scalar_paths'):
                ordinal += 1
        for descriptor in bindings.values():
            descriptor['lifetime'] = 'held by active Metadata capture/traversal at the inner throw; no later outer-throw identity'
        distinct = []
        for left, right in itertools.combinations(sorted(bindings), 2):
            a, b = bindings[left], bindings[right]
            reason = ('different reference kinds' if a['reference_kind'] != b['reference_kind'] else
                      'fresh source local allocation while supplied arguments and active clone nodes live'
                      if a['origin']['kind'].startswith('fresh_') or b['origin']['kind'].startswith('fresh_') else
                      'distinct nodes of one qualified Metadata result graph'
                      if a['origin']['kind'] == b['origin']['kind'] == 'qualified_metadata_private_result' else
                      'finite detached-copy hypothesis; original provider identity not measured')
            distinct.append({'bindings': [left, right], 'reason': reason})
        rows.append({'mode': source['mode'], 'capture_api': captured['index'], 'scope_api': pair['scope_api'],
                     'guard': captured['guard'], 'frames': captured['frames'], 'bindings': bindings,
                     'occurrences': occurrences, 'simultaneously_live_distinct': distinct,
                     'domain': [source['mode'], 'api', captured['index'], 'inner-Metadata-source-throw'],
                     'caught_outer_trace': {'api': pair['scope_api'], 'frames': source['outer']['frames'],
                         'state': 'embedded caught trace, inactive before the later Value throw; cross-operation join remains open'}})
    return {'cases': rows, 'scope': 'Complete finite Metadata core source bindings and shared recursion-local hypotheses. Original numeric/private/provider/formatter identity, later Value throw joins, helper/parser roles and canonical publication remain open.'}
