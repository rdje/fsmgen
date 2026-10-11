"""Independent source-first reconstruction; never imports the candidate producer."""
import argparse
from collections import defaultdict
from common import *

SUCCESS = 'PASS independent complete original raw semantic links; inherited bodies and native/private limits conserve.\n'


def same(left, right):
    return canonical(left) == canonical(right)


def structured(value):
    # This is the explicitly qualified predecessor's JSON representation.
    return pin(json.dumps(value, sort_keys=True).encode())


def table(rows, key):
    result = {key(row): row for row in rows}
    need(len(result) == len(rows), 'unique complete independent source association')
    return result


def follow(value, path):
    for part in path:
        value = value[part]
    return value


def source_position(phase, tail):
    positions = phase['complete_own_positions']
    if tail[:2] == ['own', 'operations']:
        return positions['operations'][tail[2]][tail[4]]
    if tail[:2] == ['public', 'own_eval_boundaries']:
        return positions['operations'][tail[2]][tail[3]]
    need(tail[0] in ('own', 'public') and tail[1] in ('core', 'helper', 'body', 'entry'),
         'complete declared own/public source path')
    return positions[tail[1] + '_positions'][tail[2]]


def check_addresses(raw, parsed, phase, class_phase, public_phase, coordinate, source, holders, numbers):
    domain = phase['domain']
    need(same(domain, source['domain']) and same(domain, holders['domain']) and same(domain, numbers['domain']),
         'complete address source/holder/numeric lifetime domain')
    need(phase['whole_class_phase'] == structured(class_phase)
         and phase['whole_public_phase'] == structured(public_phase)
         and phase['whole_coordinate_phase'] == structured(coordinate)
         and phase['whole_source_view'] == holders['whole_prior_view'] == structured(source),
         'complete address class/public/coordinate/source phase bridges')
    need(numbers['whole_source_view'] == structured(source)
         and numbers['whole_holder_view'] == structured(holders)
         and numbers['whole_parsed_phase'] == structured(phase), 'complete numeric source and holder bridges')
    frames = {f['frame_index']: f for f in parsed['segments'] if f['kind'] == 'frame'}
    mappings = table(phase['frames'], lambda f: f['source_frame'])
    body = raw['body'].encode()
    for mapping in mappings.values():
        sf = source['frames'][mapping['source_frame']]
        actual = frames[mapping['frame_index']]
        need(mapping['whole_source_frame'] == structured(sf) and sf['function'] == actual['function']
             and mapping['source_arguments'] == len(sf['arguments']), 'whole address source-frame/function/argument bridge')
    visible, unaddressed = [], []
    for occurrence in source['occurrences']:
        mapping = mappings[occurrence['frame']]
        if occurrence['argument'] >= mapping['visible_arguments']:
            unaddressed.append(dict(source=occurrence, frame_index=mapping['frame_index'], category='hidden_reference', token=None))
            continue
        token = frames[mapping['frame_index']]['arguments'][occurrence['argument']]
        if token['kind'] == 'regex_display':
            unaddressed.append(dict(source=occurrence, frame_index=mapping['frame_index'], category='regex_display', token=token))
            continue
        binding = occurrence['binding']
        held = binding in holders['held_source_bindings']
        if binding.startswith('caller:'):
            _, name, number = binding.split(':')
            held = held or any(p['table'] == name and p['first'] <= int(number) < p['end'] for p in source['retained_caller_prefixes'])
        need(token['kind'] == 'reference' and held and body[token['start']:token['end']] == token['raw'].encode()
             and body[token['hex_span'][0]:token['hex_span'][1]] == token['hex'].encode(),
             'whole visible address operand bytes and simultaneous source holder')
        visible.append(dict(source=occurrence, frame_index=mapping['frame_index'], reference_kind=token['reference_kind'],
            display_class=token['display_class'], raw=token['raw'], span=[token['start'], token['end']],
            hex=token['hex'], hex_span=token['hex_span'], numeric_key=hex(int(token['hex'], 16))))
    need(same(visible, numbers['references']) and same(unaddressed, numbers['unaddressed_source_operands']),
         'whole complete visible and opaque address-source operand allocation')
    groups = defaultdict(list)
    for index, row in enumerate(visible):
        groups[row['source']['binding']].append(index)
    aliases = [dict(binding=key, members=members, numeric_key=visible[members[0]]['numeric_key'])
               for key, members in sorted(groups.items())]
    need(same(aliases, numbers['source_alias_classes']), 'whole explicit source alias class allocation')
    pairs = []
    for left in range(len(visible)):
        for right in range(left + 1, len(visible)):
            a, b = visible[left], visible[right]
            relation = ('equal' if a['source']['binding'] == b['source']['binding'] else
                        'opaque_CODE' if a['reference_kind'] == b['reference_kind'] == 'CODE' else 'distinct')
            equal = a['numeric_key'] == b['numeric_key']
            need((relation != 'equal' or equal) and (relation != 'distinct' or not equal),
                 'qualified simultaneous numeric alias/distinction relation without CODE identity promotion')
            pairs.append(dict(left=left, right=right, source_relation=relation, numeric_equal=equal))
    need(same(pairs, numbers['pairs']), 'whole numeric pair relation allocation')


