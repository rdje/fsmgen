"""Select complete authored regex recipes before current native observation."""
import re
from common import AUTHORITY, BASE, CENSUS, SCALAR, SCOPE, canonical, module, need, pin, read, save


def source():
    return module(SCALAR/'derive.py')['source']()


def recipes(authority):
    catalogue = authority['source_recipes']
    test = catalogue['source_units']['test']['body']
    result = []
    for helper in catalogue['callbacks']:
        statement, declaration = helper['source_statement'], helper['source_declaration']
        need(statement in test and (declaration is None or declaration in test), 'whole authored source statement/declaration custody')
        location = declaration or statement
        expressions = list(re.finditer(r'qr/([^/\n]*)/([A-Za-z]*)', location))
        need(len(expressions) == 1, 'one complete finite authored regex expression')
        match = expressions[0]
        body, flags = match.groups()
        need(re.fullmatch(r"[A-Za-z0-9_ .'*-]+", body) is not None and flags == '',
             'finite authored ASCII pattern alphabet and absent modifiers')
        need(helper['pattern'] == '(?^:'+body+')', 'source literal versus inherited pattern evidence')
        result.append(dict(helper=helper['index'], statement=statement, declaration=declaration,
            expression=match.group(), body=body, authored_modifiers=flags, source_encoding='ASCII characters',
            original_native_flags_encoding='not measured', label=helper['label'], subtest=helper['subtest'],
            api_members=helper['api_members'], parse_members=helper['parse_members']))
    return result


def collect(authority, census, model):
    authored = recipes(authority)
    by_helper = {r['helper']:r for r in authored}
    need(len(by_helper) == len(authored), 'distinct whole authored helper allocation')
    members = []
    for row in census['operands']:
        if row['schema'] != 'regex_source':
            continue
        path = row['path']
        need(path[:1] == ['modes'] and path[2] == 'cases' and path[4] == 'phases', 'complete regex case/phase path')
        case = model['modes'][path[1]]['cases'][path[3]]
        recipe = by_helper[case['helper']]
        need(case['index'] in recipe['api_members' if case['domain']=='api' else 'parse_members']
             and case['subtest'] == recipe['subtest'], 'whole authored helper case/subtest allocation')
        operand = row['input']
        need(operand == dict(kind='regex_source', role='source_refusal_pattern', source_pattern='(?^:'+recipe['body']+')',
             display_body=recipe['body']), 'whole source regex operand body/role/schema')
        members.append(dict(path=path, helper=case['helper'], mode=model['modes'][path[1]]['mode'],
            domain=case['domain'], index=case['index'], phase=path[5], operand=operand))
    return dict(scope=SCOPE, authored=authored, members=members)


def token(body, flags, limit):
    complete = limit < 3 or len(body) <= limit
    prefix = body if complete else body[:limit-3]
    return dict(token='qr('+prefix+')'+('' if complete else '...')+flags, prefix=prefix, complete=complete)


def plan(product):
    bodies = sorted({r['body'] for r in product['authored']})
    cases = []
    for body in bodies:
        for constructor in ('literal', 'byte-string', 'upgraded-string'):
            flags = 'u' if constructor == 'upgraded-string' else ''
            for limit in (16, 64, 0):
                cases.append(dict(id=pin(canonical([body,constructor,limit]))['sha256'], body=body,
                    expression='qr/'+body+'/', constructor=constructor, modifiers=flags,
                    pattern_utf8=constructor=='upgraded-string', limit=limit, display=token(body,flags,limit)))
    return dict(scope=SCOPE, profile=dict(MaxArgNums=0, MaxEvalLen=0, RefArgFormatter=None), cases=cases)


def main():
    model = source()
    product = collect(read(AUTHORITY), read(CENSUS/'census.json'), model)
    save('regexes.json',product)
    save('plan.json',plan(product))
    need(not (BASE/'native.json').exists(), 'source hypotheses before native observation')
    save('pre-observation.json',dict(native_present=False, scope=SCOPE,
        inputs={str(p):pin(p.read_bytes()) for p in [AUTHORITY, CENSUS/'census.json', CENSUS/'source-models.json',
            *sorted(BASE.glob('*.py')), BASE/'native.pl', BASE/'regexes.json', BASE/'plan.json']}))
    print('PASS whole authored expressions, source allocations and finite public regex hypotheses before native observation.')


if __name__ == '__main__':
    main()
