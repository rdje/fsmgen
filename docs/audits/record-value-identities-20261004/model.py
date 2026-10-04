"""Complete source types and narrower public payload relation; no result oracle."""
from source_roots import graph, thaw, exact, digest, read, scope_model


def payload_accepts(source, target):
    if target['kind'] in ('bit', 'bits'):
        return source['kind'] in ('bit', 'bits') and source['width'] == target['width']
    if source['kind'] != target['kind']:
        return False
    if target['kind'] == 'list':
        return len(source['items']) == len(target['items']) and all(payload_accepts(a, b) for a, b in zip(source['items'], target['items']))
    if target['kind'] == 'record':
        return source['member_order'] == target['member_order'] and all(payload_accepts(source['members'][name], target['members'][name]) for name in target['member_order'])
    return False


def recipes(native):
    rows = []
    for parent in read('copies', 'copy-products.json')['rows']:
        calls = [row for row in parent['operation_span'] if row['record']['kind'] == 'identity']
        if not calls:
            continue
        assert len(calls) == 1 and parent['meaning']['reason'] in ('same-resolved-record', 'resolved-recursive-identity')
        values = thaw(parent['recipe']['arguments'])
        source = dict(zip(values[::2], values[1::2]))
        arguments, witnesses = ['FSM::Composition::InterfacePortBuilder'], []
        for name in ('source', 'target'):
            spec = source[name]['type_spec']
            stage = next(stage['copy'] for stage in parent['private_stages'] if stage['name'] == name)
            raw = thaw(stage['copy'])['type_spec']
            prepared = scope_model.prepared_type(spec, raw)
            # The complete reference width comparison reads only this root
            # width; the metadata validator reads its separate detached copy.
            prepared['width'] = spec['width']
            arguments.append(prepared)
            witnesses.append({'name': name, 'source_type': graph(spec),
                'whole_private_clone': digest(stage), 'prepared_type': graph(prepared)})
        call = calls[0]
        rows.append({'index': call['index'], 'kind': 'identity',
            'source_parent_index': parent['index'], 'whole_source_parent': digest(parent),
            'source_recipe': parent['recipe'], 'witnesses': witnesses,
            'expected_arguments': graph(arguments),
            'expected_result': int(source['source']['type_spec'] != source['target']['type_spec']),
            'caller': ['FSM::Support::ISFRecordPortValues', 'perl/FSM/Support/ISFRecordPortValues.pm', 110],
            'helper': parent['original']['helper'], 'parse': parent['original']['parse']})
    roots = read('copy-fields', 'source-models.json')['roots']
    selected = [i for i, row in enumerate(native['api']) if row['kind'] == 'payload']
    assert len(selected) == 4
    for index, name in zip(selected, ('signed_data', 'four', 'two', 'bit_kind')):
        source, target = roots['authored:frame'], roots['authored:' + name]
        rows.append({'index': index, 'kind': 'payload', 'source_parent_index': None,
            'whole_source_parent': None,
            'source_recipe': {'file': 't/1986-isf-record-port-value-gates.t',
                'loop_members': ['signed_data', 'four', 'two', 'bit_kind'], 'source': 'authored:frame', 'target': 'authored:' + name},
            'witnesses': [{'source_type': graph(source), 'target_type': graph(target)}],
            'expected_arguments': graph(['FSM::Package::PayloadTypeSupport', source, target]),
            'expected_result': int(payload_accepts(source, target)),
            'caller': ['main', './t/1986-isf-record-port-value-gates.t', 138],
            'helper': None, 'parse': None})
    return sorted(rows, key=lambda row: row['index'])
