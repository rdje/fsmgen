"""Independently derive every remaining source operand, then compute its truth."""
import argparse
import copy
from remaining_common import *
import comparison
from source_terms import Literal, graph, json_frame
import value_inputs as inputs

SUCCESS = 'PASS independent complete original remaining consumer operands/truth; helper/full join and higher scopes retain.\n'


def source_api(data, kind, select):
    matches = [row for row in data['models'][kind] if select(row)]
    need(len(matches) == 1, 'unique complete own remaining source API allocation')
    model = matches[0]
    index = model['index']
    product = data['products']['apis'][index]
    need(product['kind'] == kind and product['source_index'] == index
         and product['whole_source_model'] == pin(canonical(model).rstrip(b'\n')),
         'complete original qualified source model/product join')
    value = model['meaning']['product'] if kind == 'copy' else model.get('expected_product', model.get('expected_result'))
    need(same(value, product['expected_product']), 'whole independently selected qualified source product')
    return index, value, pin(canonical(product))


def copy_api(data, label):
    return source_api(data, 'copy', lambda model: model['recipe']['label'] == label)


def reference_api(data, contract, token, access, scope, occurrence=0):
    rows = sorted((row for row in data['models']['reference']
        if row['source_call']['token'] == token and row['source_call']['access'] == access
        and row['source_call']['helper'] is None and scope in row['source_scope_matches']), key=lambda row: row['index'])
    need(0 <= occurrence < len(rows), 'complete own remaining reference source occurrence')
    selected = rows[occurrence]['index']
    return source_api(data, 'reference', lambda row: row['index'] == selected)


def projected(value):
    # Every plain reference is true in Perl, including an empty container.
    if type(value) is list:
        return 1
    return int(value is not None and value not in (0, '', '0'))


