"""Independent token lexer, source spelling and complete allocation reconstruction."""
import re
from common import CLASS, HEADERS, SCOPE, canonical, inputs, need, pin, read, same


def spelling(value):
    if value is None:
        return 'undef'
    text = str(value)
    if re.fullmatch(r'-?[0-9]+(?:\.[0-9]*)?(?:[eE][+-]?[0-9]+)?', text):
        return text
    shortened = len(text) > 64
    visible = text[:61] if shortened else text
    units = []
    for character in visible:
        code = ord(character)
        if code < 32 or code > 126:
            units.append('\\x{' + format(code, 'x') + '}')
        else:
            units.append(('\\' if character in '$@"\\' else '') + character)
    return '"' + ''.join(units) + '"' + ('...' if shortened else '')


def alternatives(binding, product):
    source = binding['source']['qualification']
    result = []
    for identifier in binding['current_construction_cases']:
        evidence = product['current_construction_cases'][identifier]
        case = evidence['case']
        if evidence['kind'] != 'predicate' and case['limit'] != 64:
            continue
        if evidence['kind'] == 'predicate':
            token = spelling(source['string_value'])
        elif evidence['kind'] == 'scalar':
            need(same(case['value'], source['value']), 'independent entire scalar recipe/source equality')
            token = spelling(source['value'])
        else:
            body = source['authored']['body']
            need(case['body'] == body, 'independent entire regex recipe/source equality')
            token = 'qr(' + (body[:61] if len(body)>64 else body) + ')' + ('...' if len(body)>64 else '')
            token += 'u' if case['constructor'] == 'upgraded-string' else ''
        if token not in result:
            result.append(token)
    return result


def lex(text, function):
    start = function + '('
    need(text.startswith(start) and text.endswith(')'), 'whole source-qualified call framing')
    tail = text[len(start):-1]
    tokens = []
    cursor = 0
    while cursor < len(tail):
        opening = cursor
        if tail[cursor] == '"':
            cursor += 1
            while cursor < len(tail):
                char = tail[cursor]
                cursor += 1
                if char == '\\':
                    cursor += 1
                elif char == '"':
                    break
            else:
                raise ValueError('whole source-qualified literal argument header')
            if tail[cursor:cursor+3] == '...':
                cursor += 3
        elif tail.startswith('qr(', cursor):
            closing = tail.find(')', cursor+3)
            need(closing >= 0, 'whole source-qualified literal argument header')
            cursor = closing+1
            if tail[cursor:cursor+3] == '...':
                cursor += 3
            if tail[cursor:cursor+1] == 'u':
                cursor += 1
        else:
            stop = tail.find(', ', cursor)
            cursor = len(tail) if stop < 0 else stop
        token = tail[opening:cursor]
        need(token != '', 'whole source-qualified complete argument population')
        tokens.append((token, len(start)+opening, len(start)+cursor))
        if cursor < len(tail):
            need(tail[cursor:cursor+2] == ', ', 'whole source-qualified argument separator')
            cursor += 2
            need(cursor < len(tail), 'whole source-qualified complete argument population')
    return tokens


