"""Join complete source role graphs through explicit source forwarding anchors."""
import hashlib
import json
import re

SCOPE = ('Complete finite visible own source reference roles, qualified private-root holders and '
         'observer caller prefixes at every original source throw view. Graph equality follows '
         'qualified source forwarding/construction, never equal payload alone. Source distinctions '
         'remain finite allocation/copy hypotheses. Original raw addresses, native identity/flags/payload, '
         'opaque provider/framework/formatter/Regexp/CODE identity, global heap census, cold replay '
         'and governed canonical publication remain open.')


def exact(a, b):
    return json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True)


def identity(value):
    raw = json.dumps(value, sort_keys=True, separators=(',', ':')).encode()
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


class Graphs:
    def __init__(self):
        self.nodes, self.roots, self.parents, self.graphs, self.anchors = {}, {}, {}, {}, []

    def add(self, name, encoded):
        seen = {}
        def read(value, path):
            if type(value) in (str, int, type(None)):
                return ('scalar', value)
            tag, body = value
            if tag == 'reference':
                return ('node', seen[body])
            key = (name, path)
            seen[path] = key
            self.parents[key] = key
            self.nodes[key] = {'kind': 'HASH' if tag == 'hash' else 'ARRAY', 'edges': {}}
            for edge, child in ((k, body[k]) for k in sorted(body)) if tag == 'hash' else enumerate(body):
                pointer = path + '/' + str(edge).replace('~', '~0').replace('/', '~1')
                self.nodes[key]['edges'][str(edge)] = read(child, pointer)
            return ('node', key)
        self.roots[name] = read(encoded, '')
        self.graphs[name] = identity(encoded)
        return self.roots[name][1]

    def at(self, name, pointer):
        value = self.roots[name]
        for part in pointer.split('/')[1:]:
            value = self.nodes[value[1]]['edges'][part.replace('~1', '/').replace('~0', '~')]
        if value[0] != 'node':
            raise ValueError('source graph anchor is a reference')
        return value[1]

    def find(self, node):
        while self.parents[node] != node:
            self.parents[node] = self.parents[self.parents[node]]
            node = self.parents[node]
        return node

    def join(self, left, right, expression):
        self.anchors.append({'left': list(left), 'right': list(right), 'source': expression})
        visited, forward, reverse, todo = set(), {}, {}, [(left, right)]
        while todo:
            a, b = todo.pop()
            if (a in forward and forward[a] != b) or (b in reverse and reverse[b] != a):
                raise ValueError('whole source forwarding graph alias agreement')
            forward[a], reverse[b] = b, a
            if (a, b) in visited:
                continue
            visited.add((a, b))
            x, y = self.nodes[a], self.nodes[b]
            if x['kind'] != y['kind'] or set(x['edges']) != set(y['edges']):
                raise ValueError('whole source forwarding graph kind/member agreement')
            first, second = sorted((self.find(a), self.find(b)))
            self.parents[second] = first
            for edge in x['edges']:
                u, v = x['edges'][edge], y['edges'][edge]
                if u[0] != v[0]:
                    raise ValueError('whole source forwarding graph reference agreement')
                if u[0] == 'node':
                    todo.append((u[1], v[1]))
                elif not exact(u[1], v[1]):
                    raise ValueError('whole source forwarding graph scalar agreement')

    def key(self, node):
        return 'graph:' + json.dumps(self.find(node), separators=(',', ':'))

    def reachable(self, roots):
        reached, todo = set(), list(roots)
        while todo:
            node = todo.pop()
            if node in reached:
                continue
            reached.add(node)
            todo.extend(value[1] for value in self.nodes[node]['edges'].values() if value[0] == 'node')
        return {self.key(node) for node in reached}

    def groups(self):
        groups = {}
        for node in sorted(self.nodes):
            groups.setdefault(self.key(node), []).append(list(node))
        if any(len({pair[0] for pair in members}) != len(members) for members in groups.values()):
            raise ValueError('distinct nodes in one qualified source graph cannot collapse')
        return groups