def reconstruct(data):
    raw_rows = table([(m['mode'], name, r) for m in data['raw']['inventories']
        for name, domain in m['domains'].items() for r in domain['nonempty']], lambda x: (x[0], x[1], x[2]['index']))
    classes = table([(mi, ci, m['mode'], c) for mi, m in enumerate(data['classes']['modes'])
        for ci, c in enumerate(m['cases'])], lambda x: (x[2], x[3]['domain'], x[3]['index']))
    qualified = table([(m['mode'], c) for m in data['frames']['modes'] for c in m['cases']],
                      lambda x: (x[0], x[1]['domain'], x[1]['index']))
    coordinates = table(data['coordinates']['matches'], lambda x: (x['mode'], x['domain'], x['index']))
    parsed = table([(m['mode'], name, r) for m in data['operands']['modes']
        for name, domain in m['domains'].items() for r in domain['records']], lambda x: (x[0], x[1], x[2]['index']))
    views = {name: table([v for m in data[name]['modes'] for v in m['views']], lambda x: tuple(x['domain']))
             for name in ('source_address', 'holders')}
    views['numbers'] = table(data['numbers']['views'], lambda x: tuple(x['domain']))
    opaque = table(data['headers']['complete_opaque_allocation'], lambda x: tuple(x['record']))
    need(all(set(t) == set(raw_rows) for t in (classes, qualified, coordinates, parsed, opaque)),
         'complete original cross-product association record membership')
    headers = {}
    for kind in ('source_headers', 'public_headers', 'loads'):
        groups = defaultdict(list)
        for header in data['headers'][kind]:
            a = header['allocation']; groups[(*a['record'], a['phase'])].append(header)
        headers[kind] = groups
    modes, rows, allocation, used = [], [], [], set()
    for mode in data['raw']['inventories']:
        domains, alloc_domains = {}, {}
        for name, domain in mode['domains'].items():
            records = []
            alloc_domains[name] = dict(population=domain['population'], empty=domain['empty_string_members'],
                                      nonempty=[r['index'] for r in domain['nonempty']])
            for raw in domain['nonempty']:
                key = mode['mode'], name, raw['index']
                mi, ci, _, source = classes[key]
                proof, coord, operand = qualified[key][1], coordinates[key], parsed[key][2]
                frames = [s for s in raw['segments'] if s['kind'] == 'frame']
                need(raw['body'].encode() == b''.join(s['raw'].encode() for s in raw['segments'])
                     and pin(raw['body'].encode()) == raw['body_identity'] == proof['original_whole_body']
                     and same(source['exception'], proof['exception'])
                     and raw['body'].startswith(source['exception']['primary'] + '\n'),
                     'whole complete original stack and source first cause')
                need(len(source['phases']) == len(proof['phases']) == len(coord['phases']) == len(operand['phases']),
                     'complete independent ordered phase membership')
                phases, edges = [], []
                for pi, src in enumerate(source['phases']):
                    q, cp, op = proof['phases'][pi], coord['phases'][pi], operand['phases'][pi]
                    dk = (*key, pi); used.add(dk)
                    need(type(src['phase']) is int and src['phase'] == q['phase'] == op['phase'] == pi
                         and src['family'] == q['family'] == cp['family']
                         and src['inferred_class'] == q['inferred_class'] == 'unblessed_nonreference_scalar'
                         and same(src['guard_source'], q['guard_source']), 'whole source guard/class and throw-phase order')
                    own_headers, public, loads = (headers[kind][dk] for kind in ('source_headers', 'public_headers', 'loads'))
                    ids, header_edges = set(), []
                    for h in own_headers:
                        a, sh = h['allocation'], h['source_header']; path = a['source_path']
                        need(path[:6] == ['modes', mi, 'cases', ci, 'phases', pi]
                             and a['frame_position'] == source_position(q, path[6:])
                             and same(h['original_frame'], frames[a['frame_position']]), 'whole own header source/caller/phase/frame bridge')
                        model = follow(data['classes'], path)
                        args = [data['expressions']['operands'][identifier] for identifier in sh['source_argument_ids']]
                        need(model['function'] == sh['expression']['function'] == h['joined']['function']
                             and same([a['source']['input'] for a in args], model['arguments']),
                             'whole source function and complete ordered argument expression bridge')
                        ids.update(sh['source_argument_ids'])
                        header_edges.append(dict(source_path=path, frame_index=a['frame_position'], function=model['function'],
                            whole_frame=pin(canonical(frames[a['frame_position']])), whole_header=pin(canonical(h)),
                            argument_ids=sh['source_argument_ids'], arguments=args))
                    for h in public:
                        ids.update(h['allocation']['complete_argument_ids'])
                    for h in (*public, *loads):
                        need(same(h['original_frame'], frames[h['allocation']['frame_position']]),
                             'whole public header and do-load raw frame bridge')
                    parsed_frames = {f['frame_index']: f for f in operand['segments'] if f['kind'] == 'frame'}
                    for caller in cp['callers_inner_to_outer']:
                        index = caller['frame_index']; selection = caller['selection']; binding = caller['source_binding']
                        need(caller['whole_segment'] == structured(frames[index])
                             and binding['callee'] == parsed_frames[index]['function'], 'whole source caller/raw coordinate frame bridge')
                        for link in binding['model_links']:
                            need(follow(src['own'], link)['function'] == binding['callee'], 'whole coordinate source role/function bridge')
                        if selection is not None:
                            need(selection['reported_filename'] == frames[index]['path']
                                 and selection['reported_line'] == frames[index]['line']
                                 and selection['reported_filename'] in selection['all_filename_alternatives']
                                 and all(selection['all_line_alternatives'][label] == frames[index]['line']
                                         for label in selection['matching_line_labels']), 'whole source coordinate alternatives without path normalization')
                    sa, holder, number = (views[kind][dk] for kind in ('source_address', 'holders', 'numbers'))
                    check_addresses(raw, operand, op, q, proof['public']['phases'][pi], cp, sa, holder, number)
                    phases.append(dict(domain=list(dk), source_class_frame=src, qualified_class_frame=q, coordinate=cp,
                        source_headers=own_headers, public_headers=public, loads=loads,
                        source_arguments={identifier: data['expressions']['operands'][identifier] for identifier in sorted(ids)},
                        parsed_address=op, source_address=sa, holders=holder, numbers=number))
                    edges.append(dict(domain=list(dk),
                        classification={k: src[k] for k in ('phase', 'family', 'guard_source', 'inferred_class', 'native_class')},
                        headers=header_edges, public_headers=public, loads=loads, callers=cp['callers_inner_to_outer'],
                        coordinate_boundary={k: v for k, v in cp.items() if k != 'callers_inner_to_outer'},
                        address=dict(numbers=number, whole_source=pin(canonical(sa)), whole_holders=pin(canonical(holder)),
                                     whole_parsed=pin(canonical(op))), opaque=q['complete_own_positions']['opaque_framework']))
                forwarding = None
                relation = proof['forwarded']
                if relation is not None:
                    child_key = mode['mode'], 'api', relation['capture_api']; child = raw_rows[child_key][2]
                    prefix = source['phases'][-1]['guard_source']['prefix'] + relation['context'] + ' has invalid resolved type: ' + child['body'] + '\n'
                    need(raw['body'].startswith(prefix) and pin(prefix.encode()) == relation['entire_outer_prefix']
                         and child['body_identity'] == relation['inner_body'] and len(phases) == 2
                         and source['phases'][0]['family'] == 'metadata' and source['phases'][1]['family'] == 'value',
                         'whole nested inner operand and new outer guard/phase association')
                    trace = raw['body'][len(prefix):]
                    need(pin(trace.encode()) == relation['new_outer_trace'], 'whole new outer trace after complete inner cause')
                    forwarding = dict(source_relation=relation, inner_record=list(child_key), outer_record=list(key),
                        whole_inner_body=child['body'], whole_outer_prefix=prefix, whole_new_outer_trace=trace)
                records.append(dict(record=list(key), original=raw, source_case={k: v for k, v in source.items() if k != 'phases'},
                    qualified_case={k: v for k, v in proof.items() if k != 'phases'}, observer_coordinate=coord['observer_caller'],
                    opaque_allocation=opaque[key], parsed_operands=operand, phases=phases, forwarding=forwarding))
                rows.append(dict(record=list(key), stack=dict(body=raw['body_identity'],
                    segments=[pin(canonical(s)) for s in raw['segments']], frames=[pin(canonical(f)) for f in frames]),
                    first_cause=source['exception'], context=raw['context'], observer=coord['observer_caller'], phases=edges,
                    opaque=dict(allocation=opaque[key], lexemes=raw['opaque_lexemes'], qualified_frames=proof['opaque_frames']), forwarding=forwarding))
            domains[name] = dict(population=domain['population'], empty_string_members=domain['empty_string_members'], records=records)
        modes.append(dict(mode=mode['mode'], domains=domains)); allocation.append(dict(mode=mode['mode'], domains=alloc_domains))
    need(all(set(v) == used for v in views.values()) and all(set(v) <= used for v in headers.values()),
         'whole complete source phase allocation without borrowed members')
    return modes, dict(scope=SCOPE, allocation=allocation, original_unknowns=data['headers']['original_unknowns'],
        inherited_scopes={role: {k: value[k] for k in ('scope', 'role', 'unresolved', 'original_unmeasured') if k in value}
                          for role, value in data.items()}, records=rows)