def header(text, function, ids, product, receiver=None):
    if function == 'eval {...}':
        need(ids == [] and text == function, 'whole source-qualified eval marker')
        return dict(function=function, arguments=[], hidden_argument_ids=[], complete_call=text,
                    original_meaning='source eval boundary only; private implementation unmeasured')
    parsed = lex(text, function)
    rows = []
    if receiver is not None:
        need(parsed and parsed[0][0] == receiver, 'whole opaque public receiver conservation')
        token, start, end = parsed.pop(0)
        rows.append(dict(source_role='whole opaque public receiver', token=token,
                         interval_bytes=[len(text[:start].encode()),len(text[:end].encode())],
                         original_meaning='contents/class/identity/private implementation unmeasured'))
    if len(ids)>8:
        need(parsed and parsed[-1][0] == '...', 'whole source-qualified argument-count marker')
        parsed.pop()
    need(len(parsed) == min(len(ids),8), 'whole source-qualified complete argument population')
    for identifier, (token, start, end) in zip(ids[:8], parsed, strict=True):
        binding = product['operands'][identifier]
        source = binding['source']
        value = source['qualification']
        if value['kind'] == 'source reference role and kind only':
            prefix = value['reference_kind']
            if source['input'].get('display_class') is not None:
                prefix = source['input']['display_class'] + '=' + prefix
            need(token.startswith(prefix+'(0x') and token.endswith(')') and
                 token[len(prefix)+3:-1] != '' and
                 all(c in '0123456789abcdef' for c in token[len(prefix)+3:-1]),
                 'whole source-qualified reference kind/token syntax')
            options = None
            meaning = 'Complete original encoded interval and source kind/role only; address/referent/receiver/native identity unmeasured.'
        else:
            options = alternatives(binding, product)
            need(token in options, 'whole source-qualified literal argument header')
            meaning = ('Complete known source value under an explicit qualifying current grammar; original flags/settings/encoding/provider remain unmeasured.'
                       if value['kind'] != 'qualified whole authored regex' else
                       'Complete authored regex value and full qualified constructor alternatives; matched original encoded spelling does not measure original flags/encoding/provider.')
        rows.append(dict(argument_id=identifier, source=source, token=token,
                         interval_bytes=[len(text[:start].encode()),len(text[:end].encode())],
                         qualified_current_alternatives=options, original_meaning=meaning))
    rebuilt = function + '(' + ', '.join(([receiver] if receiver is not None else []) +
               [row['token'] for row in rows if 'argument_id' in row] + (['...'] if len(ids)>8 else [])) + ')'
    need(rebuilt == text, 'whole source-generated complete original call equality')
    return dict(function=function, arguments=rows, hidden_argument_ids=ids[8:], complete_call=rebuilt,
                qualifying_profile=product['current_profile'],
                original_meaning='Finite encoded compatibility and complete opaque conservation only; original settings and native/private attribution unmeasured.')


def selection(product):
    source = read(CLASS/'source-models.json')
    prior = read(CLASS/'proofs.json')['full_prior_public_join']
    own = {(mode['mode'],case['domain'],case['index']):case
           for mode in prior['own_join']['contexts'] for case in mode['cases']}
    public = {(mode['mode'],case['domain'],case['index']):case
              for mode in prior['modes'] for case in mode['cases']}
    operands = {tuple(v['source']['path']):key for key,v in product['operands'].items()}
    paths, virtual, loads = {}, [], []
    for mi, mode in enumerate(source['modes']):
        for ci, case in enumerate(mode['cases']):
            key = mode['mode'], case['domain'], case['index']
            for pi, phase in enumerate(case['phases']):
                root = ['modes',mi,'cases',ci,'phases',pi]
                positions = own[key]['phases'][pi]
                for group in ('core','helper','body','entry'):
                    for fi, _ in enumerate(phase['own'][group]):
                        paths[tuple(root+['own',group,fi])] = (key,pi,positions[group+'_positions'][fi])
                for oi, operation in enumerate(phase['own']['operations']):
                    for fi, _ in enumerate(operation['frames']):
                        paths[tuple(root+['own','operations',oi,'frames',fi])] = (key,pi,positions['operations'][oi][fi])
                for group in ('body','entry'):
                    for fi, _ in enumerate(phase['public'][group]):
                        paths[tuple(root+['public',group,fi])] = (key,pi,positions[group+'_positions'][fi])
                for oi, frames in enumerate(phase['public']['own_eval_boundaries']):
                    for fi, _ in enumerate(frames):
                        paths[tuple(root+['public','own_eval_boundaries',oi,fi])] = (key,pi,positions['operations'][oi][fi])
                interface = phase['public']
                need(interface['public_path'] == ['Test::Builder::subtest','Test::More::subtest'],
                     'independent complete public source symbols')
                virtual.append(dict(id=pin(canonical(root+['public','public_path',0]))['sha256'],
                    source_path=root+['public','public_path',0],record=list(key),phase=pi,
                    frame_position=public[key]['phases'][pi]['public_positions'][0],
                    function='Test::Builder::subtest',
                    complete_argument_ids=[operands[tuple(root+['public','public_name'])],operands[tuple(root+['public','callback'])]],
                    receiver_role=interface['receiver'],profile=product['current_profile'],
                    meaning='Full source/public name and callback-kind expression with a whole opaque receiver parameter; no original private/native receiver meaning.'))
                for branch in ('own','public'):
                    loads.append(dict(source_path=root+[branch,'load'],record=list(key),phase=pi,
                        frame_position=positions['load_position'],diagnostic_marker=phase[branch]['load'],
                        source_operator='do',diagnostic_marker_is_source_operator=False))
    need(set(paths) == {tuple(h['path']) for h in product['headers']}, 'independent complete source/header role population')
    allocated=[]
    for h in product['headers']:
        key,phase,position=paths[tuple(h['path'])]
        allocated.append(dict(header_id=h['id'],source_path=h['path'],record=list(key),phase=phase,frame_position=position))
    return dict(scope=SCOPE,source_headers=allocated,public_headers=virtual,loads=loads,
                source_expression=pin((HEADERS/'headers.json').read_bytes()),
                original_unknowns=product['original_unmeasured'],raw_comparison='not performed by this source/role selection',
                inputs={str(p):pin(p.read_bytes()) for p in inputs()})


