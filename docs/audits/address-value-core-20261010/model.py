"""Finite direct Value source bindings; no raw numeric address is consumed."""
import itertools
import re


def objects(value):
    result = {}
    def visit(item, path):
        if type(item) not in (dict, list) or id(item) in result:
            return
        result[id(item)] = path
        entries = ((key, item[key]) for key in sorted(item)) if type(item) is dict else enumerate(item)
        for key, child in entries:
            visit(child, path + '/' + str(key).replace('~', '~0').replace('/', '~1'))
    visit(value, '')
    return result


def tagged(factory, cause, kind, arguments):
    original = factory['argument']
    retained, tags = [], {}
    def argument(value, role):
        row = original(value, role)
        if row['kind'] == 'reference':
            if id(value) not in tags:
                tags[id(value)] = len(retained)
                retained.append(value)
            row['binding_tag'] = tags[id(value)]
        return row
    factory['argument'] = argument
    try:
        derived = factory['derive'](cause, kind, arguments)
    finally:
        factory['argument'] = original
    return derived, retained


def derive(inputs, factory, thaw):
    cases = []
    for source in inputs['cases']:
        arguments = thaw(source['arguments'])
        named = dict(zip(arguments[::2], arguments[1::2]))
        input_paths = objects(arguments)
        modeled, retained = tagged(factory, inputs['sources']['cause_model'], source['kind'], arguments)
        frames = [{**frame, 'arguments': [{k: v for k, v in arg.items() if k != 'binding_tag'}
                                         for arg in frame['arguments']]} for frame in modeled['frames']]
        if modeled['guard'] != source['guard'] or frames != source['frames'] or modeled['primary'] != source['primary']:
            raise ValueError('whole unchanged independently qualified direct Value path and predicate')
        private = source['private']
        selectors = []
        if source['kind'] == 'copy':
            roots = [(role, named[role]) for role in ('source', 'target') if type(named[role]) is dict]
            if len(roots) != len(private):
                raise ValueError('complete source/target clone assignment order')
            selectors = [(role, root, copy) for (role, root), copy in zip(roots, private, strict=True)]
        elif source['kind'] == 'scope':
            stages = source['scope_stages']
            if [s['copy_index'] for s in stages] != [p['domain'][1] for p in private]:
                raise ValueError('complete qualified Scope source clone order')
            selectors = [(s['layer'] + '.' + s['name'], named[s['layer']][s['name']], p)
                         for s, p in zip(stages, private, strict=True)]
        elif private:
            token = named['token']
            root_name = re.match(r'([A-Za-z_]\w*)', token)[1]
            if len(private) != 1:
                raise ValueError('one selected reference root clone')
            selectors = [('scope.' + root_name, named['scope'][root_name], private[0])]
        scope_context = next((a['value'] for f in frames if f['function'].endswith('::_validate_type')
                              for a in f['arguments'] if a['role'] == 'context'), None)
        active_scope = None
        if scope_context is not None:
            name = re.fullmatch(r"root '([^']+)'", scope_context)[1]
            active_scope = next((r for r in selectors if r[0].endswith('.' + name)), None)
            if active_scope is None:
                raise ValueError('source failure context selects a qualified Scope root clone')
        bindings, occurrences = {}, []
        for fi, frame in enumerate(modeled['frames']):
            for ai, arg in enumerate(frame['arguments']):
                if arg['kind'] != 'reference':
                    continue
                value = retained[arg['binding_tag']]
                role = arg['role']
                if fi == len(frames) - 1:
                    path = input_paths[id(value)]
                    key = 'input:' + path
                    origin = {'kind': 'supplied_input_node', 'node': path}
                elif role in ('required_keys', 'optional_keys'):
                    key = 'fresh:' + str(fi) + ':' + str(ai)
                    origin = {'kind': 'fresh_key_array', 'source_values': value}
                elif frame['call_site'] in ('scope_keys', 'reference_keys', 'copy_keys'):
                    if id(value) in input_paths or frame['function'].rsplit('::', 1)[-1] != '_keys':
                        raise ValueError('fresh named-argument hash source contract')
                    key = 'fresh:' + str(fi) + ':' + str(ai)
                    origin = {'kind': 'fresh_named_arguments', 'keys': sorted(named), 'statement': 'my %args = @_;'}
                else:
                    if source['kind'] == 'scope':
                        selected = active_scope
                    else:
                        selected = next((r for r in selectors if id(value) in objects(r[1])), None)
                    if selected is None:
                        raise ValueError('every direct core referent has a source-selected private clone')
                    source_role, root, copy = selected
                    paths = objects(root)
                    if id(value) not in paths:
                        raise ValueError('active private clone contains the source-modeled core referent')
                    path = paths[id(value)]
                    key = 'copy:' + str(copy['domain'][1]) + ':' + path
                    origin = {'kind': 'qualified_private_result', 'copy_index': copy['domain'][1],
                              'node': path, 'source_root': source_role, 'api': source['index']}
                descriptor = {'reference_kind': arg['reference_kind'], 'origin': origin,
                              'lifetime': 'held by active source call at this throw; no post-return or numeric identity'}
                if key in bindings and bindings[key] != descriptor:
                    raise ValueError('one core source binding has one kind/origin/lifetime')
                bindings[key] = descriptor
                occurrences.append({'frame': fi, 'argument': ai, 'role': role, 'binding': key})
        distinct = []
        for left, right in itertools.combinations(sorted(bindings), 2):
            a, b = bindings[left], bindings[right]
            if a['reference_kind'] != b['reference_kind']:
                reason = 'different reference kinds'
            elif a['origin']['kind'].startswith('fresh_') or b['origin']['kind'].startswith('fresh_'):
                reason = 'fresh source allocation while supplied arguments and active locals live'
            elif a['origin']['kind'] == b['origin']['kind'] == 'supplied_input_node':
                reason = 'distinct simultaneously retained supplied graph nodes'
            elif (a['origin']['kind'] == b['origin']['kind'] == 'qualified_private_result'
                  and a['origin']['copy_index'] == b['origin']['copy_index']):
                reason = 'distinct nodes of one qualified private result graph'
            else:
                reason = 'finite fresh-copy hypothesis; original provider identity not measured'
            distinct.append({'bindings': [left, right], 'reason': reason})
        cases.append({'mode': source['mode'], 'index': source['index'], 'kind': source['kind'],
                      'guard': source['guard'], 'frames': frames, 'bindings': bindings, 'occurrences': occurrences,
                      'simultaneously_live_distinct': distinct,
                      'domain': [source['mode'], 'api', source['index'], 'direct-source-throw']})
    return {'cases': cases, 'scope': 'Complete finite direct Value core source binding hypotheses; '
            'entry arguments retain supplied referents while active validator locals may hold detached copies. '
            'Original numeric/private/provider/formatter identities, cross-call/post-return lifetimes and '
            'Metadata/nested/helper/parser roles and canonical publication remain open.'}
