"""Independent source traversal and whole scalar/current-native reconstruction."""
import re
from common import SCOPE, canonical, need, pin, same


def source_members(source):
    # Traverse the complete source model directly, never the producer census.
    # Reversed stack insertion preserves its sorted structural traversal.
    pending = [(source['modes'], ['modes'])]
    result = []
    while pending:
        value, path = pending.pop()
        if type(value) is list:
            pending.extend((value[i], path + [i]) for i in reversed(range(len(value))))
        elif type(value) is dict:
            if 'role' in value and (value.get('kind') == 'scalar' or 'source_value' in value):
                if value['role'] != 'guard predicate':
                    context = 'source_value' in value
                    expected_keys = ({'expression', 'match', 'native_scalar_encoding', 'position', 'role', 'source_value'}
                        if context else {'kind', 'role', 'value'})
                    need(set(value) == expected_keys, 'independent closed scalar schema')
                    if context:
                        need(value['native_scalar_encoding'] == 'not measured', 'original scalar flags remain unmeasured')
                    raw = value['source_value' if context else 'value']
                    need(raw is None or type(raw) in (int, str), 'independent exact scalar type')
                    result.append(dict(path=path, schema='context_scalar' if context else 'scalar', operand=value,
                        value=pin(canonical(raw))['sha256'], evidence_role=('inherited serialized evidence'
                            if value['role'] == 'entire_context_and_inner_error' else 'qualified own-source value')))
            pending.extend((value[k], path + [k]) for k in sorted(value, reverse=True))
    return result


def token(value, limit):
    if value is None:
        return 'undef', True, None
    string = str(value)
    number = type(value) is int or re.fullmatch(r'[012]', string) is not None
    complete = number or limit < 3 or len(string) <= limit
    prefix = string if complete else string[:limit - 3]
    if number:
        return string, True, string
    out = ['"']
    for character in prefix:
        codepoint = ord(character)
        if not 32 <= codepoint <= 126:
            out.extend(('\\x{', hex(codepoint)[2:], '}'))
        else:
            if character in ('"', '\\', '$', '@'):
                out.append('\\')
            out.append(character)
    out.append('"')
    if not complete:
        out.append('...')
    return ''.join(out), complete, prefix


def verify_source(source, product, selected):
    need(set(product) == {'scope', 'values', 'members'} and set(selected) == {'scope', 'profile', 'cases'},
         'closed whole scalar products')
    need(product['scope'] == selected['scope'] == SCOPE, 'source versus inherited/native scope')
    members = source_members(source)
    need(same(members, product['members']), 'complete independent scalar member/order/role/value allocation')
    values = {}
    for member in members:
        operand = member['operand']
        value = operand['value' if member['schema'] == 'scalar' else 'source_value']
        constructor = 'undef' if value is None else 'numeric literal' if type(value) is int else 'complete codepoint string'
        values[member['value']] = dict(value=value, constructor=constructor)
    need(same(values, product['values']), 'entire independently typed scalar value dictionary')
    need(same(selected['profile'], dict(MaxArgNums=0, MaxEvalLen=0, RefArgFormatter=None)), 'explicit selected public profile')
    cases = []
    for identifier in sorted(values):
        item = values[identifier]
        for limit in (64, 0):
            spelling, complete, prefix = token(item['value'], limit)
            cases.append(dict(id=identifier + ':' + str(limit), value_id=identifier, **item, limit=limit,
                display=dict(token=spelling, complete=complete, prefix=prefix)))
    need(same(cases, selected['cases']), 'independent complete constructor and display hypotheses')
    return dict(members=pin(canonical(members)), values=pin(canonical(values)), cases=pin(canonical(cases)), scope=SCOPE)


def verify_native(plan, receipt, driver):
    need(set(receipt) == {'command', 'status', 'stdout', 'stderr', 'inputs'}, 'closed actual public capture receipt')
    need(type(receipt['status']) is int and receipt['status'] == 0 and receipt['stderr'] == '', 'actual typed public capture success')
    import json
    native = json.loads(receipt['stdout'])
    need(set(native) == {'rows', 'runtime'} and set(native['runtime']) == {'perl','carp','json_pp'}
         and all(type(v) is str and v for v in native['runtime'].values()), 'whole current public runtime metadata')
    need([r['id'] for r in native['rows']] == [r['id'] for r in plan['cases']], 'complete ordered public scalar corpus')
    lines = driver.decode().splitlines()
    emitter_line = next(i for i, line in enumerate(lines, 1) if 'my $trace = emitter();' in line)
    caller_line = next(i for i, line in enumerate(lines, 1) if 'boundary($value)' in line)
    for case, row in zip(plan['cases'], native['rows'], strict=True):
        need(set(row) == {'id', 'trace', 'value', 'profile'}, 'closed complete native scalar observation')
        need(same(row['profile'], dict(**plan['profile'], MaxArgLen=case['limit'])), 'actual explicit current profile')
        expected = dict(defined=case['value'] is not None, codepoints=[] if case['value'] is None else list(map(ord, str(case['value']))))
        need(same(row['value'], expected), 'complete native constructed scalar value')
        expected_trace = ('scalar source fixture at docs/audits/observer-scalar-values-20261010/native.pl line ' + str(emitter_line) + '.\n'
            '\tmain::boundary(' + case['display']['token'] + ') called at docs/audits/observer-scalar-values-20261010/native.pl line ' + str(caller_line) + '\n')
        need(row['trace'] == expected_trace, 'whole source-generated public scalar header and trace')
    return dict(native=pin(receipt['stdout'].encode()), scope=SCOPE)