def derive(contract, mode, data):
    kind = contract['context']['kind']
    expressions = [argument['body'] for argument in contract['assertion']['arguments']]
    expression, origin = expressions[0], {}
    role = contract['operand_role']
    if role == 'canonical_json_before_after_readonly_source_values':
        frame = json_frame(data['source'])
        value = dict(packet=dict(role='input', type_spec=frame))
        if '$source' in expression:
            declaration = data['source'].split('my $source = ', 1)[1].split(';', 1)[0]
            need("root => 'packet'" in declaration and "role => 'input'" in declaration
                 and "path_text => ''" in declaration and "width => '8'" in declaration
                 and "@{$target}{qw(root role)} = ('held', 'storage');" in data['source'],
                 'whole authored JSON source/clone/target-role dataflow')
            value = [dict(root='packet', role='input', path_text='', width='8', type_spec=frame)]
            value.append(copy.deepcopy(value[0])); value[1].update(root='held', role='storage')
            api, _, custody = copy_api(data, 'first-touch')
        elif '$scope' in expression:
            api, _, custody = source_api(data, 'reference', lambda row: row['source_call']['context'] == 'first touch')
        else:
            api, _, custody = source_api(data, 'scope', lambda row: row['recipe']['label'] == 'first-touch')
        actual = json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True)
        expected = actual
        origin = dict(kind='readonly-authored-json', api=api, source_value=value, whole_source_product=custody)
    elif role in ('whole_synthetic_carp_operand_with_opaque_native_coordinates', 'authored_synthetic_first_line'):
        body = data['source'].split('sub wrong_cause_with_pattern_in_stack {', 1)[1].split('\n}', 1)[0]
        need('eval { confess "Deliberately wrong diagnostic\\n" };' in body
             and "sub diagnostic_line { (split /\\n/, $_[0] // '')[0] // '' }" in data['source'],
             'complete own synthetic message and first-line source rules')
        message = body.split('confess "', 1)[1].split('\\n"', 1)[0]
        trace = data['native'][mode][3]['actual']
        need(trace.startswith(message + '\n') and 'main::wrong_cause_with_pattern_in_stack(qr(expected_cause_only_in_argument))' in trace,
             'whole original opaque synthetic trace own authored message/argument roles')
        actual = trace if expression == '$error' else message
        expected = Literal(expressions[1]).whole() if kind == 'is' else '(?^:' + expressions[1][3:-1] + ')'
        origin = dict(kind='synthetic-authored-first-line-and-opaque-original-trace', message=message,
                      whole_native_trace=pin(trace.encode()))
    elif role == 'authored_whole_actor_and_detached_source_copy':
        actor = data['actors']['actors']['local']
        need(data['actors']['sources']['local'] in data['source']
             and 'my $before = dclone($actor);' in contract['source_scope']['body']
             and '$scope->{packet}{type_spec}{members}{data}{width} = 99;' in contract['source_scope']['body'],
             'whole authored actor and detached scope mutation source flow')
        actual = graph(actor)
        witnesses = [row for row in data['copy_inputs'] if row['native']['caller'] ==
                     ['main', './t/1986-isf-record-port-value-gates.t', 122]]
        need(len(witnesses) == 1, 'unique original actor test-copy source witness')
        witness = witnesses[0]
        need(same(actual, witness['native']['before']) and witness['index'] == 80,
             'whole independently authored actor and qualified copy-input kinds')
        provider = 'storable' if mode == 'storable' else 'ordinary'
        proof = [row for row in data['copy_proofs'] if row['mode'] == mode and row['kind'] == 'returned'
                 and row['original_index'] == witness['index']]
        need(len(proof) == 1 and proof[0]['provider'] == provider, 'complete qualified original actor copy provider role')
        def detach(source, before, legacy):
            need(same(source, before), 'whole original source actor copy input')
            if type(source) is list:
                need(type(legacy) is list and len(legacy) == 2 and source[0] == legacy[0],
                     'whole qualified Storable actor-copy structural kind')
                if source[0] == 'hash':
                    need(source[1].keys() == legacy[1].keys(), 'whole qualified actor-copy hash membership')
                    return ['hash', {key: detach(source[1][key], before[1][key], legacy[1][key]) for key in source[1]}]
                need(len(source[1]) == len(legacy[1]), 'whole qualified actor-copy array membership')
                return ['array', [detach(a, b, c) for a, b, c in zip(source[1], before[1], legacy[1], strict=True)]]
            need(comparison.scalar(source) == comparison.scalar(legacy), 'qualified actor-copy scalar semantic conservation')
            return legacy
        expected = detach(actual, witness['native']['before'], witness['native']['copy']) if provider == 'storable' else graph(copy.deepcopy(actor))
        origin = dict(kind='whole-authored-actor-detached-copy', actor=0, source_actor=actor,
                      qualified_test_copy=dict(index=80, witness=pin(canonical(witness)), provider=provider))
    elif role == 'authored_resolved_type_width':
        if '$name' in expression:
            names = data['source'].split('for my $name (qw(', 1)[1].split('))', 1)[0].split()
            siblings = [row for row in data['prepared']['assertions']
                        if row['operand_role'] == role and row['assertion'] == contract['assertion']]
            offset = next(i for i, row in enumerate(siblings) if row['context'] == contract['context'])
            name = names[offset]
        else:
            name = expression[len('$types{'):expression.index('}')]
        spec = data['authored']['types'][name]
        actual, expected = spec['width'], Literal(expressions[1]).whole()
        origin = dict(kind='whole-authored-type-width', name=name, source_type=spec)
    else:
        selected = []
        if expression.startswith('copy('):
            operands = re.findall(r"'([^']*)'", expression)
            label = {('packet', 'held'): 'input-storage-alias', ('held', 'output'): 'storage-output-alias',
                     ('packet', 'output'): 'input-output-alias', ('old', 'held'): 'storage-prior-contract',
                     ('scalar', 'scalar'): 'scalar-prior-contract'}[tuple(operands)]
            if 'imported and local aliases' in contract['source_scope']['body']:
                label = 'imported-local'
            family = 'copy'; api, value, custody = copy_api(data, label)
        elif expression.startswith('validate_record_port_copy('):
            family = 'copy'; api, value, custody = copy_api(data, 'literal-prior-contract')
        elif expression.startswith('FSM::Package::PayloadTypeSupport'):
            siblings = [row for row in data['prepared']['assertions'] if row['operand_role'] == role]
            offset = next(i for i, row in enumerate(siblings) if row['context'] == contract['context'])
            names = data['source'].split('for my $name (qw(signed_data', 1)[1].split('))', 1)[0].split()
            name = (['signed_data'] + names)[offset]
            family = 'payload'
            api, value, custody = source_api(data, family, lambda row: row['kind'] == 'payload'
                and row['source_recipe']['target'] == 'authored:' + name)
        else:
            family = 'reference'
            if expression.startswith('$leaf'):
                token, access, scope = 'packet.body.count', 'write', 'formal-output'
                selected = [expression.split('{', 1)[1].split('}', 1)[0]]
                occurrence = 0
            else:
                call = expression.split(')->', 1)[0] + (')' if ')->' in expression else '')
                strings = re.findall(r"'([^']*)'", call)
                token, access = strings[0], strings[1] if len(strings) > 1 else 'read'
                selected = re.findall(r'\{([^}]+)\}', expression.split(')->', 1)[1]) if ')->' in expression else []
                scope = 'nested-paths' if 'core scalar paths retain exact' in contract['source_scope']['body'] else (
                    'local-unresolved' if '$unresolved,' in call else 'local-scalar' if '$scalar_shadow,' in call else
                    'formal-output' if '$formal,' in call else 'storage-only+old+lanes' if token == 'lanes[1]' else 'resolved-alias')
                # Source lexical occurrences, including the intervening assigned
                # leaf, distinguish otherwise identical fresh reference calls.
                before = data['source'][contract['source_scope']['start']:contract['assertion']['end']]
                occurrence = before.count(call) - 1
            api, value, custody = reference_api(data, contract, token, access, scope, occurrence)
        actual = copy.deepcopy(value)
        origin = dict(kind='qualified-own-source-api', family=family, api=api, selected=selected,
                      whole_source_product=custody, unprojected=copy.deepcopy(value))
        for key in selected:
            need(type(actual) is list and actual[0] == 'hash', 'whole source selected property container')
            actual = actual[1][key]
        if kind == 'ok':
            actual = projected(actual)
        expected = None if kind == 'ok' else graph(Literal(expressions[1]).whole())
    operand = dict(actual=actual)
    if kind != 'ok':
        operand['expected'] = expected
    assertion = dict(kind=kind, **operand)
    if kind == 'ok':
        outcome = actual
    elif kind == 'is':
        outcome = int(comparison.scalar(actual) == comparison.scalar(expected))
    elif kind == 'is_deeply':
        outcome = int(comparison.deep(actual, expected))
    else:
        outcome = int(comparison.regex(expected, actual) == (kind == 'like'))
    return dict(source_assertion=contract, origin=origin, operand=operand, outcome=outcome, comparison=kind)


