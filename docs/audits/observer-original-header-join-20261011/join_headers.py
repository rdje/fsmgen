"""Join whole encoded original calls to full source literals and opaque intervals."""
import re
from common import CLASS, HEADERS, SCOPE, canonical, load, need, pin, read, save


def tokens(binding, product):
    alternatives = []
    for identifier in binding['current_construction_cases']:
        row = product['current_construction_cases'][identifier]
        if row['kind'] != 'predicate' and row['case']['limit'] != 64:
            continue
        spelling = row['case']['display_token'] if row['kind'] == 'predicate' else row['case']['display']['token']
        if spelling not in alternatives:
            alternatives.append(spelling)
    return alternatives


def call(call_text, function, argument_ids, product, receiver=None):
    if function == 'eval {...}':
        need(not argument_ids and call_text == function, 'whole source-qualified eval marker')
        return dict(function=function, arguments=[], hidden_argument_ids=[], complete_call=call_text,
                    original_meaning='source eval boundary only; private implementation unmeasured')
    opening = function + '('
    need(call_text.startswith(opening) and call_text.endswith(')'), 'whole source-qualified call framing')
    cursor = len(opening)
    rows = []
    if receiver is not None:
        need(call_text[cursor:].startswith(receiver + ', '), 'whole opaque public receiver conservation')
        rows.append(dict(source_role='whole opaque public receiver', token=receiver,
                         interval_bytes=[len(call_text[:cursor].encode()), len(call_text[:cursor+len(receiver)].encode())],
                         original_meaning='contents/class/identity/private implementation unmeasured'))
        cursor += len(receiver) + 2
    visible = argument_ids[:8]
    for index, identifier in enumerate(visible):
        binding = product['operands'][identifier]
        source = binding['source']
        qualified = source['qualification']
        start = cursor
        if qualified['kind'] == 'source reference role and kind only':
            kind = qualified['reference_kind']
            display_class = source['input'].get('display_class')
            if display_class is not None:
                kind = display_class + '=' + kind
            match = re.match(re.escape(kind) + r'\(0x[0-9a-f]+\)', call_text[cursor:])
            need(match is not None, 'whole source-qualified reference kind/token syntax')
            token = match.group()
            alternatives = None
            meaning = 'Complete original encoded interval and source kind/role only; address/referent/receiver/native identity unmeasured.'
        else:
            alternatives = tokens(binding, product)
            matches = [value for value in alternatives if call_text.startswith(value, cursor)
                       and call_text[cursor+len(value):].startswith((', ', ')'))]
            need(len(matches) == 1, 'whole source-qualified literal argument header')
            token = matches[0]
            meaning = ('Complete known source value under an explicit qualifying current grammar; original flags/settings/encoding/provider remain unmeasured.'
                       if qualified['kind'] != 'qualified whole authored regex' else
                       'Complete authored regex value and full qualified constructor alternatives; matched original encoded spelling does not measure original flags/encoding/provider.')
        cursor += len(token)
        rows.append(dict(argument_id=identifier, source=source, token=token,
                         interval_bytes=[len(call_text[:start].encode()),len(call_text[:cursor].encode())],
                         qualified_current_alternatives=alternatives, original_meaning=meaning))
        if index+1 < len(visible):
            need(call_text[cursor:cursor+2] == ', ', 'whole source-qualified argument separator')
            cursor += 2
    if len(argument_ids) > 8:
        need(call_text[cursor:cursor+5] == ', ...', 'whole source-qualified argument-count marker')
        cursor += 5
    need(call_text[cursor:] == ')', 'whole source-qualified complete argument population')
    assembled = opening + ', '.join(([receiver] if receiver is not None else []) + [r['token'] for r in rows if 'argument_id' in r]
                    + (['...'] if len(argument_ids)>8 else [])) + ')'
    need(assembled == call_text, 'whole source-generated complete original call equality')
    return dict(function=function, arguments=rows, hidden_argument_ids=argument_ids[8:], complete_call=assembled,
                qualifying_profile=product['current_profile'],
                original_meaning='Finite encoded compatibility and complete opaque conservation only; original settings and native/private attribution unmeasured.')