def derive(data, spec):
    d = lambda name: data[name]['hypotheses']
    inp = lambda name: data[name]['inputs']
    operations = {(r['mode'], r['domain'], r['index']): r for r in d('operation')['cases']}
    values = {(r['mode'], r['index']): r for r in d('value')['cases']}
    value_inputs = {(r['mode'], r['index']): r for r in inp('value')['cases']}
    nested = {(r['mode'], v['record_api'], v['phase']): (r, v)
              for r in d('nested')['cases'] for v in r['views']}
    parsers = {(m['mode'], r['domain'][2]): (m, r) for m in d('parser')['modes'] for r in m['cases']}
    hold_modes = {m['mode']: m for m in d('holders')['modes']}
    headers = {m['mode']: m['headers'] for m in inp('holders')['modes']}
    modes = []
    for helper_mode in d('helper')['modes']:
        mode = helper_mode['mode']
        holder = hold_modes[mode]
        holder_views = {tuple(v['domain']): v for v in holder['views']}
        cases = []
        for case in helper_mode['cases']:
            profile = helper_mode['profiles'][case['helper']]
            for helper in case['views']:
                domain = helper['domain']
                kind, index, phase = domain[1:]
                operation = operations[mode, kind, index]
                g = Graphs()
                g.add('helper', profile['graph'])
                old_bindings, old_occurrences, maps, held_roots = {}, [], {}, []
                inactive, copy_lifetimes, facts = [], [], {}
                original_parts = []
                def part(name, frames, occurrences, bindings, frame_map=None):
                    maps[name] = frame_map if frame_map is not None else list(range(len(frames)))
                    old_bindings[name] = bindings
                    original_parts.append({'name': name, 'frames': frames, 'occurrences': occurrences})
                    old_occurrences.extend((name, r) for r in occurrences)
                if kind == 'parses':
                    category = 'parser'
                    parser_mode, parser = parsers[mode, index]
                    frames = list(parser['frames'])
                    part('parser', parser['frames'], parser['occurrences'], parser_mode['bindings'])
                    local_held = [('parser', k) for k in parser['held']]
                    facts = {key: parser[key] for key in ('active_roots', 'inactive_intermediates',
                        'returned_context_delegates', 'returned_api_events', 'lifetime_scope', 'pending')}
                    if parser['pending']:
                        raise ValueError('no pending parser role survives complete integration')
                elif (mode, index, phase) in nested:
                    category = 'nested'
                    record, view = nested[mode, index, phase]
                    g.add('nested', record['joint_source_graph'])
                    frames = list(view['frames'])
                    part('nested', view['frames'], view['occurrences'], record['bindings'])
                    local_held = [('nested', k) for k in view['active_bindings'] + view['source_retained_bindings']]
                    inactive = [('nested', k) for k in view['no_active_own_holder']]
                    copy_lifetimes = view['returned_copy_delegates']
                    facts = {key: view[key] for key in ('active_invocations', 'inactive_invocations', 'event')}
                else:
                    category = 'direct'
                    core, source = values[mode, index], value_inputs[mode, index]
                    boundary = operation['operations'][0]
                    if len(operation['operations']) != 1 or phase != 0:
                        raise ValueError('complete finite direct source operation phase')
                    g.add('operation', operation['source_input_graph'])
                    if (core['frames'][-1]['function'] != boundary['frames'][0]['function']
                            or not exact(core['frames'][-1]['arguments'], boundary['frames'][0]['arguments'])):
                        raise ValueError('complete direct public frame forwarding overlap')
                    frames = core['frames'][:-1] + boundary['frames']
                    part('value', core['frames'], core['occurrences'], core['bindings'])
                    local_held = [('value', k) for k in core['bindings']]
                    named = {source['arguments'][1][i]: i + 1 for i in range(0, len(source['arguments'][1]), 2)}
                    for number, private in enumerate(source['private']):
                        copy_index = private['domain'][1]
                        before, result = 'copy-input:' + str(copy_index), 'copy-result:' + str(copy_index)
                        g.add(before, private['before']); g.add(result, private['result'])
                        if source['kind'] == 'copy':
                            role = [r for r in ('source', 'target')
                                    if isinstance(source['arguments'][1][named[r]], list)][number]
                            pointer = '/' + str(named[role])
                        elif source['kind'] == 'scope':
                            stage = source['scope_stages'][number]
                            pointer = '/' + str(named[stage['layer']]) + '/' + stage['name']
                        else:
                            root = re.match(r'([A-Za-z_]\w*)', source['arguments'][1][named['token']])[1]
                            pointer = '/' + str(named['scope']) + '/' + root
                        g.join(g.at(before, ''), g.at('operation', pointer), 'dclone input from ' + pointer)
                        active = source['kind'] != 'scope' or number == len(source['private']) - 1
                        if active:
                            held_roots.append(g.at(result, ''))
                        copy_lifetimes.append({'copy_index': copy_index, 'input_anchor': pointer,
                            'result_pool': result, 'active_source_holder': active,
                            'activation': 'copy delegate returned; source variable holds result' if active else
                                          'earlier scope iteration ended; no private result holder asserted'})
                    facts = {'guard': core['guard'], 'private_scope': 'Complete original Value private calls; copy delegates inactive. Current copy/reference variables or final failing scope root establish result holders; no external object death claimed.'}
                # The complete helper path follows the installed operation wrapper.
                offset = len(frames)
                part('helper', helper['frames'], helper['occurrences'], helper_mode['bindings'],
                     list(range(offset, offset + len(helper['frames']))))
                frames += helper['frames']
                local_held += [('helper', k) for k in helper['held_bindings']]
                # Join helper source construction to the active outer API arguments.
                if category != 'parser':
                    outer_api = record['scope_api'] if category == 'nested' else index
                    actual = g.at('nested', '/0') if category == 'nested' else g.at('operation', '')
                    active = [(i, r) for i, r in enumerate(profile['named_activations']) if r['index'] == outer_api]
                    if active:
                        i, call = active[0]
                        if call['activation'] != 'active':
                            raise ValueError('helper forwarding selects active named operation')
                        g.join(actual, g.at('helper', '/1/' + str(i)), 'active named helper operation arguments')
                    elif profile['source_recipe']['call_shape']['completed']:
                        g.join(actual, g.at('helper', '/3'), 'direct callback arguments and retained returned reference')
                # Every old operation slot joins its exact already qualified source frame.
                for oi, boundary in enumerate(operation['operations']):
                    if boundary['domain'][3] != phase:
                        continue
                    starts = [i for i, f in enumerate(frames) if f['function'] == boundary['frames'][0]['function']
                              and [x['function'] for x in frames[i:i+4]] == [x['function'] for x in boundary['frames']]]
                    if len(starts) != 1:
                        raise ValueError('one complete source operation frame boundary')
                    name = 'operation:' + str(oi)
                    part(name, boundary['frames'], boundary['occurrences'], boundary['bindings'],
                         list(range(starts[0], starts[0] + 4)))
                translated, descriptors = {}, {}
                def code_key(expression):
                    return 'saved:' + expression
                def resolve(component, old):
                    label = component + '/' + old
                    if label in translated:
                        return translated[label]
                    descriptor = old_bindings[component][old]
                    origin = descriptor['origin']; family = origin['kind']
                    if component.startswith('operation:'):
                        oi = int(component.split(':')[1]); boundary = operation['operations'][oi]
                        # All operation slots were independently assigned by the more complete source model.
                        candidates = {r['binding'] for r in boundary['occurrences'] if r['binding'] == old}
                        slots = [r for r in boundary['occurrences'] if r['binding'] in candidates]
                        targets = []
                        for r in slots:
                            fi = maps[component][r['frame']]
                            for source_component, occurrence in old_occurrences:
                                if not source_component.startswith('operation:') and maps[source_component][occurrence['frame']] == fi and occurrence['argument'] == r['argument']:
                                    targets.append(resolve(source_component, occurrence['binding']))
                        if category == 'direct' and not targets:
                            if family == 'fresh_caller_array':
                                key = 'caller:api:' + str(index)
                            elif family == 'saved_lookup':
                                key = code_key(origin['expression'])
                            elif family == 'qualified_input_node':
                                key = g.key(g.at('operation', origin['path']))
                            else:
                                raise ValueError('direct operation source binding resolves completely')
                        else:
                            if not targets or len(set(targets)) != 1:
                                raise ValueError('complete operation roles agree with joined source aliases')
                            key = targets[0]
                    elif component == 'helper':
                        if family == 'qualified_helper_source_node':
                            key = g.key(g.at('helper', origin['node']))
                        elif family == 'observer_helper_caller_snapshot':
                            key = 'caller:helpers:' + str(origin['helper'])
                        elif family == 'observer_api_caller_snapshot':
                            key = 'caller:api:' + str(origin['api'])
                        elif family == 'source_code_handle' and old.startswith('saved-api:'):
                            key = code_key(origin['expression'])
                        elif old == 'saved-public-subtest':
                            key = code_key('$subtest')
                        else:
                            key = 'helper:' + old
                    elif component == 'value':
                        if family == 'supplied_input_node':
                            key = g.key(g.at('operation', origin['node']))
                        elif family == 'qualified_private_result':
                            key = g.key(g.at('copy-result:' + str(origin['copy_index']), origin['node']))
                        else:
                            key = 'value:' + old
                    elif component == 'nested':
                        if family == 'joint_source_node':
                            key = g.key(g.at('nested', origin['node']))
                        elif family == 'observer_caller_snapshot':
                            key = 'caller:api:' + str(origin['api'])
                        elif family == 'saved_lookup':
                            key = code_key(origin['expression'])
                        else:
                            key = 'nested:' + old
                    else:
                        if family == 'retained_context_protocol_caller':
                            key = 'caller:' + ('api' if origin['holder'] == '@api' else 'copies') + ':' + str(origin['index'])
                        elif family == 'observer_caller_snapshot':
                            key = 'caller:parses:' + str(origin['parse_index'])
                        elif family == 'saved_lookup':
                            key = code_key(origin['expression'])
                        else:
                            key = 'parser:' + old
                    translated[label] = key
                    existing = descriptors.setdefault(key, {'reference_kind': descriptor['reference_kind'], 'origins': []})
                    if existing['reference_kind'] != descriptor['reference_kind']:
                        raise ValueError('complete source joined reference kind')
                    existing['origins'].append({'component': component, 'binding': old, 'source': origin})
                    return key
                for component, occurrence in old_occurrences:
                    resolve(component, occurrence['binding'])
                for component, old in local_held + inactive:
                    resolve(component, old)
                joined = {}
                for component, occurrence in old_occurrences:
                    fi, ai = maps[component][occurrence['frame']], occurrence['argument']
                    key = resolve(component, occurrence['binding'])
                    slot = (fi, ai)
                    row = joined.setdefault(slot, {'frame': fi, 'argument': ai,
                        'role': frames[fi]['arguments'][ai]['role'], 'binding': key, 'provenance': []})
                    if row['binding'] != key:
                        raise ValueError('one joined source referent per overlapping frame operand')
                    row['provenance'].append({'component': component, 'frame': occurrence['frame'], 'argument': ai})
                held = {resolve(component, key) for component, key in local_held}
                groups = g.groups()
                # All graph referents reachable from qualified held source roots remain held.
                for key in list(held):
                    if key in groups:
                        held_roots.append(tuple(groups[key][0]))
                held |= g.reachable(held_roots)
                for key, members in groups.items():
                    if key in held:
                        descriptors.setdefault(key, {'reference_kind': g.nodes[tuple(members[0])]['kind'], 'origins': []})
                prefixes = holder_views[tuple(domain)]['held_prefixes']
                count = holder_views[tuple(domain)]['population']
                caller_set = set()
                for key in held:
                    if key.startswith('caller:'):
                        _, table, number = key.split(':')
                        if not any(r['table'] == table and r['first'] <= int(number) < r['end'] for r in prefixes):
                            raise ValueError('every source caller resolves inside complete held prefix')
                        caller_set.add(key)
                extra = sorted(held - caller_set)
                codes = sorted(k for k in extra if descriptors[k]['reference_kind'] == 'CODE')
                total = count + len(extra)
                failed = [i for i in range(headers[mode]['helpers'][case['helper']]['api_start'],
                                           headers[mode]['helpers'][case['helper']]['api_end']) if headers[mode]['api'][i]['accepted'] == 0]
                active_api = [record['scope_api'], record['capture_api']] if category == 'nested' and phase == 0 else [record['scope_api']] if category == 'nested' else [index] if category == 'direct' else []
                returned = [i for i in range(headers[mode]['helpers'][case['helper']]['api_start'],
                                            headers[mode]['helpers'][case['helper']]['api_end']) if headers[mode]['api'][i]['accepted'] == 1]
                cases.append({'domain': domain, 'category': category, 'event': helper['event'],
                    'frames': frames, 'occurrences': [joined[k] for k in sorted(joined)],
                    'bindings': descriptors, 'component_frame_maps': maps, 'source_binding_aliases': dict(sorted(translated.items())),
                    'graphs': g.graphs, 'graph_anchors': g.anchors, 'graph_groups': groups,
                    'held_source_bindings': extra, 'retained_caller_prefixes': prefixes,
                    'trial_caller_aliases': holder_views[tuple(domain)]['trial_aliases'],
                    'no_active_own_holder': sorted(resolve(c, k) for c, k in inactive),
                    'source_distinctions': {'relation': 'all distinct held member pairs except CODE/CODE',
                        'population': total, 'pairs': total * (total - 1) // 2 - len(codes) * (len(codes) - 1) // 2,
                        'opaque_CODE_members': codes},
                    'lifetime': {'active_api_invocations': active_api, 'inactive_failed_api_invocations': [i for i in failed if i not in active_api],
                        'successful_returned_api_invocations': returned, 'private_results': copy_lifetimes,
                        'qualified_source_phase_facts': facts,
                        'helper_result_holders': profile['returned_result_holders'],
                        'scope': 'Own source holders and call state at this event; returned calls do not establish payload death or external/provider retention.'},
                    'external_interval': helper['opaque_framework_interval']})
        modes.append({'mode': mode, 'views': cases})
    return {'modes': modes, 'scope': SCOPE,
            'conserved_models': {name: row['hypotheses'] for name, row in spec['models'].items()}}
