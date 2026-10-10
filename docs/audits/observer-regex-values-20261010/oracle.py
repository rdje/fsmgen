"""Independent literal parsing, source traversal and whole public trace oracle."""
import json
from common import BASE, SCOPE, canonical, need, pin, same


def authored(authority):
    catalogue = authority['source_recipes']
    body = catalogue['source_units']['test']['body']
    result = []
    for helper in catalogue['callbacks']:
        statement, declaration = helper['source_statement'], helper['source_declaration']
        need(statement in body and (declaration is None or declaration in body), 'independent whole authored source custody')
        text = statement if declaration is None else declaration
        need(text.count('qr/') == 1, 'independent unique authored qr expression')
        start = text.index('qr/')
        stop = text.index('/', start+3)
        pattern = text[start+3:stop]
        end = stop+1
        while end < len(text) and text[end].isalpha():
            end += 1
        modifiers = text[stop+1:end]
        alphabet = set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_ .'*-")
        need(pattern and set(pattern) <= alphabet and not modifiers,
             'independent whole ASCII pattern/absent authored modifiers')
        need(helper['pattern'] == '(?^:'+pattern+')', 'independent source versus dated pattern meaning')
        result.append(dict(helper=helper['index'], statement=statement, declaration=declaration,
            expression=text[start:end], body=pattern, authored_modifiers=modifiers, source_encoding='ASCII characters',
            original_native_flags_encoding='not measured', label=helper['label'], subtest=helper['subtest'],
            api_members=helper['api_members'], parse_members=helper['parse_members']))
    return result


def members(model, recipes):
    result = []
    pending = [(model['modes'], ['modes'])]
    helpers = {r['helper']:r for r in recipes}
    while pending:
        value, path = pending.pop()
        if type(value) is list:
            pending.extend((value[i], path+[i]) for i in reversed(range(len(value))))
        elif type(value) is dict:
            if value.get('kind') == 'regex_source':
                need(set(value) == {'kind','role','source_pattern','display_body'} and value['role']=='source_refusal_pattern',
                     'independent closed source regex schema/role')
                mode, case = model['modes'][path[1]], model['modes'][path[1]]['cases'][path[3]]
                recipe = helpers[case['helper']]
                need(case['index'] in recipe['api_members' if case['domain']=='api' else 'parse_members']
                     and case['subtest']==recipe['subtest'], 'independent entire helper/source case allocation')
                need(value['source_pattern']=='(?^:'+recipe['body']+')' and value['display_body']==recipe['body'],
                     'independent complete source regex body')
                result.append(dict(path=path,helper=case['helper'],mode=mode['mode'],domain=case['domain'],
                    index=case['index'],phase=path[5],operand=value))
            pending.extend((value[k],path+[k]) for k in sorted(value,reverse=True))
    return result


def selected(recipes):
    result = []
    patterns = set(r['body'] for r in recipes)
    for body in sorted(patterns):
        for constructor in ['literal','byte-string','upgraded-string']:
            unicode = constructor == 'upgraded-string'
            flags = 'u' if unicode else ''
            for length in [16,64,0]:
                complete = length <= 2 or len(body) <= length
                visible = body if complete else ''.join(body[i] for i in range(length-3))
                spelling = ''.join(['qr(',visible,')','' if complete else '...',flags])
                result.append(dict(id=pin(canonical([body,constructor,length]))['sha256'],body=body,
                    expression='qr/'+body+'/',constructor=constructor,modifiers=flags,pattern_utf8=unicode,limit=length,
                    display=dict(token=spelling,prefix=visible,complete=complete)))
    return result


def source(authority,model,product,plan):
    need(set(product)=={'scope','authored','members'} and set(plan)=={'scope','profile','cases'}, 'closed complete regex products')
    need(product['scope']==plan['scope']==SCOPE,'original versus current regex scope')
    recipes = authored(authority)
    need(same(recipes,product['authored']),'whole independent authored regex expressions/flags/encoding')
    allocation = members(model,recipes)
    need(same(allocation,product['members']),'complete independent regex member/order/role/schema allocation')
    need(same(plan['profile'],dict(MaxArgNums=0,MaxEvalLen=0,RefArgFormatter=None)),'selected complete public profile')
    cases = selected(recipes)
    need(same(cases,plan['cases']),'whole independent regex constructor/value/flags/encoding/display hypotheses')
    return dict(authored=pin(canonical(recipes)),members=pin(canonical(allocation)),cases=pin(canonical(cases)),scope=SCOPE)


def native(plan,receipt,driver):
    need(set(receipt)=={'command','status','stdout','stderr','inputs'},'closed complete public regex receipt')
    need(type(receipt['status']) is int and receipt['status']==0 and receipt['stderr']=='','actual typed public regex success')
    observed=json.loads(receipt['stdout'])
    need(set(observed)=={'runtime','rows'} and set(observed['runtime'])=={'perl','carp','json_pp'}
         and all(type(v) is str and v for v in observed['runtime'].values()),'complete public runtime metadata')
    need([r['id'] for r in observed['rows']]==[r['id'] for r in plan['cases']],'complete ordered public regex corpus')
    lines=driver.decode().splitlines()
    called=next(i for i,line in enumerate(lines,1) if 'my $trace = emitter();' in line)
    caller=next(i for i,line in enumerate(lines,1) if 'my $row = displayed($regex);' in line)
    for case,row in zip(plan['cases'],observed['rows'],strict=True):
        need(set(row)=={'id','trace','value','profile','source_utf8'},'closed whole native regex observation')
        need(same(row['profile'],dict(**plan['profile'],MaxArgLen=case['limit'])),'actual complete selected regex profile')
        need(type(row['source_utf8']) is bool and row['source_utf8']==case['pattern_utf8'],'current selected constructor input encoding')
        expected=dict(kind='Regexp',codepoints=[ord(c) for c in case['body']],modifiers=case['modifiers'],
            pattern_utf8=case['pattern_utf8'],normalized='(?^'+case['modifiers']+':'+case['body']+')')
        need(same(row['value'],expected),'whole public compiled pattern/flags/encoding/normalized value')
        expected_trace=('regex source fixture at '+str(BASE/'native.pl')+' line '+str(called)+'.\n'
            '\tmain::displayed('+case['display']['token']+') called at '+str(BASE/'native.pl')+' line '+str(caller)+'\n')
        need(row['trace']==expected_trace,'whole source-generated regex public header and trace')
    # Actual paired construction intervention: unchanged characters, different
    # explicit input representation and resulting public modifiers/displays.
    for index in range(0,len(observed['rows']),9):
        literal,byte,wide=(observed['rows'][index+i] for i in (2,5,8))
        need(literal['value']==byte['value'] and byte['value']['codepoints']==wide['value']['codepoints']
             and byte['value']['modifiers']!=wide['value']['modifiers'], 'actual whole byte/upgraded construction separation')
    return dict(native=pin(receipt['stdout'].encode()),scope=SCOPE)