def qualify(candidate):
    baseline = inherited()
    need(set(candidate) == set(baseline) | {'semantic_links'}, 'complete proposed and inherited product field population')
    projection = {k: v for k, v in candidate.items() if k != 'semantic_links'}
    need(same(projection, baseline), 'every complete inherited component conserves before new semantic judgement')
    modes, expected = reconstruct(inputs())
    need(same(projection['modes'], modes), 'independent complete source-first reconstruction of the entire inherited association product')
    actual = candidate['semantic_links']
    need(set(actual) == set(expected), 'semantic complete link field population')
    need(same(actual['scope'], expected['scope']) and same(actual['original_unknowns'], expected['original_unknowns'])
         and same(actual['inherited_scopes'], expected['inherited_scopes']), 'semantic scope and original native/private boundary')
    need(same(actual['allocation'], expected['allocation'])
         and same([r['record'] for r in actual['records']], [r['record'] for r in expected['records']]), 'semantic complete original member allocation')
    for a, e in zip(actual['records'], expected['records'], strict=True):
        need(set(a) == set(e), 'semantic complete record field population')
        for field, cause in (('stack', 'semantic full stack and complete ordered body'), ('first_cause', 'semantic complete source first cause'),
                             ('context', 'semantic complete original context'), ('observer', 'semantic observer caller association'),
                             ('opaque', 'semantic complete opaque allocation'), ('forwarding', 'semantic whole nested inner/outer cause association')):
            need(same(a[field], e[field]), cause)
        need(same([p['domain'] for p in a['phases']], [p['domain'] for p in e['phases']]), 'semantic complete ordered throw-phase allocation')
        for ap, ep in zip(a['phases'], e['phases'], strict=True):
            need(set(ap) == set(ep), 'semantic complete phase field population')
            for field, cause in (('classification', 'semantic whole source guard class and phase'),
                ('headers', 'semantic complete ordered source header and arguments'), ('public_headers', 'semantic complete public header association'),
                ('loads', 'semantic whole source do and diagnostic load association'), ('callers', 'semantic source caller and coordinate association'),
                ('coordinate_boundary', 'semantic complete coordinate and opaque boundary'), ('address', 'semantic whole simultaneous address/holder association'),
                ('opaque', 'semantic phase opaque boundary')):
                need(same(ap[field], ep[field]), cause)
    return dict(scope=SCOPE, inherited=pin(canonical(projection)), links=pin(canonical(expected)),
        independence='Independent source-first reconstruction imports no candidate constructor or link producer. Qualified original raw/class/frame/header/coordinate/address products and their earlier source models are shared assumptions. Separate native whole-body custody is a distinct leg; original native/private identities remain unmeasured.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('candidate')
    args = parser.parse_args()
    raw = gzip.decompress(local(args.candidate).read_bytes())
    value = json.loads(raw); need(raw == canonical(value), 'whole canonical semantic candidate before judgement')
    qualify(value)
    print(SUCCESS, end='')