def check(candidate):
    data = inputs.inputs()
    need(set(candidate) == set(inputs.header(data)) | {'modes'}
         and same({key: value for key, value in candidate.items() if key != 'modes'}, inputs.header(data)),
         'complete original remaining source/native/product/contract boundary custody')
    need([row['mode'] for row in candidate['modes']] == list(inputs.MODES), 'complete remaining original consumer mode domain')
    allocations = []
    for proposed, mode in zip(candidate['modes'], inputs.MODES, strict=True):
        need(set(proposed) == {'mode', 'consumers'} and len(proposed['consumers']) == 125,
             'complete original remaining consumer population including helper observations')
        qualified, retained = [], []
        for index, (row, contract, native) in enumerate(zip(proposed['consumers'], data['prepared']['assertions'], data['native'][mode], strict=True)):
            need(set(row) == {'index', 'source_context', 'native', 'meaning'}
                 and type(row['index']) is int and row['index'] == index and same(row['source_context'], contract['context']),
                 'whole own remaining consumer source context allocation')
            if contract['helper'] is not None:
                need(row['meaning'] is None and same(row['native'], native), 'whole helper observation retains without truth promotion')
                retained.append(index)
                continue
            # A forced flag reaches the independent comparison before source
            # admission or original-observation custody can reject its bytes.
            truth = comparison.observed(row['native'])
            expected = derive(contract, mode, data)
            need(same(row['meaning'], expected), 'whole independently derived own remaining source operands and outcome')
            operand = {key: row['native'][key] for key in ('actual', 'expected') if key in row['native']}
            need(same(operand, expected['operand']) and truth == expected['outcome'], 'whole source-derived remaining typed consumer operand and truth')
            need(same(row['native'], native), 'complete original remaining consumer native custody')
            qualified.append(dict(index=index, source=pin(canonical(contract)), meaning=pin(canonical(expected))))
        need(len(qualified) == 39 and len(retained) == 86, 'complete remaining/helper original source partition')
        allocations.append(dict(mode=mode, qualified=qualified, retained_helpers=retained))
    return dict(owner=PLAN['owner'], candidate=pin(canonical(candidate)), inputs=data['identities'],
                source_roles=data['source_roles'], allocations=allocations, boundary=PLAN['condition'],
                assumptions=inputs.header(data)['assumptions'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', default='candidate-v2.json.gz')
    parser.add_argument('--save', action='store_true')
    args = parser.parse_args()
    result = check(load_product(args.candidate))
    if args.save:
        need(args.candidate == 'candidate-v2.json.gz', 'save only complete corrected positive remaining qualification')
        save('qualification.json', result)
    print(SUCCESS, end='')