def reconstruct(native, selected, product):
    need(same(selected, selection(product)), 'whole independent original header source selection')
    previous = read(CLASS/'proofs.json')['full_prior_public_join']
    receivers = {(m['mode'],c['domain'],c['index'],p['phase']):p['public_header_compatibility']['receiver_opaque']
                 for m in previous['modes'] for c in m['cases'] for p in c['phases']}
    records = {(m['mode'],domain,r['index']):r for m in native for domain,v in m['domains'].items() for r in v['nonempty']}
    for record in records.values():
        need(type(record['body']) is str and pin(record['body'].encode()) == record['body_identity'] and
             ''.join(s['raw'] for s in record['segments']) == record['body'], 'whole reversible original raw body')
    headers = {h['id']:h for h in product['headers']}
    result = dict(scope=SCOPE,source_headers=[],public_headers=[],loads=[],complete_opaque_allocation=[],
                  original_unknowns=selected['original_unknowns'],full_original_raw_domain=pin(canonical(native)),
                  source_first_selection=pin(canonical(selected)))
    covered = {}
    for group in ('source_headers','public_headers','loads'):
        for allocation in selected[group]:
            key = tuple(allocation['record']);position=allocation['frame_position']
            frame = [s for s in records[key]['segments'] if s['kind']=='frame'][position]
            row = dict(allocation=allocation,original_frame=frame)
            if group == 'source_headers':
                source = headers[allocation['header_id']]
                row['source_header'] = source
                row['joined'] = header(frame['call'],source['expression']['function'],source['source_argument_ids'],product)
            elif group == 'public_headers':
                row['joined'] = header(frame['call'],allocation['function'],allocation['complete_argument_ids'],product,
                                       receivers[(*key,allocation['phase'])])
            else:
                need(frame['call']==allocation['diagnostic_marker'] and allocation['source_operator']=='do' and
                     allocation['diagnostic_marker_is_source_operator'] is False,'whole source do/diagnostic require boundary')
            result[group].append(row);covered.setdefault(key,set()).add(position)
    for key in sorted(covered):
        frames=[s for s in records[key]['segments'] if s['kind']=='frame']
        result['complete_opaque_allocation'].append(dict(record=list(key),covered_frame_positions=sorted(covered[key]),
            whole_opaque_frames=[dict(frame_position=i,frame=f) for i,f in enumerate(frames) if i not in covered[key]],
            meaning='All remaining complete private/framework intervals conserved; no semantic/native/private attribution.'))
    return result


def validate(actual, native, selected, product):
    need(pin(canonical(product)) == selected['source_expression'], 'whole committed complete source-header expression')
    need(same(reconstruct(native,selected,product),actual), 'whole independently reconstructed original header result')
    need(same(native,read(CLASS/'raw-product.json')['inventories']), 'every complete original raw/address/coordinate/source domain conserves')
    return dict(source_headers=pin(canonical(actual['source_headers'])),public_headers=pin(canonical(actual['public_headers'])),
                loads=pin(canonical(actual['loads'])),opaque=pin(canonical(actual['complete_opaque_allocation'])),scope=SCOPE)
