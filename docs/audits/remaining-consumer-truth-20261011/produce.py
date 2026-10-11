"""Propose remaining meanings from authored values and qualified whole API products."""
import copy
import argparse
from remaining_common import *
import value_inputs as inputs

# A finite source-operation allocation, separate from the reader's recipe walk.
APIS = {0: ('scope', 2, ()), 1: ('reference', 47, ()), 2: ('copy', 89, ()),
    6: ('copy', 376, ()), 7: ('copy', 524, ()), 8: ('copy', 672, ()),
    15: ('reference', 879, ()), 47: ('reference', 4659, ()), 48: ('reference', 4751, ()),
    49: ('reference', 4938, ('type_spec', 'signed')), 66: ('reference', 5920, ()),
    67: ('reference', 6172, ('role',)), 68: ('reference', 6172, ('width',)),
    71: ('reference', 6484, ('width',)), 74: ('reference', 6495, ()),
    75: ('reference', 6515, ('width',)), 78: ('reference', 6675, ()),
    79: ('reference', 6676, ()), 80: ('copy', 6906, ()), 81: ('copy', 6977, ()),
    82: ('copy', 6982, ()), 87: ('reference', 7140, ('width',)), 90: ('copy', 7575, ())}
APIS.update({37 + offset: ('payload', 2971 + offset, ()) for offset in range(4)})


def graph(value):
    if type(value) is dict:
        return ['hash', {key: graph(child) for key, child in value.items()}]
    if type(value) is list:
        return ['array', [graph(child) for child in value]]
    return value


def literal(expression):
    if expression == 'undef':
        return None
    if re.fullmatch(r'[0-9]+', expression):
        return int(expression)
    if expression.startswith("'") and expression.endswith("'"):
        return expression[1:-1]
    # These exact authored hash literals have no escapes or interpolation.
    converted = re.sub(r'\b([a-z_]+)\s*=>', r'"\1":', expression)
    converted = re.sub(r"'([^'\\]*)'", lambda match: json.dumps(match[1]), converted)
    converted = re.sub(r',\s*}', '}', converted)
    return graph(json.loads(converted))


def equal(left, right):
    if left is None or right is None:
        return left is None and right is None
    if type(left) is list or type(right) is list:
        if not (type(left) is list and type(right) is list and left[0] == right[0]):
            return False
        if left[0] == 'hash':
            return left[1].keys() == right[1].keys() and all(equal(left[1][key], right[1][key]) for key in left[1])
        return len(left[1]) == len(right[1]) and all(equal(a, b) for a, b in zip(left[1], right[1]))
    return str(left) == str(right)


def meaning(index, contract, mode, data):
    kind = contract['context']['kind']
    expressions = [row['body'] for row in contract['assertion']['arguments']]
    origin = {}
    if index in (0, 1, 2):
        declaration = data['source'].split('my $string_frame = $json->decode(', 1)[1].split(');', 1)[0]
        frame = json.loads(''.join(re.findall(r"'([^']*)'", declaration)))
        value = {'packet': {'role': 'input', 'type_spec': frame}}
        if index == 2:
            source = dict(root='packet', role='input', path_text='', width='8', type_spec=frame)
            target = copy.deepcopy(source)
            target.update(root='held', role='storage')
            value = [source, target]
        actual = json.dumps(value, sort_keys=True, separators=(',', ':'))
        expected = actual
        api = APIS[index][1]
        origin = dict(kind='readonly-authored-json', api=api, source_value=value,
                      whole_source_product=pin(canonical(data['products']['apis'][api])))
    elif index in (3, 4, 5):
        message = re.search(r'eval \{ confess "([^"\\]*)\\n" \}', data['source'])[1]
        pattern = '(?^:' + re.search(r'qr/([^/]+)/', expressions[1])[1] + ')' if kind != 'is' else literal(expressions[1])
        actual = data['native'][mode][3]['actual'] if index == 3 else message
        expected = pattern
        origin = dict(kind='synthetic-authored-first-line-and-opaque-original-trace', message=message,
                      whole_native_trace=pin(data['native'][mode][3]['actual'].encode()))
    elif index == 16:
        actual = data['products']['actors'][0]['expected_product']
        witness = next(row for row in data['copy_inputs'] if row['index'] == 80)
        need(same(actual, witness['native']['before']), 'whole actor copy qualified source input')
        expected = copy.deepcopy(witness['native']['copy'] if mode == 'storable' else actual)
        origin = dict(kind='whole-authored-actor-detached-copy', actor=0,
                      source_actor=data['actors']['actors']['local'], qualified_test_copy=dict(
                          index=80, witness=pin(canonical(witness)), provider='storable' if mode == 'storable' else 'ordinary'))
    elif contract['operand_role'] == 'authored_resolved_type_width':
        name = contract['context']['label'].split()[0] if '$name' in expressions[0] else re.search(r'\$types\{([^}]+)\}', expressions[0])[1]
        actual = data['authored']['types'][name]['width']
        expected = literal(expressions[1])
        origin = dict(kind='whole-authored-type-width', name=name, source_type=data['authored']['types'][name])
    else:
        family, api, selected = APIS[index]
        product = data['products']['apis'][api]
        need(product['kind'] == family, 'own proposed source API kind')
        actual = copy.deepcopy(product['expected_product'])
        for key in selected:
            need(type(actual) is list and actual[0] == 'hash', 'complete proposed selected source hash')
            actual = actual[1][key]
        origin = dict(kind='qualified-own-source-api', family=family, api=api,
                      selected=list(selected), whole_source_product=pin(canonical(product)),
                      unprojected=copy.deepcopy(product['expected_product']))
        if kind == 'ok':
            actual = int(actual is not None and actual != 0 and actual != '')
        expected = None if kind == 'ok' else literal(expressions[1])
    operand = {'actual': actual}
    if kind != 'ok':
        operand['expected'] = expected
    if kind == 'ok':
        outcome = actual
    elif kind in ('like', 'unlike'):
        outcome = int(bool(re.search(expected[4:-1], actual)) == (kind == 'like'))
    else:
        outcome = int(equal(actual, expected))
    return dict(source_assertion=contract, origin=origin, operand=operand, outcome=outcome,
                comparison=kind)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    need(args.output == 'candidate-v2.json.gz', 'retain first failed candidate and name corrected proposal explicitly')
    data = inputs.inputs()
    modes = []
    for mode in inputs.MODES:
        rows = []
        for index, (contract, native) in enumerate(zip(data['prepared']['assertions'], data['native'][mode], strict=True)):
            rows.append(dict(index=index, source_context=contract['context'], native=native,
                meaning=None if contract['helper'] is not None else meaning(index, contract, mode, data)))
        modes.append(dict(mode=mode, consumers=rows))
    save_product(args.output, dict(**inputs.header(data), modes=modes))
    print('Built every original observation with source-derived remaining typed operands; helper and complete join scopes retain.')
