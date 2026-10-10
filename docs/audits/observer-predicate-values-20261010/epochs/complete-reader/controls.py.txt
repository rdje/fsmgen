"""Execute full product counterexamples and a separating public native control."""
import base64
import copy
import gzip
import json
import subprocess
from common import BASE, canonical, load, need, pin, save
from oracle import verify
from native_verify import verify as public_verify


def pack(value):
    return base64.b64encode(gzip.compress(canonical(value),mtime=0)).decode()


def replay():
    report=load('controls.json'); seen=set()
    for row in report['rows']:
        need(row['name'] not in seen and row['status'] == 'rejected','unique genuine complete control')
        seen.add(row['name']); raw=gzip.decompress(base64.b64decode(row['candidate'],validate=True)); candidate=json.loads(raw)
        need(canonical(candidate) == raw,'lossless whole control product')
        try:
            if row['kind'] == 'whole_source_value': verify(candidate['source'],candidate['values'])
            elif row['kind'] == 'whole_public_native': public_verify(load('fixture-plan-qualified.json'),candidate)
            else: raise RuntimeError('unknown control kind')
        except (ValueError,KeyError,IndexError,TypeError) as exc:
            need(str(exc) == row['error'],'same complete intended control refusal')
        else: raise ValueError('accepted retained whole counterexample')
    need(seen == {'omitted-operand','reordered-operand','borrowed-location','schema-promotion','false-value-encoding',
        'native-flag-promotion','original-setting-promotion','helper-normalization','wrong-short-circuit-branch',
        'wrong-qualified-input','resolver-override','first-wrong-precedence-product','native-omission',
        'native-header-token','native-value-coercion','native-profile-promotion','ignored-native-tail'},'complete genuine control membership')
    plan=load('native-control-plan.json'); actual=load('native-control.json'); driver=BASE/'native-control.pl'
    need(plan == report['native_control'] and plan['driver'] == pin(driver.read_bytes())
        and actual['command'] == ['perl',str(driver)] and actual['status'] == 0 and not actual['stderr']
        and actual['plan'] == pin((BASE/'native-control-plan.json').read_bytes()),'whole real source control custody')
    base=(BASE/'native-qualified.pl').read_bytes(); before=plan['source_change']['before'].encode(); after=plan['source_change']['after'].encode()
    need(base.count(before) == 1 and base.replace(before,after) == driver.read_bytes(),'one exact complete native source change')
    product=json.loads(actual['stdout']); original=public_verify(load('fixture-plan-qualified.json'),load('native-qualified.json'))
    need(product['profile'] == original['profile'] and product['runtime'] == original['runtime'] and len(product['rows']) == len(original['rows']),'whole current native control profile and membership')
    for i,(row,previous) in enumerate(zip(product['rows'],original['rows'])):
        expected=copy.deepcopy(previous); expected['trace']=previous['trace'].replace(str(BASE/'native-qualified.pl'),str(driver))
        if i == 2:
            expected['string']='0'; expected['trace']=expected['trace'].replace('main::boundary("numeric_comparison", "")','main::boundary("numeric_comparison", 0)')
        need(row == expected,'whole real native intervention result, including every other constructor')
    return dict(controls=pin((BASE/'controls.json').read_bytes()),native=pin((BASE/'native-control.json').read_bytes()))