def join(native, selection, product):
    records = {(m['mode'], domain, r['index']):r for m in native
               for domain, values in m['domains'].items() for r in values['nonempty']}
    header_table = {r['id']:r for r in product['headers']}
    previous = read(CLASS/'proofs.json')['full_prior_public_join']
    receivers = {(m['mode'],c['domain'],c['index'],p['phase']):p['public_header_compatibility']['receiver_opaque']
                 for m in previous['modes'] for c in m['cases'] for p in c['phases']}
    result = []
    covered = {}
    for allocation in selection['source_headers']:
        key = tuple(allocation['record'])
        record = records[key]
        frame = [r for r in record['segments'] if r['kind']=='frame'][allocation['frame_position']]
        header = header_table[allocation['header_id']]
        need(header['path'] == allocation['source_path'], 'whole source/header role allocation')
        joined = call(frame['call'], header['expression']['function'], header['source_argument_ids'], product)
        result.append(dict(allocation=allocation, source_header=header, original_frame=frame, joined=joined))
        covered.setdefault(key, set()).add(allocation['frame_position'])
    public = []
    for allocation in selection['public_headers']:
        key = tuple(allocation['record'])
        record = records[key]
        frame = [r for r in record['segments'] if r['kind']=='frame'][allocation['frame_position']]
        receiver = receivers[(*key, allocation['phase'])]
        joined = call(frame['call'], allocation['function'], allocation['complete_argument_ids'], product, receiver)
        public.append(dict(allocation=allocation, original_frame=frame, joined=joined))
        covered.setdefault(key, set()).add(allocation['frame_position'])
    loads = []
    for allocation in selection['loads']:
        key = tuple(allocation['record'])
        frame = [r for r in records[key]['segments'] if r['kind']=='frame'][allocation['frame_position']]
        need(frame['call'] == allocation['diagnostic_marker'] and allocation['source_operator']=='do'
             and allocation['diagnostic_marker_is_source_operator'] is False, 'whole source do/diagnostic require boundary')
        loads.append(dict(allocation=allocation, original_frame=frame))
        covered.setdefault(key, set()).add(allocation['frame_position'])
    remaining = []
    for key in sorted(covered):
        record = records[key]
        frames = [r for r in record['segments'] if r['kind']=='frame']
        remaining.append(dict(record=list(key), covered_frame_positions=sorted(covered[key]),
            whole_opaque_frames=[dict(frame_position=i, frame=frame) for i,frame in enumerate(frames) if i not in covered[key]],
            meaning='All remaining complete private/framework intervals conserved; no semantic/native/private attribution.'))
    return dict(scope=SCOPE, source_headers=result, public_headers=public, loads=loads,
                complete_opaque_allocation=remaining, original_unknowns=selection['original_unknowns'],
                full_original_raw_domain=pin(canonical(native)),
                source_first_selection=pin(canonical(selection)))


if __name__ == '__main__':
    native = read(CLASS/'raw-product.json')['inventories']
    selected = load('selected.json')
    product = read(HEADERS/'headers.json')
    joined = join(native, selected, product)
    save('original-raw-intake.json',dict(scope=SCOPE, original=pin((CLASS/'raw-product.json').read_bytes()),
        committed_source_selection=pin((HEADERS/'selection.json').read_bytes()),
        own_source_selection=pin((__import__('common').BASE/'selected.json').read_bytes()),
        meaning='First own encoded comparison uses complete prior canonical raw inventory; no original recapture.'))
    save('joined.json',joined)
    print('PASS complete original encoded source/public headers, full literals/count/grammar and whole opaque intervals; original native/private/settings identity remains unmeasured.')