def run():
    source=load('source-inputs.json'); values=load('predicate-values-qualified.json')
    plan=load('fixture-plan-qualified.json'); native=load('native-qualified.json')
    verify(source,values); public_verify(plan,native)
    results=[]
    def source_case(name,edit):
        s,v=copy.deepcopy(source),copy.deepcopy(values); edit(s,v)
        need(not (canonical(s) == canonical(source) and canonical(v) == canonical(values)),'genuine source control')
        try: verify(s,v)
        except (ValueError,KeyError,IndexError,TypeError) as exc: error=str(exc)
        else: raise ValueError('accepted hostile complete source candidate: '+name)
        results.append(dict(name=name,kind='whole_source_value',candidate=pack(dict(source=s,values=v)),status='rejected',error=error))
    source_case('omitted-operand',lambda s,v:v['rows'].pop())
    source_case('reordered-operand',lambda s,v:v['rows'].reverse())
    source_case('borrowed-location',lambda s,v:v['rows'][0].update(path=v['rows'][1]['path']))
    source_case('schema-promotion',lambda s,v:v['rows'][0]['input'].update(kind='scalar'))
    source_case('false-value-encoding',lambda s,v:v['rows'][0].update(string_value='0'))
    source_case('native-flag-promotion',lambda s,v:v['rows'][0].update(original_native_scalar_flags='qualified'))
    source_case('original-setting-promotion',lambda s,v:v.update(original_observer_settings=v['current_profile']))
    source_case('helper-normalization',lambda s,v:v['helpers'].update({next(iter(v['helpers'])):'sub _whole_record { return !1; }'}))
    def branch(s,v):
        c=next(c for c in s['cases'] if c['event']['site'] == 'metadata_type.9')
        c['event']['facts']['identifier']=False
        for r in v['rows']:
            if r['source_case']['key'] == c['key']: r['source_case']=copy.deepcopy(c)
    source_case('wrong-short-circuit-branch',branch)
    def supplied(s,v):
        c=s['cases'][0]; c['input_graph'][1][1][1]['width']=99
    source_case('wrong-qualified-input',supplied)
    source_case('resolver-override',lambda s,v:v['resolver']['calls'][0]['keys'].append('ok'))
    source_case('first-wrong-precedence-product',lambda s,v:(v.clear(),v.update(load('predicate-values.json'))))
    def native_case(name,edit):
        n=copy.deepcopy(native); product=json.loads(n['stdout']); edit(product)
        n['stdout']=canonical(product).decode()
        need(n != native,'genuine whole native candidate')
        try: public_verify(plan,n)
        except (ValueError,KeyError,IndexError,TypeError) as exc: error=str(exc)
        else: raise ValueError('accepted hostile complete native candidate: '+name)
        results.append(dict(name=name,kind='whole_public_native',candidate=pack(n),status='rejected',error=error))
    native_case('native-omission',lambda p:p['rows'].pop())
    native_case('native-header-token',lambda p:p['rows'][2].update(trace=p['rows'][2]['trace'].replace(', "")',', 0)')))
    native_case('native-value-coercion',lambda p:p['rows'][2].update(string='0'))
    native_case('native-profile-promotion',lambda p:p['profile'].update(MaxArgLen=0))
    native_case('ignored-native-tail',lambda p:p['rows'][0].update(trace=p['rows'][0]['trace']+'unqualified extra frame\n'))
    # A real source intervention, selected before executing its public capture.
    driver=(BASE/'native-qualified.pl').read_bytes()
    old=b'boundary("numeric_comparison", scalar(1 == 2))'
    new=b'boundary("numeric_comparison", scalar(normalized(1 == 2)))'
    need(driver.count(old) == 1,'one complete native constructor intervention')
    changed=driver.replace(old,new); path=BASE/'native-control.pl'
    need(not path.exists(),'one fresh genuine native constructor control')
    path.write_bytes(changed)
    selected=dict(driver=pin(changed),source_change=dict(before=old.decode(),after=new.decode()),
        expected=dict(string='0',number=0,defined=True,token='0'),original_runtime='not measured')
    save('native-control-plan.json',selected)
    actual=subprocess.run(['perl',str(path)],capture_output=True,text=True)
    save('native-control.json',dict(command=['perl',str(path)],status=actual.returncode,stdout=actual.stdout,stderr=actual.stderr,plan=pin((BASE/'native-control-plan.json').read_bytes())))
    need(actual.returncode == 0 and not actual.stderr,'actual complete native control')
    changed_product=json.loads(actual.stdout); current=json.loads(native['stdout'])
    a=changed_product['rows'][2]; b=current['rows'][2]
    need(a['name'] == b['name'] == 'numeric_comparison' and a['string'] == '0' and b['string'] == ''
        and a['number'] == b['number'] == 0 and a['defined'] is b['defined'] is True
        and 'main::boundary("numeric_comparison", 0) called at '+str(path)+' line ' in a['trace']
        and 'main::boundary("numeric_comparison", "") called at ' in b['trace'],'real source normalization separates whole value and public token')
    save('controls.json',dict(rows=results,native_control=selected,scope='All complete counterexamples and actual native source intervention; no original capture or flag promotion.'))
    print('PASS genuine whole source/branch/value/schema/member/encoding/native-scope controls and real public constructor intervention.')


if __name__ == '__main__': run()
